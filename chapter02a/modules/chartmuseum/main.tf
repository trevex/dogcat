resource "kubernetes_namespace" "chartmuseum" {
  metadata {
    name = "chartmuseum"
  }
}

resource "google_storage_bucket" "chartmuseum" {
  name     = "${var.project}-chartmuseum"
  location = "EU"

  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
}

module "wi" {
  source = "..//workload-identity"

  project   = var.project
  name      = "chartmuseum"
  namespace = kubernetes_namespace.chartmuseum.metadata[0].name
  roles     = []
}

resource "google_storage_bucket_iam_member" "bucket_admin" {
  bucket = google_storage_bucket.chartmuseum.name
  role   = "roles/storage.admin"
  member = "serviceAccount:${module.wi.gcp_service_account_email}"
}

resource "helm_release" "chartmuseum" {
  repository = "https://chartmuseum.github.io/charts"
  chart      = "chartmuseum"
  version    = trimprefix(var.chart_version, "v")

  name      = "chartmuseum"
  namespace = kubernetes_namespace.chartmuseum.metadata[0].name

  set {
    name  = "fullnameOverride"
    value = "chartmuseum"
  }
  set {
    name  = "serviceAccount.name"
    value = module.wi.k8s_service_account_name
  }
  set {
    name  = "serviceAccount.create"
    value = "false"
  }
  set {
    name  = "env.open.DISABLE_API"
    value = "false"
  }
  set {
    name  = "env.open.STORAGE"
    value = "google"
  }
  set {
    name  = "env.open.STORAGE_GOOGLE_BUCKET"
    value = google_storage_bucket.chartmuseum.name
  }

  depends_on = [
    google_storage_bucket_iam_member.bucket_admin,
    module.wi
  ]
}
