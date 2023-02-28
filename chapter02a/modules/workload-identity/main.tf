resource "google_service_account" "sa" {
  account_id   = var.name
  display_name = substr("GCP SA bound to K8S SA ${var.namespace}/${var.name}]", 0, 100)
  project      = var.project_id
}

resource "kubernetes_service_account" "sa" {
  metadata {
    name      = var.name
    namespace = var.namespace
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.sa.email
    }
  }
  automount_service_account_token = true
}

resource "google_service_account_iam_member" "wi" {
  service_account_id = google_service_account.sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.namespace}/${var.name}]"
}

resource "google_project_iam_member" "roles" {
  for_each = var.roles

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.sa.email}"
}
