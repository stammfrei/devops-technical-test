// This file is an 'hello-world'. I used packer long ago, so I train and try
// things here first.

packer {
  required_plugins {
    docker = {
      version = ">= 1.0.8"
      source  = "github.com/hashicorp/docker"
    }
    amazon = {
      source  = "github.com/hashicorp/amazon"
      version = "~> 1"
    }
  }
}

variable "tag" {
  type = string
}


variable "use_aws_ecr" {
  type        = bool
  description = "Do you use aws ecr ?"
  default     = false
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

variable "registry_username" {
  type        = string
  description = "username for ecr login"
  default     = "AWS"
}

variable "registry_password" {
  type        = string
  description = "Registry password"
  sensitive   = true
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
    repository = "${var.repository_url}/packer-second-world"
    tags       = [var.tag]
  }

  post-processor "docker-push" {
    ecr_login    = true
    login_server = var.registry_url
  }
}
