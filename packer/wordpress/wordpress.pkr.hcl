// Build file for the wordpress container

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

variable "tag" {
  type = string
}

// source a container
source "docker" "python" {
  image  = "python:3.11.5"
  commit = true
  changes = [
    "ENTRYPOINT ${jsonencode(["/bin/bash", "-c"])}"
  ]
}

build {
  name = "wordpress"
  sources = [
    "source.docker.python",
  ]

  provisioner "shell" {
    scripts = [
      "packer/wordpress/scripts/install-ansible.sh"
    ]
  }

  post-processor "docker-tag" {
    repository = "wordpress"
    tags       = [var.tag]
  }
}
