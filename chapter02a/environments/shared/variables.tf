variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "clusters" {
  type        = set(string)
  description = "Full cluster IDs of all clusters. Make sure each cluster has a unique name regardless of ID and name includes target environment."
}

variable "source_repository_name" {
  type = string # TODO: remove?
}

variable "create_source_repository" {
  type = bool
}

variable "tekton_pipeline_version" {
  type = string
}

variable "tekton_triggers_version" {
  type = string
}

variable "tekton_dashboard_version" {
  type = string
}

variable "dns_project_id" {
  type = string
}

variable "dns_zone_name" {
  type = string
}

variable "dns_dedicated_fqdn" {
  type = string
}

variable "external_dns_version" {
  type = string
}
