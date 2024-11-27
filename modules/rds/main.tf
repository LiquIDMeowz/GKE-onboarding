resource "google_sql_database_instance" "main" {
  name             = var.rds_instance_name
  database_version = var.rds_version
  region           = var.resource_region

  settings {
    tier = "db-f1-micro"
  }
}

resource "google_sql_database" "wordpress_database" {
  name     = "wordpress"
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "wordpress_user" {
  name     = "wordpress"
  instance = google_sql_database_instance.main.name
  host = "%"
  password = var.rds_password
}
