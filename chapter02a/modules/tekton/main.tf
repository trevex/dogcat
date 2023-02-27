
module "tekton_pipeline" {
  source = "..//remote-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/pipeline/previous/${var.pipeline_version}/release.yaml"
  name = "tekton-pipeline"
}

module "tekton_triggers" {
  source = "..//remote-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/triggers/previous/${var.triggers_version}/release.yaml"
  name = "tekton-triggers"

  depends_on = [module.tekton_pipeline]
}

module "tekton_interceptors" {
  source = "..//remote-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/triggers/previous/${var.triggers_version}/interceptors.yaml"
  name = "tekton-interceptors"


  depends_on = [module.tekton_triggers]
}

module "tekton_dashboard" {
  source = "..//remote-manifests"

  url  = "https://storage.googleapis.com/tekton-releases/dashboard/previous/${var.dashboard_version}/release.yaml"
  name = "tekton-dashboard"

  depends_on = [module.tekton_pipeline, module.tekton_triggers]
}
