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

// source a container
source "docker" "python" {
  image  = "debian:bookworm"
  commit = true
  changes = [
    "USER ${var.wordpress_user}",
    "WORKDIR ${var.wordpress_workdir}",
    "ENV WP_DB_NAME ''",
    "ENV WP_DB_USER ''",
    "ENV WP_DB_PASSWORD ''",
    "ENV WP_DB_HOST ''",
    "ENV WP_DB_CHARSET utf8",
    "ENV WP_DB_COLLATE ''",
    "ENV WP_TABLE_PREFIX 'wp_'",
    "ENV WP_DEBUG 'false'",
    "ENV WP_AUTH_KEY ''",
    "ENV WP_SECURE_AUTH_KEY ''",
    "ENV WP_LOGGED_IN_KEY ''",
    "ENV WP_NONCE_KEY ''",
    "ENV WP_AUTH_SALT ''",
    "ENV WP_SECURE_AUTH_SALT ''",
    "ENV WP_LOGGED_IN_SALT ''",
    "ENV WP_NONCE_SALT ''",
    "EXPOSE 9000",
    "ENTRYPOINT ${jsonencode(["/bin/bash", "-c"])}",
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
    playbook_dir  = "./packer/wordpress/ansible"
    playbook_file = "./packer/wordpress/ansible/build.yml"
    extra_arguments = [
      "--extra-vars", "wordpress_user=${var.wordpress_user}",
      "--extra-vars", "wordpress_workdir=${var.wordpress_workdir}",
      "--extra-vars", "wordpress_version=${var.wordpress_version}",
      "--extra-vars", "wordpress_logdir=${var.wordpress_logdir}",
    ]
  }

  post-processor "docker-tag" {
    repository = "wordpress"
    tags       = [var.wordpress_version]
  }
}
