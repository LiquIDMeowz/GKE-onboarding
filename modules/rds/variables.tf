variable "rds_instance_name" {
  description = "The name of the RDS instance"
  default = "mysql-wordpress-instance"
}

variable "rds_version" {
  description = "The version of the RDS instance"
  default = "MYSQL_8_0"
  
}

variable "resource_region" {
  description = "The region for the RDS instance"
}

variable "rds_password" {
  description = "The password for the RDS instance" 
  
}