// Install wordpress and dependencies with ansible
source "docker" "base-ansible" {
  image  = "base-ansible:${var.debian_version}"
  pull   = false
  commit = true
  changes = [
    // Declare all env var here for clarity
    // Wordpress env config
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
    "ENV WP_CONTENT_PATH '/wp-content'",
    "ENV WP_PLUGIN_PATH '/wp-content/plugins'",
    "ENV WP_UPLOADS_PATH '/wp-uploads'",
    "ENV WP_POST_REVISIONS 'true'",

    "EXPOSE 80",

    "HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 CMD ${jsonencode(["apache2ctl", "configtest"])}",

    "USER www-data",
    "WORKDIR ${var.wordpress_workdir}",

    "ENTRYPOINT ${jsonencode(["apache2"])}",
    "CMD ${jsonencode(["-D", "FOREGROUND"])}",
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
      "--extra-vars", "wordpress_workdir=${var.wordpress_workdir}",
      "--extra-vars", "wordpress_version=${var.wordpress_version}",
      "--extra-vars", "wordpress_log_dir=${var.wordpress_log_dir}",
    ]
  }

  post-processors {
    post-processor "docker-tag" {
      repository = var.repository_url
      tags = [
        "latest",
        var.wordpress_version,
        "${var.debian_version}-${var.wordpress_version}",
      ]
    }

    post-processor "docker-push" {
      ecr_login    = true
      login_server = var.repository_url
    }
  }
}
