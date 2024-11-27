variable "credentials_file" {
  description = "Path to the GC JSON"
}

variable "project_id" {
  description = "The project ID"
}

variable "resource_region" {
  description = "The GC region"
}

variable "zone" {
  description = "value of the zone"
}

variable "vpc_name" {
  description = "The name of the VPC"
}

variable "subnet_name" {
  description = "The name of the subnet"

}
variable "subnet_cidr" {
  description = "The CIDR block for the subnet"
}

variable "node_network" {
  description = "The network for the nodes"
}

variable "pod_network" {
  description = "The network for the pods"
}

variable "cluster_name" {
  description = "The name of the cluster"
}

variable "pool_name" {
  description = "The name of the pool"
  
}

variable "rds_password" {
  description = "The password for the RDS instance" 
  
}