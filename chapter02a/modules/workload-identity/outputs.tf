output "k8s_service_account_name" {
  value = kubernetes_service_account.sa.metadata[0].name
}
