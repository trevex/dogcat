# We are creating an autopilot cluster so some tfsec rules create false positives, we ignore them:
#tfsec:ignore:google-gke-enforce-pod-security-policy
#tfsec:ignore:google-gke-metadata-endpoints-disabled
#tfsec:ignore:google-gke-enable-network-policy
#tfsec:ignore:google-gke-node-metadata-security
#tfsec:ignore:google-gke-use-cluster-labels
resource "google_container_cluster" "cluster" {
  #checkov:skip=CKV_GCP_21:We do not use labels in this demo
  #checkov:skip=CKV_GCP_61:We do not use VPC Flow Logs in this demo
  #checkov:skip=CKV_GCP_66:TODO let's enable Binary Auth in the future!
  #checkov:skip=CKV_GCP_12:We do not use Network Policies in this demo
  #checkov:skip=CKV_GCP_65:Well, to simplify the demo we do not use Google Groups in GKE
  #checkov:skip=CKV_GCP_68:Node configuration irrelevant for Autopilot
  #checkov:skip=CKV_GCP_69:Node configuration irrelevant for Autopilot
  #checkov:skip=CKV_GCP_19:Disabled on Autopilot by default => false positive
  #checkov:skip=CKV_GCP_67:Legacy compute instance metadata API not relevant on Autopilot
  #checkov:skip=CKV_GCP_13:Certificate based authentication irrelevant using Autopilot
  #checkov:skip=CKV_GCP_24:No privileged workloads on Autopilot, so PSPs irrelevant
  provider = google-beta

  name     = var.name
  location = var.region

  enable_autopilot = true

  network    = var.network_id
  subnetwork = var.subnetwork_id

  release_channel {
    channel = var.release_channel
  }

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

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}
