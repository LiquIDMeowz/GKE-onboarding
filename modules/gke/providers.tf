provider "kubernetes" {
  host                   = "https://${google_container_cluster.liquid_cluster.endpoint}"
  cluster_ca_certificate = base64decode(google_container_cluster.liquid_cluster.master_auth[0].cluster_ca_certificate)
  token                  = data.google_client_config.default.access_token
}

provider "helm" {
  kubernetes {
    host                   = "https://${google_container_cluster.liquid_cluster.endpoint}"
    cluster_ca_certificate = base64decode(google_container_cluster.liquid_cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.default.access_token
  }
}