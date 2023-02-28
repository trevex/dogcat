data "google_project" "project" {
}

resource "kubernetes_namespace" "dns" {
  metadata {
    name = "external-dns"
  }
}

module "wi" {
  source = "..//workload-identity"

  project_id = data.google_project.project.project_id
  name       = "external-dns"
  namespace  = kubernetes_namespace.dns.metadata[0].name
  roles      = ["roles/dns.admin"]
}

resource "helm_release" "external_dns" {
  repository = "https://charts.bitnami.com/bitnami"
  chart      = "external-dns"
  version    = var.chart_version

  name      = "external-dns"
  namespace = kubernetes_namespace.dns.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "external-dns"
  }
  set {
    name  = "serviceAccount.name"
    value = module.wi.k8s_service_account_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "provider"
    value = "google"
  }
  set {
    name  = "google.project"
    value = data.google_project.project.project_id
  }
  set {
    name  = "domainFilters"
    value = "{${join(",", [for zone in var.dns_zones : replace(zone, "/\\.\\z/", "")])}}"
  }
}
