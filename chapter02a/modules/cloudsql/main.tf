resource "google_sql_database_instance" "instance" {
  name             = var.name
  database_version = var.version
  region           = var.region

  settings {
    tier              = var.tier
    availability_type = var.availability_type
    disk_size         = var.disk_size
    backup_configuration {
      enabled = var.backups
    }
  }

  deletion_protection = var.deletion_protection
}

locals {
  database_name = var.database_name == "" ? var.name : var.database_name
}

resource "google_sql_database" "database" {
  name            = local.database_name
  instance        = google_sql_database_instance.instance.name
  deletion_policy = var.deletion_protection ? "ABANDON" : "DELETE"
}

resource "random_password" "password" {
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

locals {
  user = var.user == "" ? var.name : var.user
}

resource "google_sql_user" "user" {
  name     = local.user
  instance = google_sql_database_instance.instance.name
  password = random_password.password.result
}
