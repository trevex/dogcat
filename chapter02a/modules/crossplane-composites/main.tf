module "composites" {
  # We intentionally do not use `kubernetes_manifest` as it will not
  # successfully plan until Crossplane is installed.
  # This can be avoided by using tools such as terragrunt or terramate
  # in a non-demo setup.
  source = "..//helm-manifests"

  name      = "crossplane-composites"
  namespace = "crossplane-system"

  manifests = <<EOF
${templatefile("${path.module}/files/workloadidentity.yaml", {
  project = var.project
  # We pass in the src explicitly as we are crossing module boundaries here
  # for simplicity, if template was self-contained we could use ${file(...)}
  src_files = [
    file("${path.module}/../workload-identity/variables.tf"),
    file("${path.module}/../workload-identity/main.tf"),
    file("${path.module}/../workload-identity/outputs.tf"),
  ]
  })}
---
${templatefile("${path.module}/files/iapservice.yaml", {
  iap_brand = var.iap_brand
  # See note above
  src_files = [
    file("${path.module}/../iap-service/variables.tf"),
    file("${path.module}/../iap-service/main.tf"),
    file("${path.module}/../iap-service/outputs.tf"),
  ]
  })}
---
${templatefile("${path.module}/files/cloudsql.yaml", {
  region = var.region
  # See note above
  src_files = [
    file("${path.module}/../cloudsql/variables.tf"),
    file("${path.module}/../cloudsql/main.tf"),
    file("${path.module}/../cloudsql/outputs.tf"),
  ]
})}
---
EOF

}
