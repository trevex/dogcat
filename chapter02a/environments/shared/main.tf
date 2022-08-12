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
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com",
  ])
  project = var.project
  service = each.value
}


# Let's create our artifact registry for our container-images

resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "images"
  description   = "Primary container-image registry"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}


# And we give all our compute in cluster projects reader access to container-images

data "google_project" "cluster_project" {
  for_each   = var.cluster_projects
  project_id = each.value
}

resource "google_artifact_registry_repository_iam_member" "compute_ar_reader" {
  for_each = var.cluster_projects

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
    [for p in var.cluster_projects : { project = p, env = "dev" } if length(regexall(".*-dev$", p)) > 0],
    [for p in var.cluster_projects : { project = p, env = "stage" } if length(regexall(".*-stage$", p)) > 0],
    [for p in var.cluster_projects : { project = p, env = "prod" } if length(regexall(".*-prod$", p)) > 0],
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

resource "google_project_iam_member" "build_act_as" {
  for_each = local.environments
  project  = var.project
  role     = "roles/iam.serviceAccountUser"
  member   = "serviceAccount:${google_service_account.build[each.value].email}"
}

resource "google_project_iam_member" "build_logs_writer" {
  for_each = local.environments
  project  = var.project
  role     = "roles/logging.logWriter"
  member   = "serviceAccount:${google_service_account.build[each.value].email}"
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
    _PLAN_ENV   = join(",", concat(lookup(each.value, "plan_environment", []), [each.key]))
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
    google_project_iam_member.build_act_as,
    google_project_iam_member.build_logs_writer,
    google_project_iam_member.build_access_project,
  ]
}
