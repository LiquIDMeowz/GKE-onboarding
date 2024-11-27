variable "vpc_name" {
  description = "The name of the VPC"
}

variable "subnet_name" {
  description = "The name of the subnet"
}

variable "resource_region" {
  description = "The region"
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
