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
