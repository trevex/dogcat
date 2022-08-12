resource "google_service_account" "cluster" {
  account_id   = var.name
  display_name = "SA used by cluster ${var.name}"
}

# We are creating an autopilot cluster so some tfsec rules create false positives, we ignore them:
#tfsec:ignore:google-gke-enforce-pod-security-policy
#tfsec:ignore:google-gke-metadata-endpoints-disabled
#tfsec:ignore:google-gke-enable-network-policy
#tfsec:ignore:google-gke-node-metadata-security
#tfsec:ignore:google-gke-use-cluster-labels
resource "google_container_cluster" "cluster" {
  provider = google-beta

  name     = var.name
  location = var.region

  enable_autopilot = true

  network    = var.network_id
  subnetwork = var.subnetwork_id

  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
    master_global_access_config {
      enabled = true
    }
  }

  master_authorized_networks_config {
    dynamic "cidr_blocks" {
      for_each = var.master_authorized_networks_config
      content {
        display_name = cidr_blocks.key
        cidr_block   = cidr_blocks.value
      }
    }
  }

  node_config {
    service_account = google_service_account.cluster.email
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}