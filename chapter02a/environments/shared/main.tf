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
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com",
    "clouddeploy.googleapis.com",
    "dns.googleapis.com",
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
  # Format: "projects/my-project-name/locations/us-west1/clusters/example-cluster-name"
  cluster_splits = [for c in var.clusters : split("/", c)]
  clusters = { for s in local.cluster_splits : s[5] => {
    cluster_id = join("/", s)
    project    = s[1]
    location   = s[3]
    name       = s[5]
    # Environment is extracted from cluster name
    env = regexall(".*(dev|stage|prod).*", s[5])[0][0]
  } }
}

resource "google_artifact_registry_repository_iam_member" "compute_ar_reader" {
  for_each = local.clusters

  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  # TODO: This is a rather implicit contract to how the cluster-module works.
  #       Most likely we should revisit this in the future and make it explicit using a variable.
  #       Maybe moving to the relevant envs would be better...
  member = "serviceAccount:${each.value.name}@${each.value.project}.iam.gserviceaccount.com"
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

  parent_project_id = var.dns_project_id
  parent_zone_name  = var.dns_zone_name

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
  subnetwork_id          = module.network.subnetworks["network-shared-main-europe-west1"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  depends_on = [google_project_service.services]
}

###############################################################################
# Setup Tekton, ArgoCD, External-DNS, Cert-Manager
###############################################################################

data "google_client_config" "cluster" {}

provider "kubernetes" {
  host                   = module.cluster.host
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    token                  = data.google_client_config.cluster.access_token
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
  }
}

# Tekton

module "tekton" {
  source = "../../modules//tekton"

  pipeline_version  = var.tekton_pipeline_version
  triggers_version  = var.tekton_triggers_version
  dashboard_version = var.tekton_dashboard_version
}

# External DNS

module "external_dns" {
  source = "../../modules//external-dns"

  chart_version = var.external_dns_version
  dns_zones     = [module.dns_zone.fqdn]
}

# Cert-Manager

module "cert_manager" {
  source = "../../modules//cert-manager"

  chart_version     = var.cert_manager_version
  dns_zones         = [module.dns_zone.fqdn]
  letsencrypt_email = var.letsencrypt_email
}

# ArgoCD

module "argo_cd" {
  source = "../../modules//argo-cd"

  chart_version = var.argo_cd_version
}
