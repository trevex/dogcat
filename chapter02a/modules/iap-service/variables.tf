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
  type    = map(string)
  default = {}
}

variable "selector_json" {
  type    = string
  default = "{}"
}

variable "port" {
  type    = number
  default = 8080
}

variable "target_port" {
  type = number
}
