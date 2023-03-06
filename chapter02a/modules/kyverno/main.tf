resource "kubernetes_namespace" "kyverno" {
  metadata {
    name = "kyverno"
  }
}

resource "helm_release" "kyverno" {
  repository = "https://kyverno.github.io/kyverno/"
  chart      = "kyverno"
  version    = trimprefix(var.chart_version, "v")

  name      = "kyverno"
  namespace = kubernetes_namespace.kyverno.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "kyverno"
  }
  set {
    name  = "replicaCount"
    value = "1" # to reduce footprint of the demo
  }
}
