resource "kubernetes_namespace" "argo_cd" {
  metadata {
    name = "argo-cd"
  }
}

# Intentionally not HA as this is a demo, check:
# https://github.com/argoproj/argo-helm/tree/main/charts/argo-cd#high-availability
resource "helm_release" "argo_cd" {
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = trimprefix(var.chart_version, "v")

  name      = "argo-cd"
  namespace = kubernetes_namespace.argo_cd.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "argo-cd"
  }
}
