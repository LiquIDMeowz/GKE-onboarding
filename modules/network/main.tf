resource "google_compute_network" "liquid_vpc" {
  name                     = var.vpc_name
  auto_create_subnetworks  = false
  enable_ula_internal_ipv6 = true
}

resource "google_compute_subnetwork" "liquid_subnet" {
  depends_on = [ google_compute_network.liquid_vpc ]
  name             = var.subnet_name
  ip_cidr_range    = var.subnet_cidr
  region           = var.resource_region
  stack_type       = "IPV4_IPV6" #Switch to IPV4_ONLY later, no need for dual stack 
  ipv6_access_type = "INTERNAL" # Remove later, post switching of the stack type 
  network          = google_compute_network.liquid_vpc.id
  secondary_ip_range {
    range_name    = "services-range"
    ip_cidr_range = var.node_network
  }
  secondary_ip_range {
    range_name    = "pod-ranges"
    ip_cidr_range = var.pod_network
  }
}