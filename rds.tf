module "rds" {
  source   = "./modules/rds"
  resource_region = var.resource_region
  rds_password = var.rds_password
}