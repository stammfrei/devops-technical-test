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

    amazon = { // for aws credential management
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
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

variable "wordpress_workdir" {
  type        = string
  description = "The wordpress directory inside the container"
  default     = "/var/www/html"
}

variable "wordpress_log_dir" {
  type        = string
  description = "The wordpress logs directory inside the container"
  default     = "/var/log/wp"
}

variable "repository_url" {
  type        = string
  description = "The image repository to use"
  default     = ""
}

variable "registry_url" {
  type        = string
  description = "A valid aws ect url for pushing your image"
}
