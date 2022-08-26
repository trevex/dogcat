terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-chapter-02-tf-state"
    prefix = "terraform/dev"
  }

  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
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
  ])
  project = var.project
  service = each.value
}

module "network" {
  source = "../../modules//network"

  name = "dev-network"
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



# Create GKE Autopilot cluster

module "cluster" {
  source = "../../modules//cluster"

  name                   = "dev-cluster"
  project                = var.project
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["dev-network-main-europe-west1"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  depends_on = [google_project_service.services]
}


data "google_client_config" "cluster" {}

provider "kubectl" {
  host                   = module.cluster.host
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  load_config_file       = false
}

provider "kubernetes" {
  host                   = module.cluster.host
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
}

module "configconnector" {
  source = "../../modules//configconnector"

  project = var.project

  depends_on = [module.cluster]
}

module "team" {
  for_each = var.teams

  source = "../../modules//team"

  project = var.project
  name    = each.value

  depends_on = [module.cluster]
}
