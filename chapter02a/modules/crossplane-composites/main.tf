resource "kubernetes_secret" "provider_terraform_variables" {
  metadata {
    name      = "provider-terraform-variables"
    namespace = "default"
  }
  data = {
    "default.tfvars" = <<EOF
project = "${var.project}"
region = "${var.region}"
EOF
  }
}

module "composites" {
  # We intentionally do not use `kubernetes_manifest` as it will not
  # successfully plan until Crossplane is installed.
  # This can be avoided by using tools such as terragrunt or terramate
  # in a non-demo setup.
  source = "..//helm-manifests"

  name      = "crossplane-composites"
  namespace = "crossplane-system"

  manifests = <<EOF
${templatefile("${path.module}/files/serviceaccount.yaml", {
  # We pass in the src explicitly as we are crossing module boundaries here
  # for simplicity, if template was self-contained we could use ${file(...)}
  src_files = [
    file("${path.module}/../workload-identity/variables.tf"),
    file("${path.module}/../workload-identity/main.tf"),
    file("${path.module}/../workload-identity/outputs.tf"),
  ]
})}
---
EOF

depends_on = [
  kubernetes_secret.provider_terraform_variables
]
}
