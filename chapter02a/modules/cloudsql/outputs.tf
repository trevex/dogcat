output "user" {
  value = google_sql_user.user.name
}

output "password" {
  value = random_password.password.result
}

output "database_name" {
  value = google_sql_database.database.name
}

output "host" {
  value = google_sql_database_instance.instance.connection_name
}
