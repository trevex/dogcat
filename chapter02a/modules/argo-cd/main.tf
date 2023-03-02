resource "kubernetes_namespace" "argo_cd" {
  metadata {
    name = "argo-cd"
  }
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
