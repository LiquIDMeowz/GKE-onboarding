module "nginx-controller" {
  depends_on = [ google_container_cluster.liquid_cluster ]
  source  = "terraform-iaac/nginx-controller/helm"
}