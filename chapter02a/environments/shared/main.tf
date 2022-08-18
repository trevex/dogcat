terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-chapter-02-tf-state"
    prefix = "terraform/shared"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}


# Enable required APIs

resource "google_project_service" "services" {
  for_each = toset([
    "anthos.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com",
    "clouddeploy.googleapis.com",
    "gkehub.googleapis.com",
  ])
  project = var.project
  service = each.value
}


# Let's create our artifact registry for our container-images

resource "google_artifact_registry_repository" "images" {
  #checkov:skip=CKV_GCP_84:We do not want to use CSEK
  location      = var.region
  repository_id = "images"
  description   = "Primary container-image registry"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}


# And we give all our compute in cluster projects reader access to container-images

locals {
  cluster_projects = toset([for c in var.clusters : split("/", c)[1]])
}

data "google_project" "cluster_project" {
  for_each   = local.cluster_projects
  project_id = each.value
}

resource "google_artifact_registry_repository_iam_member" "compute_ar_reader" {
  for_each = local.cluster_projects

  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_project.cluster_project[each.key].number}-compute@developer.gserviceaccount.com"
}


# We either create the required repository used for our terraform code or use the specifed one.

resource "google_sourcerepo_repository" "repo" {
  count = var.create_source_repository ? 1 : 0
  name  = var.source_repository_name

  depends_on = [google_project_service.services]
}

data "google_sourcerepo_repository" "repo" {
  count = var.create_source_repository ? 0 : 1
  name  = var.source_repository_name

  depends_on = [google_project_service.services]
}

locals {
  source_repository = var.create_source_repository ? google_sourcerepo_repository.repo[0] : data.google_sourcerepo_repository.repo[0]
}


# We set up the build triggers required to roll out the terraform code
# There will be separate triggers for each environment and each trigger is
# using a different ServiceAccount with permissions to view the other projects,
# but only mutate projects belonging to its own environment.

locals {
  projects_with_environments = concat(
    # We go over all projects and associate them to an environment based on their suffix
    [for p in local.cluster_projects : { project = p, env = "dev" } if length(regexall(".*-dev$", p)) > 0],
    [for p in local.cluster_projects : { project = p, env = "stage" } if length(regexall(".*-stage$", p)) > 0],
    [for p in local.cluster_projects : { project = p, env = "prod" } if length(regexall(".*-prod$", p)) > 0],
    [{ project = var.project, env = "shared" }] # we add the shared environment manually
  )
  environments = toset(["dev", "stage", "prod", "shared"])
  permission_mappings = {
    # for each possible combination of environments and projects associated with environments
    for pair in setproduct(local.environments, local.projects_with_environments) :
    "env-${pair[0]}-project-${pair[1].project}" => {
      from_env   = pair[0]
      to_env     = pair[1].env
      to_project = pair[1].project
    }
  }
}

resource "google_service_account" "build" {
  for_each     = local.environments
  account_id   = "build-tf-${each.value}"
  display_name = "Service Account used by Cloud Build to rollout ${each.value}-environment."
}

resource "google_project_iam_member" "build_logs_writer" {
  for_each = local.environments
  project  = var.project
  role     = "roles/logging.logWriter"
  member   = "serviceAccount:${google_service_account.build[each.value].email}"
}

resource "google_storage_bucket_iam_member" "build_state_access" {
  for_each = local.environments
  bucket   = var.state_bucket_name
  role     = "roles/storage.admin"
  member   = "serviceAccount:${google_service_account.build[each.value].email}"
}

resource "google_artifact_registry_repository_iam_member" "build_ar_writer" {
  for_each   = local.environments
  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.writer"
  member     = "serviceAccount:${google_service_account.build[each.value].email}"
}

resource "google_project_iam_member" "build_access_project" {
  for_each = local.permission_mappings
  project  = each.value.to_project
  role     = each.value.to_env == each.value.from_env ? "roles/editor" : "roles/viewer"
  member   = "serviceAccount:${google_service_account.build[each.value.from_env].email}"
}

resource "google_cloudbuild_trigger" "build" {
  for_each = {
    "dev" = {
      branch_name       = "develop"
      approval_required = false
      plan_environments = ["stage"]
    }
    "stage" = {
      branch_name       = "main"
      approval_required = false
      plan_environments = ["prod", "shared"]
    }
    "prod" = {
      branch_name       = "main"
      approval_required = true
    }
    "shared" = {
      branch_name       = "main"
      approval_required = true
    }
  }

  name            = "build-tf-${each.key}"
  service_account = google_service_account.build[each.key].id
  filename        = "chapter02a/cloudbuild.yaml"
  substitutions = {
    _TARGET_ENV = each.key
    _PLAN_ENV   = join(",", lookup(each.value, "plan_environments", []))
  }

  trigger_template {
    branch_name = each.value.branch_name
    repo_name   = local.source_repository.name
  }

  approval_config {
    approval_required = each.value.approval_required
  }

  depends_on = [
    google_project_service.services,
    google_artifact_registry_repository_iam_member.build_ar_writer,
    google_project_iam_member.build_logs_writer,
    google_project_iam_member.build_access_project,
  ]
}


# For developer teams we pre-create targets corresponding to our GKE clusters
# and assign ServiceAccounts with access to them.
locals {
  # Format: "projects/my-project-name/locations/us-west1/clusters/example-cluster-name"
  cluster_splits = [for c in var.clusters : split("/", c)]
  targets = { for s in local.cluster_splits : s[5] => {
    cluster_id = join("/", s)
    project    = s[1]
    location   = s[3]
    name       = s[5]
    # Environment is extracted from cluster name
    env = regexall(".*(dev|stage|prod).*", s[5])[0][0]
  } }

}

resource "google_storage_bucket" "artifacts" {
  #checkov:skip=CKV_GCP_62:We do not want to log access
  #checkov:skip=CKV_GCP_78:We do not need versioning either
  name                        = "${var.project}-deploy-artifacts"
  location                    = "EU"
  uniform_bucket_level_access = true
}

resource "google_service_account" "target_deployers" {
  for_each     = local.targets
  account_id   = "target-${each.key}"
  display_name = "Use to deploy release to target ${each.key}"
}

resource "google_storage_bucket_iam_member" "target_deployers_artifacts_access" {
  for_each = local.targets
  bucket   = google_storage_bucket.artifacts.id
  role     = "roles/storage.admin"
  member   = "serviceAccount:${google_service_account.target_deployers[each.key].email}"
}

resource "google_project_iam_member" "target_deployers_gke_access" {
  for_each = local.targets
  project  = each.value.project
  role     = "roles/container.developer"
  member   = "serviceAccount:${google_service_account.target_deployers[each.key].email}"
}

resource "google_clouddeploy_target" "targets" {
  for_each = local.targets

  location         = each.value.location
  name             = each.value.name
  require_approval = each.value.env == "prod" ? true : false
  description      = "Cluster ${each.value.name} in project ${each.value.project}"
  labels = {
    env = each.value.env
  }

  gke {
    cluster = each.value.cluster_id
  }

  execution_configs {
    artifact_storage = "${google_storage_bucket.artifacts.url}/${each.value.env}/"
    service_account  = google_service_account.target_deployers[each.key].email
    usages           = ["RENDER", "DEPLOY"]
  }

  depends_on = [google_project_service.services]
}


# Let's register all clusters to our fleet

data "google_project" "fleet_project" {
  project_id = var.project
}

resource "google_project_iam_member" "membership_access" {
  for_each = toset([for t in local.targets : t.project])
  project  = each.value
  role     = "roles/gkehub.serviceAgent"
  member   = "serviceAccount:service-${data.google_project.fleet_project.number}@gcp-sa-gkehub.iam.gserviceaccount.com"

  depends_on = [google_project_service.services]
}

# NOTE: This will as of today not install the connect-agent!
#       You will have to re-register the cluster through the CLI instead.
#       For the purpose of this demo, we are not interested in the features
#       of the connect-agent.
resource "google_gke_hub_membership" "membership" {
  for_each = local.targets

  membership_id = each.key
  endpoint {
    gke_cluster {
      resource_link = "//container.googleapis.com/${each.value.cluster_id}"
    }
  }
  authority {
    issuer = "https://container.googleapis.com/v1/${each.value.cluster_id}"
  }

  depends_on = [
    google_project_iam_member.membership_access,
    google_project_service.services,
  ]
}

# TODO: enable features, e.g. policy controller
#       https://registry.terraform.io/providers/hashicorp/google/latest/docs/resources/gke_hub_feature_membership

