// This file is an 'hello-world'. I used packer long ago, so I train and try
// things here first.

packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable "tag" {
  type = string
}

source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
}

build {
  name = "hello-world"
  sources = [
    "source.docker.ubuntu"
  ]

  provisioner "shell" {
    environment_vars = [
      "NAME=toto",
    ]

    inline = [
      "echo 1>&2 Adding file to container",
      "echo \"Hello $NAME\" > hello.txt",
    ]
  }

  post-processor "docker-tag" {
    repository = "packer-hello-world"
    tags       = [var.tag]
  }
}
