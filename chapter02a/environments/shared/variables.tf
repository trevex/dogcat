variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_projects" {
  type = set(string)
}

variable "source_repository_name" {
  type = string
}

variable "create_source_repository" {
  type = bool
}

variable "state_bucket_name" {
  type = string
}
