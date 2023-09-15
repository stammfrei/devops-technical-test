terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  default_tags {
    // Since AWS don't have resource group I will use tags to group
    // my resources
    tags = {
      project   = var.project_name
      managedBy = "terraform"
      tfRepo    = "https://github.com/stammfrei/devops-technical-test"
      tfFile    = "terraform/main.tf"
    }
  }
}

variable "project_name" {
  type    = string
  default = "wordpress"
}

variable "wordpress_image_name" {
  type    = string
  default = "wordpress-debian-bookworm"
}

variable "wordpress_image_tag" {
  type    = string
  default = "6.3.1"
}

resource "aws_ecr_repository" "registry" {
  name                 = "wp-registry"
  image_tag_mutability = "MUTABLE" // I use a mutable one since I will not manage versions
}

data "aws_ecr_authorization_token" "registry_token" {
  registry_id = aws_ecr_repository.registry.registry_id
}

output "registry_url" {
  value     = data.aws_ecr_authorization_token.registry_token.proxy_endpoint
  sensitive = false
}

output "registry_username" {
  value     = data.aws_ecr_authorization_token.registry_token.user_name
  sensitive = false
}

output "registry_password" {
  value     = data.aws_ecr_authorization_token.registry_token.password
  sensitive = true
}

output "repository_url" {
  value = aws_ecr_repository.registry.repository_url
}

