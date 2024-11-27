resource "google_sql_database_instance" "main" {
  name             = var.rds_instance_name
  database_version = var.rds_version
  region           = var.resource_region
  deletion_protection = false
  settings {
    tier = "db-f1-micro"
    disk_size = 10
    backup_configuration {
      enabled                        = true
      start_time                     = "01:00" # Set the start time for the backup in UTC (e.g., 04:00 AM)
    }
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
