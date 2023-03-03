variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "iap_support_email" {
  type = string
}

variable "iap_access_domain" {
  type = string
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

variable "tekton_dashboard_domain" {
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

variable "cert_manager_version" {
  type = string
}

variable "letsencrypt_email" {
  type = string
}

variable "argo_cd_version" {
  type = string
}

variable "argo_cd_domain" {
  type = string
}

variable "argo_cd_applications_repo_url" {
  type = string
}
