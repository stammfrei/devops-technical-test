packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }

    ansible = {
      source  = "github.com/hashicorp/ansible"
      version = ">= 1.1.0"
    }
  }
}

variable "debian_version" {
  type    = string
  default = "bookworm"
}

variable "wordpress_version" {
  type    = string
  default = "6.3.1"
}

variable "wordpress_user" {
  type        = string
  description = "The username of the unix user in the wordpress container"
  default     = "wp"
}

variable "wordpress_workdir" {
  type        = string
  description = "The wordpress directory inside the container"
  default     = "/var/www/html"
}

variable "wordpress_logdir" {
  type        = string
  description = "The wordpress logs directory inside the container"
  default     = "/var/log/wp"
}
