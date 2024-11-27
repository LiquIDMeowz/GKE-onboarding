output "vpc_id" {
  value = google_compute_network.liquid_vpc.id
}

output "subnet_id" {
  value = google_compute_subnetwork.liquid_subnet.id
}

output "subnet_secondary_ranges" {
  value = google_compute_subnetwork.liquid_subnet.secondary_ip_range
}