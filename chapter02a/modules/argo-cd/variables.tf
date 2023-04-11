variable "project" {
  type     = string
  nullable = false
}

variable "chart_version" {
  type = string
}

variable "image_updater_chart_version" {
  type = string
}

variable "artifact_repository_location" {
  type = string
}

variable "iap_brand" {
  type = string
}

variable "domain" {
  type = string
}
