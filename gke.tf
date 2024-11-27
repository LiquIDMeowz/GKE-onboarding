module "gke" {
  source   = "./modules/gke"
  cluster_name = var.cluster_name
  resource_region = var.resource_region
  vpc_id = module.network.vpc_id
  subnet_id = module.network.subnet_id
  subnet_secondary_ranges = module.network.subnet_secondary_ranges
  pool_name = var.pool_name
}