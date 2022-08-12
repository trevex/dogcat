terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-chapter-02-tf-state"
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
    "compute.googleapis.com",
    "container.googleapis.com",
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
    secondary_ip_range = [{
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

data "http" "myip" {
  url = "https://ipinfo.io/ip"
}


module "cluster" {
  source = "../../modules//cluster"

  name                   = "dev-cluster"
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["dev-network-main-europe-west1"].id
  master_ipv4_cidr_block = "172.16.0.0/28"
  master_authorized_networks_config = {
    "My IP" = "${chomp(data.http.myip.body)}/32"
  }

  depends_on = [google_project_service.services]
}
