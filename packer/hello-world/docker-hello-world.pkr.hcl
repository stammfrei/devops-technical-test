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

// source a container
source "docker" "ubuntu" {
  image  = "ubuntu:22.04"
  commit = true
  changes = [
    "ENTRYPOINT ${jsonencode(["/bin/bash", "-c"])}"
  ]
}

build {
  name = "hello-world"
  sources = [
    "source.docker.ubuntu",
  ]

  provisioner "shell" {
    environment_vars = [
      "NAME=toto",
    ]

    inline = [
      "echo 1>&2 Adding file to container",
      "echo \"Hello $NAME\" > hello.txt",
      "mkdir -p /app",
    ]
  }

  provisioner "file" {
    source      = "./ci/build.sh"
    destination = "/app/build.sh"
  }

  post-processor "docker-tag" {
    repository = "packer-hello-world"
    tags       = [var.tag]
  }
}

// source a container
source "docker" "hello-world" {
  image  = "packer-hello-world:${var.tag}"
  pull   = false
  commit = true
  changes = [
    "ENTRYPOINT ${jsonencode(["/bin/bash", "-c"])}"
  ]
}

build {
  name = "second-world"
  sources = [
    "source.docker.hello-world"
  ]

  provisioner "shell" {
    environment_vars = [
      "NAME=toto",
    ]

    inline = [
      "echo 1>&2 Adding file to container",
      "echo \"Hello tutitu\" >> hello.txt",
    ]
  }

  post-processor "docker-tag" {
    repository = "packer-second-world"
    tags       = [var.tag]
  }
}
