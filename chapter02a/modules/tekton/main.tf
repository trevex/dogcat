
module "tekton_pipeline" {
  source = "..//helm-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/pipeline/previous/${var.pipeline_version}/release.yaml"
  name = "tekton-pipeline"
}

module "tekton_triggers" {
  source = "..//helm-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/triggers/previous/${var.triggers_version}/release.yaml"
  name = "tekton-triggers"

  depends_on = [module.tekton_pipeline]
}

module "tekton_interceptors" {
  source = "..//helm-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/triggers/previous/${var.triggers_version}/interceptors.yaml"
  name = "tekton-interceptors"


  depends_on = [module.tekton_triggers]
}

module "tekton_dashboard" {
  source = "..//helm-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/dashboard/previous/${var.dashboard_version}/release.yaml"
  name = "tekton-dashboard"

  depends_on = [module.tekton_pipeline, module.tekton_triggers]
}

# Let's expose the dashboard, but protected via IAP

module "tekton_dashboard_iap_service" {
  source = "..//iap-service"

  iap_brand   = var.iap_brand
  name        = "tekton-dashboard-iap"
  namespace   = "tekton-pipelines"
  selector    = { "app" = "tekton-dashboard" }
  target_port = 9097

  depends_on = [module.tekton_dashboard]
}

resource "kubernetes_ingress_v1" "tekton_dasboard_iap" {
  metadata {
    name      = "tekton-dashboard-iap"
    namespace = "tekton-pipelines"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }

  spec {
    rule {
      host = var.dashboard_domain
      http {
        path {
          path = "/*"
          backend {
            service {
              name = module.tekton_dashboard_iap_service.name
              port {
                number = module.tekton_dashboard_iap_service.port
              }
            }
          }
        }
      }
    }

    tls {
      hosts       = [var.dashboard_domain]
      secret_name = "tekton-dashboard-tls"
    }
  }
}

resource "kubernetes_namespace" "tekton" {
  metadata {
    name = "tekton"
  }
}

module "wi" {
  source = "..//workload-identity"

  project   = var.project
  name      = "tekton"
  namespace = kubernetes_namespace.tekton.metadata[0].name
  roles     = ["roles/artifactregistry.writer"] # NOTE: should be more fine-granular for production on per AR-level
}
