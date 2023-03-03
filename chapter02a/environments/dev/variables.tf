variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "teams" {
  type = set(string)
}

variable "artifact_repository_id" {
  type = string
}

variable "shared_cluster_id" {
  type = string
}

variable "argo_cd_applications_repo_url" {
  type = string
}

variable "argo_cd_sync_policy_automated" {
  type = bool
}
