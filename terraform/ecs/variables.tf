variable "environment" {
  type        = string
  description = "The environment to deploy to (dev, staging, prod)"
  default     = "dev"
}

variable "cidr_block" {
  type        = string
  description = "cidr ip block for the vpc"
  default     = "192.168.0.0/16"
}

variable "main_subnet_cidr" {
  type        = string
  description = "main wordpress cidr"
  default     = "192.168.1.0/24"
}

variable "image" {
  type        = string
  description = "The wordpress image to deploy"
  default     = "359550916290.dkr.ecr.eu-west-3.amazonaws.com/wp-registry:6.3.1"
}

variable "db_allocated_storage" {
  type        = number
  default     = 20
  description = "storage allocated to the database"

  validation {
    condition     = var.db_allocated_storage >= 20
    error_message = "AWS RDS instances must have at least 20GB in storage"
  }
}

variable "db_mysql_version" {
  type        = string
  default     = "8.0.33"
  description = "mysql engine version"
}

variable "db_instance_class" {
  type        = string
  default     = "db.t2.micro"
  description = "instance class"
}

variable "db_parameter_group_name" {
  type        = string
  default     = "default.mysql8.0"
  description = "see https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_WorkingWithParamGroups.html"
}

variable "db_username" {
  type        = string
  default     = "admin"
  description = "database username"
}

variable "db_password" {
  type        = string
  description = "instance password"
  sensitive   = true
}

variable "wp_folder_reset" {
  type        = bool
  description = "This variable enable a full wipe and reset of the wordpress folder"
  default     = true
}

variable "wp_config_reset" {
  type        = bool
  description = "This variable enable a full wipe and reset of the wp-config file"
  default     = false
}

locals {
  container_name = "wordpress"
}

