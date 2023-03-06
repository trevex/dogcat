output "cluster_id" {
  value = module.cluster.id
}

output "artifact_repository_id" {
  value = google_artifact_registry_repository.images.id
}

output "tekton_trigger_secret" {
  value     = random_password.tekton_trigger_secret.result
  sensitive = true
}
