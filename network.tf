module "network" {
  source   = "./modules/network"
  vpc_name = var.vpc_name
  subnet_name = var.subnet_name
  resource_region = var.resource_region
  subnet_cidr = var.subnet_cidr
  node_network = var.node_network
  pod_network = var.pod_network
}
