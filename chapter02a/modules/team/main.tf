resource "kubernetes_namespace" "team" {
  metadata {
    annotations = {
      "cnrm.cloud.google.com/project-id" = var.project
    }

    labels = {
      team = var.name
      env  = regexall(".*(dev|stage|prod).*", var.project)[0][0] // Let's get the suffix
    }

    name = var.name
  }
}
