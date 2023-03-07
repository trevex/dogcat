resource "kubernetes_namespace" "crossplane" {
  metadata {
    name = "crossplane-system"
  }
}

resource "helm_release" "crossplane" {
  repository = "https://charts.crossplane.io/stable"
  chart      = "crossplane"
  version    = trimprefix(var.chart_version, "v")

  name      = "crossplane"
  namespace = kubernetes_namespace.crossplane.metadata[0].name
}

module "wi" {
  source = "..//workload-identity"

  project   = var.project
  name      = "crossplane-provider-gcp"
  namespace = kubernetes_namespace.crossplane.metadata[0].name
  roles     = ["roles/editor", "roles/iam.serviceAccountAdmin", "roles/cloudsql.client", "roles/resourcemanager.projectIamAdmin"]
}

module "provider" {
  # We intentionally do not use `kubernetes_manifest` to as it will not
  # successfully plan until Crossplane is installed.
  # This can be avoided by using tools such as terragrunt or terramate
  # in a non-demo setup.
  source = "..//helm-manifests"

  name      = "crossplane-provider"
  namespace = kubernetes_namespace.crossplane.metadata[0].name
  manifests = <<EOF
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: crossplane-provider-gcp-config
spec:
  serviceAccountName: ${module.wi.k8s_service_account_name}
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: upbound-provider-gcp
spec:
  package: xpkg.upbound.io/upbound/provider-gcp:${var.provider_gcp_version}
  controllerConfigRef:
    name: crossplane-provider-gcp-config
EOF

  depends_on = [helm_release.crossplane]
}

# TODO: check if we need a create timeout between provider and its config
# resource "time_sleep" "wait_10_seconds" {
#   depends_on = [module.provider]
#   create_duration = "10s"
# }


