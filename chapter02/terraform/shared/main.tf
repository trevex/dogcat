terraform {
  backend "gcs" {
    bucket = "nvoss-dogcat-chapter-02-tf-state"
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
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com",
  ])
  project = var.project
  service = each.value
}

# Let's create our artifact registry for our container-images

resource "google_artifact_registry_repository" "images" {
  location      = var.region
  repository_id = "images"
  description   = "Primary container-image registry"
  format        = "DOCKER"

  depends_on = [google_project_service.services]
}

# And we give all our compute in cluster projects reader access to container-images

data "google_project" "cluster_project" {
  for_each   = var.cluster_projects
  project_id = each.value
}

resource "google_artifact_registry_repository_iam_member" "compute_ar_reader" {
  for_each = var.cluster_projects

  project    = google_artifact_registry_repository.images.project
  location   = google_artifact_registry_repository.images.location
  repository = google_artifact_registry_repository.images.name
  role       = "roles/artifactregistry.reader"
  member     = "serviceAccount:${data.google_project.cluster_project[each.key].number}-compute@developer.gserviceaccount.com"
}
