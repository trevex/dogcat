data "http" "manifests" {
  count = var.url != "" ? 1 : 0

  url = var.url
  request_headers = {
    Accept = "text/plain"
    // https://github.com/hashicorp/terraform-provider-http/pull/158
    // will fix warnings, if accepted mime type is ignored...
  }
}

resource "helm_release" "manifests" {
  name      = var.name
  namespace = var.namespace
  chart     = "${path.module}/manifests-chart"

  values = [<<EOT
manifests: |
  ${indent(2, tostring(var.url != "" ? data.http.manifests[0].response_body : var.manifests))}
EOT
  ]
}
