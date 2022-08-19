resource "google_service_account" "cluster" {
  account_id   = var.name
  display_name = "Service Account used by GKE cluster: '${var.name}'."
}

resource "google_project_iam_member" "cluster_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.cluster.email}"
}

resource "google_project_iam_member" "cluster_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.cluster.email}"
}

resource "google_project_iam_member" "cluster_monitoring_viewer" {
  project = var.project
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.cluster.email}"
}

resource "google_project_iam_member" "cluster_metadata_writer" {
  project = var.project
  role    = "roles/stackdriver.resourceMetadata.writer"
  member  = "serviceAccount:${google_service_account.cluster.email}"
}

#tfsec:ignore:google-gke-enable-network-policy We use Dataplane V2 with NPs by default.
#tfsec:ignore:google-gke-enforce-pod-security-policy We intentionally do not use PSPs.
#tfsec:ignore:google-gke-enable-master-networks Keeping setup simple, see retro for additional details.
resource "google_container_cluster" "cluster" {
  #checkov:skip=CKV_GCP_61:We do not use VPC Flow Logs in this demo
  #checkov:skip=CKV_GCP_66:TODO let's enable Binary Auth in the future!
  #checkov:skip=CKV_GCP_65:Well, to simplify the demo we do not use Google Groups in GKE
  #checkov:skip=CKV_GCP_24:We do not use PSPs in this demo
  #checkov:skip=CKV_GCP_20:Keeping setup simple, see retro for additional details.
  #checkov:skip=CKV_GCP_19:False positive, basic auth disabled by default.
  #checkov:skip=CKV_GCP_13:False positive, client cert disabled by default.
  #checkov:skip=CKV_GCP_12:False positive, network policy available on DPV2 by default.
  #checkov:skip=CKV_GCP_67:False positive, default node pool is not used.
  #checkov:skip=CKV_GCP_69:False positive, default node pool is not used.
  provider = google-beta

  name     = var.name
  location = var.region

  network           = var.network_id
  subnetwork        = var.subnetwork_id
  datapath_provider = "ADVANCED_DATAPATH" # We use Dataplane V2

  resource_labels = { # The var.name should contain the environment in its name, if not we error
    "managed-by" = "tf"
    "env"        = regexall(".*(dev|stage|prod).*", var.name)[0][0]
  }

  remove_default_node_pool = true
  initial_node_count       = 1

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

  # We use workload identity
  workload_identity_config {
    workload_pool = "${var.project}.svc.id.goog"
  }

  addons_config {
    # HTTP LB and HPA will be available by default
    config_connector_config {
      enabled = true
    }
  }

  node_config {
    # Argolis specific to avoid issue with org-policy
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }

  lifecycle {
    ignore_changes = [
      node_config # required due to Argolis workaround
    ]
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

#tfsec:ignore:google-gke-metadata-endpoints-disabled They are disabled, not sure why check still triggers
resource "google_container_node_pool" "default" {
  provider = google-beta

  name     = "default"
  project  = var.project
  location = var.region
  cluster  = google_container_cluster.cluster.name

  initial_node_count = 1

  autoscaling {
    min_node_count = 1
    max_node_count = 5
  }

  management {
    auto_repair  = true
    auto_upgrade = true
  }

  upgrade_settings {
    max_surge       = 1
    max_unavailable = 1
  }

  node_config {
    image_type = "COS_CONTAINERD"
    # Minimizing costs of the demo, but in the real world most likely at least
    # 8 cores desired to get maximum network bandwidth allocated
    machine_type    = "n1-standard-4"
    preemptible     = false
    local_ssd_count = 0
    disk_size_gb    = 80
    disk_type       = "pd-standard"

    # No access to legacy metadata servers
    metadata = {
      "disable-legacy-endpoints" = true
    }

    # We specify the service account to minimize permissions and not use default compute account
    service_account = google_service_account.cluster.email

    workload_metadata_config {
      mode = "GKE_METADATA"
    }

    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/monitoring" # required for Managed Prometheus
    ]

    labels = {
      default = "true"
    }
    tags = [var.name]
  }

  lifecycle {
    ignore_changes  = [initial_node_count]
    prevent_destroy = false
  }

  timeouts {
    create = "45m"
    update = "45m"
    delete = "45m"
  }
}

# For the admission controllers we need to allow ingress
# Can be reduced further if ports are known, e.g. 8443

resource "google_compute_firewall" "admission" {
  project     = var.project
  name        = "allow-gke-cp-access-admission-controller"
  network     = var.network_id
  description = "Allow ingress on tcp from GKE Control-Plane"

  allow {
    protocol = "tcp"
  }

  source_ranges = [google_container_cluster.cluster.private_cluster_config[0].master_ipv4_cidr_block]
  target_tags   = [var.name]
}

