// Install ansible
source "docker" "debian" {
  image  = "debian:bookworm"
  commit = true
  changes = [
    "ENTRYPOINT ${jsonencode(["/bin/bash", "-c"])}",
  ]
}

build {
  name = "base-ansible"
  sources = [
    "source.docker.debian",
  ]

  provisioner "shell" {
    scripts = [
      "packer/wordpress/scripts/install-ansible.sh"
    ]
  }

  post-processor "docker-tag" {
    repository = "base-ansible"
    tags       = [var.wordpress_version]
  }
}
