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

module "provider_terraform_wi" {
  source = "..//workload-identity"

  project   = var.project
  name      = "crossplane-provider-terraform"
  namespace = kubernetes_namespace.crossplane.metadata[0].name
  roles     = ["roles/editor", "roles/iam.serviceAccountAdmin", "roles/cloudsql.client", "roles/resourcemanager.projectIamAdmin"]
}

module "provider_terraform" {
  # We intentionally do not use `kubernetes_manifest` as it will not
  # successfully plan until Crossplane is installed.
  # This can be avoided by using tools such as terragrunt or terramate
  # in a non-demo setup.
  source = "..//helm-manifests"

  name      = "crossplane-provider-terraform"
  namespace = kubernetes_namespace.crossplane.metadata[0].name
  # NOTE: For a production setup you should review the permissions assigned via
  #       the ClusterRoleBinding below.
  manifests = <<EOF
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: crossplane-provider-terraform-cluster-admin
subjects:
- kind: ServiceAccount
  name: ${module.provider_terraform_wi.k8s_service_account_name}
  namespace: ${kubernetes_namespace.crossplane.metadata[0].name}
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: pkg.crossplane.io/v1alpha1
kind: ControllerConfig
metadata:
  name: crossplane-provider-terraform-config
spec:
  serviceAccountName: ${module.provider_terraform_wi.k8s_service_account_name}
---
apiVersion: pkg.crossplane.io/v1
kind: Provider
metadata:
  name: provider-terraform
spec:
  package: xpkg.upbound.io/upbound/provider-terraform:${var.provider_terraform_version}
  controllerConfigRef:
    name: crossplane-provider-terraform-config
EOF

  depends_on = [helm_release.crossplane]
}

# TODO: check if we need a create timeout between provider and its config
# resource "time_sleep" "wait_10_seconds" {
#   depends_on = [module.provider_terraform]
#   create_duration = "10s"
# }

module "provider_terraform_config" {
  # See reason to use helm above
  source = "..//helm-manifests"

  name      = "crossplane-provider-terraform-config"
  namespace = kubernetes_namespace.crossplane.metadata[0].name
  manifests = <<EOF
apiVersion: tf.upbound.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  configuration: |
    provider "google" {
      project = "${var.project}"
      region  = "${var.region}"
    }

    terraform {
      backend "kubernetes" {
        secret_suffix     = "providerconfig-default"
        namespace         = "crossplane-system"
        in_cluster_config = true
      }
    }
EOF
}


