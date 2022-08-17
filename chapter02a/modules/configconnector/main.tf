terraform {
  required_providers {
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

data "kubectl_file_documents" "generated" {
  content = file("${path.module}/generated.yaml")
}

resource "kubectl_manifest" "configconnector" {
  for_each  = data.kubectl_file_documents.generated.manifests
  yaml_body = each.value
}
