variable "project_id" {
  type = string
}

variable "name" {
  type = string
}

variable "namespace" {
  type = string
}

variable "roles" {
  type = set(string)
}
