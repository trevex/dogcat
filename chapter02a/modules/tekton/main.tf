
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

// We need to fetch tekton-chains separately and apply a patch.
data "http" "tekton_chain_manifests" {
  url = "https://storage.googleapis.com/tekton-releases/chains/previous/${var.chains_version}/release.yaml"
  request_headers = {
    Accept = "text/plain"
    // https://github.com/hashicorp/terraform-provider-http/pull/158
    // will fix warnings, if accepted mime type is ignored...
  }
}

module "tekton_chains" {
  source = "..//helm-manifests"

  name = "tekton-chains"
  # https://issuetracker.google.com/issues/227162588
  manifests = replace(tostring(data.http.tekton_chain_manifests.response_body), "/safe-to-evict: \"false\"/", "safe-to-evict: \"true\"")

  depends_on = [module.tekton_pipeline, module.tekton_triggers]
}

resource "google_kms_key_ring" "tekton_chains" {
  name     = "tekton-chains"
  location = "global"
}

resource "google_kms_crypto_key" "tekton_chains" {
  name     = "cosign"
  key_ring = google_kms_key_ring.tekton_chains.id
  purpose  = "ASYMMETRIC_SIGN"

  version_template {
    algorithm = "EC_SIGN_P384_SHA384"
  }

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_key_ring_iam_member" "key_ring" {
  key_ring_id = google_kms_key_ring.tekton_chains.id
  role        = "roles/cloudkms.viewer"
  member      = "serviceAccount:${module.wi.gcp_service_account_email}"
}

resource "google_kms_crypto_key_iam_member" "crypto_key" {
  crypto_key_id = google_kms_crypto_key.tekton_chains.id
  role          = "roles/cloudkms.signerVerifier"
  member        = "serviceAccount:${module.wi.gcp_service_account_email}"
}

# NOTE: Using this kind of resource with helm is a pain, so we work around it,
#       by storing the revision in the data, but we should consider deploying via ArgoCD instead.
resource "kubernetes_config_map_v1_data" "tekton_chains" {
  force = true
  metadata {
    name      = "chains-config"
    namespace = "tekton-chains"
  }

  data = {
    "artifacts.taskrun.signer"     = "kms"
    "artifacts.pipelinerun.signer" = "kms"
    "artifacts.oci.signer"         = "kms"
    "signers.kms.kmsref"           = "gcpkms://${google_kms_key_ring.tekton_chains.id}/cryptoKeys/${google_kms_crypto_key.tekton_chains.name}"
    "storage.grafeas.notehint"     = "We are using this field as dummy for the revision: ${module.tekton_chains.revision}"
  }
  depends_on = [module.tekton_chains]
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


