provider "google" {
  project = var.project_id
  region  = var.resource_region
  zone    = var.zone
  credentials = file(var.credentials_file)
}