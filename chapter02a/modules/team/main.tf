resource "kubernetes_namespace" "team" {
  metadata {
    annotations = {
      "cnrm.cloud.google.com/project-id" = var.project
    }

    labels = {
      team = var.name
      env  = regexall(".*(dev|stg|prd).*", var.project)[0][0] // Let's get the suffix
    }

    name = var.name
  }
}

module "provider_config" {
  # We intentionally do not use `kubernetes_manifest` to as it will not
  # successfully plan until Crossplane is installed.
  # This can be avoided by using tools such as terragrunt or terramate
  # in a non-demo setup.
  source = "..//helm-manifests"

  name      = "crossplane-provider-config"
  namespace = kubernetes_namespace.team.metadata[0].name
  manifests = <<EOF
apiVersion: gcp.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  projectID: ${var.project}
  credentials:
    source: InjectedIdentity
EOF
}
