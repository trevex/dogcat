variable "iap_brand" {
  type = string
}

variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "selector" {
  type = map(string)
}

variable "port" {
  type    = number
  default = 8080
}

variable "target_port" {
  type = number
}
