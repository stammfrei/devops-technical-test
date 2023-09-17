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
  # default     = "359550916290.dkr.ecr.eu-west-3.amazonaws.com/wp-registry:6.3.1"
  default = "traefik/whoami:latest"
}

variable "db_allocated_storage" {
  type        = int
  default     = 2
  description = "storage allocated to the database"
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

