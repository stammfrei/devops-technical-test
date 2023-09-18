#! /usr/bin/env bash

echo "Starting wordpress container" >/dev/stderr

if [ "${WP_INIT_FOLDER:-"false"}" == "true" ]; then
	echo "Wiping /var/www/html"
	rm -rf /var/www/html/*

	echo "Initialising wordpress folder" >/dev/stderr
	cp -rf /var/wp/src/* /var/www/html
fi

if [ "${WP_RESET_CONFIG:-"false"}" == "true" ]; then
	echo "Reset wp-config.php" >/dev/stderr
	cp -f /var/wp/src/wp-config.php /var/www/html/wp-config
fi

echo "Starting apache2 directory."
apache2 -D FOREGROUND
