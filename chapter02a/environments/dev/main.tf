terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-chapter02-tf-state"
    prefix = "terraform/dev"
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
    "cloudresourcemanager.googleapis.com", # required by terraform
    "compute.googleapis.com",
    "container.googleapis.com",
    "sqladmin.googleapis.com",
    "dns.googleapis.com",
  ])
  project = var.project
  service = each.value
}

# The underlying network mainly for the cluster

module "network" {
  source = "../../modules//network"

  name = "network-dev"
  subnetworks = [{
    name_affix    = "main" # full name will be `${name}-${name_affix}-${region}`
    ip_cidr_range = "10.0.0.0/20"
    region        = var.region
    secondary_ip_range = [{ # Use larger ranges in production!
      range_name    = "pods"
      ip_cidr_range = "10.0.32.0/19"
      }, {
      range_name    = "services"
      ip_cidr_range = "10.0.16.0/20"
    }]
  }]

  depends_on = [google_project_service.services]
}

# DNS zone for this project

module "dns_zone" {
  source = "../../modules//dns-zone"

  parent_project   = var.dns_project
  parent_zone_name = var.dns_zone_name

  name = "nvoss-demo-dogcat-dev"
  fqdn = var.dns_dedicated_fqdn

  depends_on = [google_project_service.services]
}


# Create GKE Autopilot cluster

module "cluster" {
  source = "../../modules//cluster"

  name                   = "cluster-dev"
  project                = var.project
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["network-dev-main-${var.region}"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  depends_on = [module.network]
}

# We allow our cluster to access our shared artifact respository for images

locals {
  artifact_repository_splits = split("/", var.artifact_repository_id)
  # Format: "projects/nvoss-dogcat-chapter-02-shared/locations/europe-west1/repositories/images"
  artifact_repository = {
    project  = local.artifact_repository_splits[1]
    location = local.artifact_repository_splits[3]
    name     = local.artifact_repository_splits[5]
  }
}

resource "google_artifact_registry_repository_iam_member" "ar_reader" {
  project    = local.artifact_repository.project
  location   = local.artifact_repository.location
  repository = local.artifact_repository.name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${module.cluster.cluster_sa_email}"
}

data "google_client_config" "cluster" {}

provider "kubernetes" {
  host                   = module.cluster.host
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  ignore_annotations = [
    "cloud\\.google\\.com\\/neg-status"
  ]
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    token                  = data.google_client_config.cluster.access_token
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
  }
}

# And we register this cluster declaratively with ArgoCD

locals {
  shared_cluster_splits = split("/", var.shared_cluster_id)
  # Format: "projects/nvoss-dogcat-chapter-02-shared/locations/europe-west1/clusters/cluster-shared"
  shared_cluster = {
    project  = local.shared_cluster_splits[1]
    location = local.shared_cluster_splits[3]
    name     = local.shared_cluster_splits[5]
  }
  argo_cd_server_email                 = "argo-cd-server@${local.shared_cluster.project}.iam.gserviceaccount.com"
  argo_cd_application_controller_email = "argo-cd-application-controller@${local.shared_cluster.project}.iam.gserviceaccount.com"
}

data "google_container_cluster" "shared" {
  project  = local.shared_cluster.project
  location = local.shared_cluster.location
  name     = local.shared_cluster.name
}

provider "kubernetes" {
  alias = "shared"

  host                   = "https://${data.google_container_cluster.shared.endpoint}"
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.shared.master_auth[0].cluster_ca_certificate)
}

resource "google_project_iam_member" "argo_cd_server" {
  project = var.project
  role    = "roles/container.viewer"
  member  = "serviceAccount:${local.argo_cd_server_email}"
}

resource "google_project_iam_member" "argo_cd_application_controller" {
  project = var.project
  role    = "roles/container.developer"
  member  = "serviceAccount:${local.argo_cd_application_controller_email}"
}

resource "kubernetes_secret" "cluster_registration" {
  provider = kubernetes.shared

  metadata {
    name      = module.cluster.name
    namespace = "argo-cd"
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }
  data = {
    name   = module.cluster.name
    server = module.cluster.host
    config = <<EOF
      {
        "execProviderConfig": {
          "command": "argocd-k8s-auth",
          "args": ["gcp"],
          "apiVersion": "client.authentication.k8s.io/v1beta1"
        },
        "tlsClientConfig": {
          "insecure": false,
          "caData": "${base64encode(module.cluster.cluster_ca_certificate)}"
        }
      }
EOF
  }

  depends_on = [google_project_iam_member.argo_cd_server, google_project_iam_member.argo_cd_application_controller]
}

resource "kubernetes_manifest" "cluster_app_project" {
  provider = kubernetes.shared

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "AppProject"
    metadata = {
      name      = module.cluster.name
      namespace = "argo-cd"
    }
    spec = {
      description = "Project for ${module.cluster.name} applications"
      sourceRepos = ["*"] # all repositories allowed
      destinations = [{
        namespace = "*"
        server    = module.cluster.host
      }]
      clusterResourceWhitelist = [{
        group = "*"
        kind  = "*"
      }]
    }
  }

}

resource "kubernetes_manifest" "cluster_applications" {
  provider = kubernetes.shared

  manifest = {
    apiVersion = "argoproj.io/v1alpha1"
    kind       = "Application"
    metadata = {
      name      = module.cluster.name
      namespace = "argo-cd"
    }
    spec = {
      destination = { # App of apps is installed in shared cluster
        namespace = "argo-cd"
        server    = "https://kubernetes.default.svc"
      }
      project = "cluster-shared"
      source = {
        path           = module.cluster.name
        repoURL        = var.argo_cd_applications_repo_url
        targetRevision = "HEAD"
        helm = {
          releaseName = "${module.cluster.name}-applications"
          parameters = [{ # But we point our subsequent apps to our newly created cluster, by passing in helm-parameters
            name  = "environment"
            value = "dev"
            }, {
            name  = "destination.server"
            value = module.cluster.host
            }, {
            name  = "chartmuseum.url"
            value = "http://chartmuseum.chartmuseum.svc:8080"
          }]
        }
      }
      syncPolicy = var.argo_cd_sync_policy_automated ? {
        automated = { prune = false }
      } : null
    }
  }

  depends_on = [kubernetes_secret.cluster_registration]
}

# External DNS

module "external_dns" {
  source = "../../modules//external-dns"

  project       = var.project
  chart_version = var.external_dns_version
  dns_zones     = [module.dns_zone.fqdn]
}

# Cert-Manager

module "cert_manager" {
  source = "../../modules//cert-manager"

  project           = var.project
  chart_version     = var.cert_manager_version
  dns_zones         = [module.dns_zone.fqdn]
  letsencrypt_email = var.letsencrypt_email
}

# Kyverno

module "kyverno" {
  source = "../../modules//kyverno"

  chart_version = var.kyverno_version
}

# Crossplane

module "crossplane" {
  source = "../../modules//crossplane"

  chart_version        = var.crossplane_version
  provider_gcp_version = var.crossplane_provider_gcp_version
  project              = var.project
}


# Now we setup the team-specific resources

module "team" {
  for_each = var.teams

  source = "../../modules//team"

  project = var.project
  name    = each.value

  depends_on = [module.cluster, module.crossplane]
}
