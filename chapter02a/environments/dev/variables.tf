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

variable "iap_support_email" {
  type = string
}

variable "iap_access_domain" {
  type = string
}

variable "argo_cd_applications_repo_url" {
  type = string
}

variable "argo_cd_sync_policy_automated" {
  type = bool
}

variable "kyverno_version" {
  type = string
}

variable "crossplane_version" {
  type = string
}

variable "crossplane_provider_terraform_version" {
  type = string
}

variable "dns_project" {
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

variable "cert_manager_version" {
  type = string
}

variable "letsencrypt_email" {
  type = string
}
