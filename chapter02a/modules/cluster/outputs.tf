output "id" {
  value = google_container_cluster.cluster.id
}

output "host" {
  value = "https://${google_container_cluster.cluster.endpoint}"
}

output "cluster_ca_certificate" {
  value = base64decode(google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
}
