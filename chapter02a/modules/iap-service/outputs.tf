output "name" {
  value = kubernetes_service.service.metadata[0].name
}

output "port" {
  value = kubernetes_service.service.spec[0].port[0].port
}
