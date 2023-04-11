terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-chapter02-tf-state"
    prefix = "terraform/shared"
  }
}

provider "google" {
  project = var.project
  region  = var.region
}

provider "google-beta" {
  project = var.project
  region  = var.region
}


# Enable required APIs

resource "google_project_service" "services" {
  for_each = toset([
    "cloudresourcemanager.googleapis.com",
    "compute.googleapis.com",
    "container.googleapis.com",
    "iam.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
    "sourcerepo.googleapis.com",
    "clouddeploy.googleapis.com",
    "dns.googleapis.com",
    "iap.googleapis.com",
    "cloudkms.googleapis.com",
  ])
  project = var.project
  service = each.value
}


# Let's create our artifact registry for our container-images

resource "google_artifact_registry_repository" "images" {
  #checkov:skip=CKV_GCP_84:We do not want to use CSEK
  location      = var.region
  repository_id = "images"
  description   = "Primary container-image registry"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}


# The underlying network mainly for the cluster

module "network" {
  source = "../../modules//network"

  name = "network-shared"
  subnetworks = [{
    name_affix    = "main" # full name will be `${name}-${name_affix}-${region}`
    ip_cidr_range = "10.10.0.0/20"
    region        = var.region
    secondary_ip_range = [{ # Use larger ranges in production!
      range_name    = "pods"
      ip_cidr_range = "10.10.32.0/19"
      }, {
      range_name    = "services"
      ip_cidr_range = "10.10.16.0/20"
    }]
  }]

  depends_on = [google_project_service.services]
}

# Dedicated zone for the shared project

module "dns_zone" {
  source = "../../modules//dns-zone"

  parent_project   = var.dns_project
  parent_zone_name = var.dns_zone_name

  name = "nvoss-demo-dogcat-shared"
  fqdn = var.dns_dedicated_fqdn

  depends_on = [google_project_service.services]
}


# Create GKE Autopilot cluster, where platform components will run in, e.g. ArgoCD and Tekton

module "cluster" {
  source = "../../modules//cluster"

  name                   = "cluster-shared"
  project                = var.project
  region                 = var.region
  network_id             = module.network.id
  subnetwork_id          = module.network.subnetworks["network-shared-main-${var.region}"].id
  master_ipv4_cidr_block = "172.16.0.0/28"

  depends_on = [module.network]
}

resource "google_artifact_registry_repository_iam_member" "cluster_ar_reader" {
  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${module.cluster.cluster_sa_email}"
}

###############################################################################
# Setup Tekton, ArgoCD, External-DNS, Cert-Manager
###############################################################################

data "google_client_config" "cluster" {}

provider "kubernetes" {
  host                   = module.cluster.host
  token                  = data.google_client_config.cluster.access_token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
  ignore_annotations = [
    "cloud\\.google\\.com\\/neg-status"
  ]
}

provider "helm" {
  kubernetes {
    host                   = module.cluster.host
    token                  = data.google_client_config.cluster.access_token
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
  }
}

resource "google_iap_brand" "dogcat" {
  support_email     = var.iap_support_email
  application_title = "Dogcat Shared"

  depends_on = [google_project_service.services]
}

resource "google_iap_web_iam_member" "access_iap_policy" {
  project = var.project
  role    = "roles/iap.httpsResourceAccessor"
  member  = "domain:${var.iap_access_domain}"

  depends_on = [google_project_service.services]
}

# External DNS

module "external_dns" {
  source = "../../modules//external-dns"

  project       = var.project
  chart_version = var.external_dns_version
  dns_zones     = [module.dns_zone.fqdn]
}

# Cert-Manager

module "cert_manager" {
  source = "../../modules//cert-manager"

  project           = var.project
  chart_version     = var.cert_manager_version
  dns_zones         = [module.dns_zone.fqdn]
  letsencrypt_email = var.letsencrypt_email
}

# Chartmuseum

module "chartmuseum" {
  source = "../../modules//chartmuseum"

  project       = var.project
  chart_version = var.chartmuseum_version
}

# ArgoCD

module "argo_cd" {
  source = "../../modules//argo-cd"

  project                      = var.project
  chart_version                = var.argo_cd_version
  image_updater_chart_version  = var.argo_cd_image_updater_version
  domain                       = var.argo_cd_domain
  iap_brand                    = google_iap_brand.dogcat.name
  artifact_repository_location = google_artifact_registry_repository.images.location

  depends_on = [module.cert_manager, module.external_dns]
}

resource "google_artifact_registry_repository_iam_member" "argo_cd_ar_reader" {
  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name

  role   = "roles/artifactregistry.reader"
  member = "serviceAccount:${module.argo_cd.image_updater_service_account_email}"
}

# # We use the apps of apps pattern, so we need to register our applications repository:

resource "kubernetes_secret" "argo_cd_applications" {
  metadata {
    name      = "argo-cd-applications"
    namespace = "argo-cd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }
  data = {
    type = "git"
    url  = var.argo_cd_applications_repo_url
  }

  depends_on = [module.argo_cd]
}

module "argo_cd_platform" {
  # We intentionally do not use `kubernetes_manifest` to as it will not
  # successfully plan until ArgoCD is installed.
  source = "../../modules//helm-manifests"

  name      = "argo-cd-${module.cluster.name}"
  manifests = <<EOF
apiVersion: argoproj.io/v1alpha1
kind: AppProject
metadata:
  name: ${module.cluster.name}
  namespace: argo-cd
spec:
  description: Project for shared cluster system components
  sourceRepos:
    - ${var.argo_cd_applications_repo_url}
  destinations:
    - namespace: "*"
      server: "https://kubernetes.default.svc"
  clusterResourceWhitelist:
    - group: "*"
      kind: "*"
EOF

  depends_on = [module.argo_cd]
}


# # Tekton

module "tekton" {
  source = "../../modules//tekton"

  project           = var.project
  pipeline_version  = var.tekton_pipeline_version
  triggers_version  = var.tekton_triggers_version
  chains_version    = var.tekton_chains_version
  dashboard_version = var.tekton_dashboard_version
  dashboard_domain  = var.tekton_dashboard_domain
  iap_brand         = google_iap_brand.dogcat.name

  depends_on = [module.cert_manager, module.argo_cd]
}


# We also use ArgoCD to deploy Tekton Pipelines for our applications:

module "tekton_application_pipelines" {
  # We intentionally do not use `kubernetes_manifest` to as it will not
  # successfully plan until ArgoCD is installed.
  source = "../../modules//helm-manifests"

  name      = "tekton-application-pipelines"
  manifests = <<EOF
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: tekton-application-pipelines
  namespace: argo-cd
spec:
  destination:
    namespace: tekton
    server: "https://kubernetes.default.svc"
  project: ${module.cluster.name}
  source:
    path: "tekton"
    repoURL: ${var.argo_cd_applications_repo_url}
    targetRevision: HEAD
  syncPolicy:
    automated: {}
 EOF

  depends_on = [module.tekton, module.argo_cd_platform]
}

# Let's configure a tekton trigger, that can schedule PipelineRuns

module "tekton_trigger" {
  source = "../../modules//tekton-trigger"

  trigger_domain  = "trigger.${var.tekton_dashboard_domain}"
  image_base      = "${google_artifact_registry_repository.images.location}-docker.pkg.dev/${var.project}/${google_artifact_registry_repository.images.repository_id}"
  git_base_url    = var.tekton_trigger_git_base_url
  chartmuseum_url = module.chartmuseum.internal_url

  depends_on = [module.tekton]
}

