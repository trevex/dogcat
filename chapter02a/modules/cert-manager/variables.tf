variable "chart_version" {
  type = string
}

variable "dns_zones" {
  type = set(string)
}

variable "letsencrypt_email" {
  type = string
}
