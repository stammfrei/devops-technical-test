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

variable "wordpress_version" {
  type    = string
  default = "6.3.1"
}

variable "php_version" {
  type    = string
  default = "8.3"
}

// source a container
source "docker" "python" {
  image  = "debian:bookworm"
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

  provisioner "ansible-local" {
    playbook_file = "./packer/wordpress/ansible/build.yml"
    command       = "/opt/ansible.sh"
  }

  post-processor "docker-tag" {
    repository = "wordpress"
    tags       = [var.tag]
  }
}
