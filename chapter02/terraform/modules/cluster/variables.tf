variable "name" {
  type = string
}

variable "region" {
  type = string
}

variable "network_id" {
  type = string
}

variable "subnetwork_id" {
  type = string
}

variable "cluster_secondary_range_name" {
  type    = string
  default = "pods"
}

variable "services_secondary_range_name" {
  type    = string
  default = "services"
}

variable "master_ipv4_cidr_block" {
  type = string
}

variable "master_authorized_networks_config" {
  type        = map(string)
  description = "Maps of authorizted networks using key as name and value as CIDR-block"
}
