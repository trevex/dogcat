terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-ch02-tf-state"
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
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com",
    "clouddeploy.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "cloudkms.googleapis.com",
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


# The underlying network mainly for the cluster

module "network" {
  source = "../../modules//network"

  name = "network-shared"
  subnetworks = [{
    name_affix    = "main" # full name will be `${name}-${name_affix}-${region}`
    ip_cidr_range = "10.10.0.0/20"
    region        = var.region
    secondary_ip_range = [{ # Use larger ranges in production!
      range_name    = "pods"
      ip_cidr_range = "10.10.32.0/19"
      }, {
      range_name    = "services"
      ip_cidr_range = "10.10.16.0/20"
    }]
  }]

  depends_on = [google_project_service.services]
}

# Dedicated zone for the shared project

module "dns_zone" {
  source = "../../modules//dns-zone"

  parent_project   = var.dns_project
  parent_zone_name = var.dns_zone_name

  name = "nvoss-demo-dogcat-shared"
  fqdn = var.dns_dedicated_fqdn

  depends_on = [google_project_service.services]
}


# Create GKE Autopilot cluster, where platform components will run in, e.g. ArgoCD and Tekton

module "cluster" {
  source = "../../modules//cluster"

  name                   = "cluster-shared"
  project                = var.project
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["network-shared-main-${var.region}"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  depends_on = [module.network]
}

resource "google_artifact_registry_repository_iam_member" "cluster_ar_reader" {
  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${module.cluster.cluster_sa_email}"
}

###############################################################################
# Setup Crossplane and our Compositions
###############################################################################

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

resource "google_iap_brand" "dogcat" {
  support_email     = var.iap_support_email
  application_title = "Dogcat Shared"

  depends_on = [google_project_service.services]
}

resource "google_iap_web_iam_member" "access_iap_policy" {
  project = var.project
  role    = "roles/iap.httpsResourceAccessor"
  member  = "domain:${var.iap_access_domain}"

  depends_on = [google_project_service.services]
}

module "crossplane" {
  source = "../../modules//crossplane"

  chart_version              = var.crossplane_version
  provider_terraform_version = var.crossplane_provider_terraform_version
  project                    = var.project
  region                     = var.region
}


module "crossplane_composites" {
  source = "../../modules//crossplane-composites"

  project   = var.project
  region    = var.region
  iap_brand = google_iap_brand.dogcat.name

  depends_on = [module.crossplane]
}

# # ArgoCD

# module "argo_cd" {
#   source = "../../modules//argo-cd"

#   project                      = var.project
#   chart_version                = var.argo_cd_version
#   image_updater_chart_version  = var.argo_cd_image_updater_version
#   domain                       = var.argo_cd_domain
#   iap_brand                    = google_iap_brand.dogcat.name
#   artifact_repository_location = google_artifact_registry_repository.images.location

#   depends_on = [module.cert_manager, module.external_dns]
# }

# resource "google_artifact_registry_repository_iam_member" "argo_cd_ar_reader" {
#   project    = google_artifact_registry_repository.images.project
#   location   = google_artifact_registry_repository.images.location
#   repository = google_artifact_registry_repository.images.name

#   role   = "roles/artifactregistry.reader"
#   member = "serviceAccount:${module.argo_cd.image_updater_service_account_email}"
# }

