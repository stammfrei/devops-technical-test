terraform {
  backend "s3" {}

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
      project   = "wordpress-ecs"
      managedBy = "terraform"
      tfRepo    = "https://github.com/stammfrei/devops-technical-test"
      tfFile    = "terraform/main.tf"
    }
  }
}
