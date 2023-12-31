output "k8s_service_account_name" {
  value = kubernetes_manifest.sa.manifest.metadata.name
}

output "gcp_service_account_email" {
  value = google_service_account.sa.email
}

output "gcp_service_account_name" {
  value = google_service_account.sa.name
}

output "gcp_roles" {
  value = local.roles
}
