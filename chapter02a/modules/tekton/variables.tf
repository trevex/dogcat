variable "project" {
  type     = string
  nullable = false
}

variable "pipeline_version" {
  type = string
}

variable "triggers_version" {
  type = string
}

variable "dashboard_version" {
  type = string
}

variable "chains_version" {
  type = string
}

variable "dashboard_domain" {
  type = string
}

variable "iap_brand" {
  type = string
}
