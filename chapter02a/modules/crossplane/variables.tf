variable "chart_version" {
  type = string
}

variable "provider_terraform_version" {
  type = string
}

variable "project" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
}
