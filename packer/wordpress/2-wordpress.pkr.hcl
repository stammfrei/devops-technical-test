// Install wordpress and dependencies with ansible
source "docker" "base-ansible" {
  image  = "base-ansible:${var.wordpress_version}"
  pull   = false
  commit = true
  changes = [
    "USER ${var.wordpress_user}",
    "WORKDIR ${var.wordpress_workdir}",

    // Declare all env var here for clarity
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
    "source.docker.base-ansible",
  ]

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
