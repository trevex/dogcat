variable "name" {
  type     = string
  nullable = false
}

variable "version" {
  type    = string
  default = "POSTGRES_14"
}

variable "region" {
  type     = string
  nullable = false
}

variable "tier" {
  type    = string
  default = "db-f1-micro"
}

variable "availability_type" {
  type    = string
  default = "ZONAL"
}

variable "disk_size" {
  type    = number
  default = 10
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "database_name" {
  type    = string
  default = ""
}

variable "user" {
  type    = string
  default = ""
}

variable "backups" {
  type    = bool
  default = true
}
