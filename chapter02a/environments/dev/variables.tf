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
