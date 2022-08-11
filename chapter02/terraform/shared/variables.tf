variable "project" {
  type = string
}

variable "region" {
  type = string
}

variable "cluster_projects" {
  type = set(string)
}
