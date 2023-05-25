
resource "google_iap_client" "client" {
  display_name = var.name
  brand        = var.iap_brand
}

resource "kubernetes_secret" "iap" {
  metadata {
    name      = var.name
    namespace = var.namespace
  }

  data = {
    "client_secret" : google_iap_client.client.secret
    "client_id" : google_iap_client.client.client_id
  }
}

resource "kubernetes_manifest" "config" {
  manifest = {
    apiVersion = "cloud.google.com/v1"
    kind       = "BackendConfig"
    metadata = {
      name = var.name
      namespace : var.namespace
    }
    spec = {
      iap = {
        enabled = true
        oauthclientCredentials = {
          secretName = kubernetes_secret.iap.metadata[0].name
        }
      }
    }
  }
}

locals {
  selector = length(var.selector) == 0 ? try(jsondecode(var.selector_json), {}) : var.selector
}

resource "kubernetes_service" "service" {
  metadata {
    name      = var.name
    namespace = var.namespace
    annotations = {
      "cloud.google.com/backend-config" = "{\"ports\": {\"default\":\"${kubernetes_manifest.config.manifest.metadata.name}\"}}"
      "cloud.google.com/neg"            = "{\"ingress\": true}"
    }
  }
  spec {
    type     = "ClusterIP"
    selector = local.selector
    port {
      name        = "default"
      port        = var.port
      target_port = var.target_port
    }
  }
  lifecycle {
    ignore_changes = [
      metadata[0].annotations["cloud.google.com/neg-status"],
    ]
  }
}
