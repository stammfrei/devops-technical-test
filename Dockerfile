FROM debian:bookworm

RUN apt update
RUN apt install -y apache2
RUN apt install -y php php-mysql git

RUN rm -rf /var/www/html
RUN git clone git://core.git.wordpress.org/ --depth 1 --branch "6.3.1" /var/www/html -q --single-branch 
RUN chown -R www-data:www-data /var/www 
RUN chmod 0740 /var/www/html 
RUN chown -R www-data:www-data /var/log 
RUN chmod 0740 /var/log
RUN chown -R www-data:www-data /etc/apache2
RUN chmod 0740 /etc/apache2

ENV APACHE_RUN_DIR="/etc/apache2"
ENV APACHE_RUN_USER="www-data"
ENV APACHE_RUN_GROUP="www-data"
ENV APACHE_LOG_DIR="/var/log/apache2"
ENV APACHE_PID_FILE="/etc/apache2/pidfile"

COPY conf/ /etc/apache2/
COPY packer/wordpress/ansible/templates/wp-config.php.j2 /var/www/html/wp-config.php

# Cleanup
RUN apt purge -y git

HEALTHCHECK --interval=10s --timeout=5s --start-period=5s --retries=3 CMD [ "apache2ctl", "configtest" ]

EXPOSE 80
USER www-data

CMD ["/usr/sbin/apache2", "-X"]

