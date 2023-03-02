data "google_project" "project" {
}

resource "kubernetes_namespace" "argo_cd" {
  metadata {
    name = "argo-cd"
  }
}

# We manage our service accounts separately to setup workload-identity for
# access to other clusters.

module "argo_cd_server_wi" {
  source = "..//workload-identity"

  project_id = data.google_project.project.project_id
  name       = "argo-cd-server"
  namespace  = kubernetes_namespace.argo_cd.metadata[0].name
}

module "argo_cd_application_controller_wi" {
  source = "..//workload-identity"

  project_id = data.google_project.project.project_id
  name       = "argo-cd-application-controller"
  namespace  = kubernetes_namespace.argo_cd.metadata[0].name
}

# Intentionally not HA as this is a demo, check for production configuration:
# https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd#high-availability
resource "helm_release" "argo_cd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = trimprefix(var.chart_version, "v")

  name      = "argo-cd"
  namespace = kubernetes_namespace.argo_cd.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "argo-cd"
  }
  set { # The LB takes care of TLS
    name  = "configs.params.server.insecure"
    value = "true"
  }
  set {
    name  = "server.extraArgs[0]"
    value = "--insecure"
  }
  set {
    name  = "server.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "server.serviceAccount.name"
    value = module.argo_cd_server_wi.k8s_service_account_name
  }
  set {
    name  = "controller.serviceAccount.create"
    value = "false"
  }
  set {
    name  = "controller.serviceAccount.name"
    value = module.argo_cd_application_controller_wi.k8s_service_account_name
  }
}

# Let's expose the ArgoCD server, but protected via IAP

module "argo_cd_iap_service" {
  source = "..//iap-service"

  iap_brand = var.iap_brand
  name      = "argo-cd-server-iap"
  namespace = kubernetes_namespace.argo_cd.metadata[0].name
  selector = {
    "app.kubernetes.io/instance" = "argo-cd"
    "app.kubernetes.io/name"     = "argocd-server"
  }
  target_port = 8080

  depends_on = [helm_release.argo_cd]
}

resource "kubernetes_ingress_v1" "argo_cd_iap" {
  metadata {
    name      = "argo-cd-server-iap"
    namespace = kubernetes_namespace.argo_cd.metadata[0].name
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    rule {
      host = var.domain
      http {
        path {
          path = "/*"
          backend {
            service {
              name = module.argo_cd_iap_service.name
              port {
                number = module.argo_cd_iap_service.port
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.domain]
      secret_name = "argo-cd-server-tls"
    }
  }
}
