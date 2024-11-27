resource "google_container_cluster" "liquid_cluster" {
  name                     = var.cluster_name
  location                 = var.resource_region
  enable_l4_ilb_subsetting = true
  network                  = var.vpc_id
  subnetwork               = var.subnet_id
  remove_default_node_pool = true
  initial_node_count       = 1
  ip_allocation_policy {
    stack_type                    = "IPV4"
    services_secondary_range_name = var.subnet_secondary_ranges[0].range_name
    cluster_secondary_range_name  = var.subnet_secondary_ranges[1].range_name
  }
  deletion_protection = false
}


resource "google_container_node_pool" "liquid_pool" {
  depends_on = [ google_container_cluster.liquid_cluster ]
  name               = var.pool_name
  cluster            = google_container_cluster.liquid_cluster.name
  location           = var.resource_region
  node_count = 1
  autoscaling {
    min_node_count = 1
    max_node_count = 3
  }
  node_config {
    machine_type = "e2-standard-4"
    disk_size_gb = 20
    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform",
      "https://www.googleapis.com/auth/userinfo.email"
    ]
  }
  management {
    auto_upgrade = true
    auto_repair  = true
  }
}

module "nginx-controller" {
  source  = "terraform-iaac/nginx-controller/helm"
}

