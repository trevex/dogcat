terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

resource "google_service_account" "configconnector" {
  account_id   = "configconnector"
  display_name = "Service Account used by ConfigConnector."
}

resource "google_project_iam_member" "configconnector_project_access" {
  project = var.project
  role    = "roles/owner"
  member  = "serviceAccount:${google_service_account.configconnector.email}"
}

resource "google_service_account_iam_member" "configconnector_workload_identity" {
  service_account_id = google_service_account.configconnector.id
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project}.svc.id.goog[cnrm-system/cnrm-controller-manager]"
}

# NOTE: we can't use `kubernetes_manifest` due to:
#       https://github.com/hashicorp/terraform-provider-kubernetes/issues/1380
resource "kubectl_manifest" "configconnector_config" {
  yaml_body = <<-EOF
apiVersion: core.cnrm.cloud.google.com/v1beta1
kind: ConfigConnector
metadata:
  name: configconnector.core.cnrm.cloud.google.com
spec:
 mode: cluster
 googleServiceAccount: "${google_service_account.configconnector.email}"
EOF

  depends_on = [
    google_service_account_iam_member.configconnector_workload_identity
  ]
}
