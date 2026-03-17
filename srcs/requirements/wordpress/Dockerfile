FROM debian:bookworm-slim

# Install PHP-FPM and PHP-MySQL bridge
# mariadb-client: allows us to use 'mariadb-admin' to check DB status
# curl: required to download WP-CLI and WordPress core
# php8.2-redis : for bonus part
RUN apt-get update && apt-get install -y \
     php8.2-fpm \
     php8.2-mysql \
     php8.2-gd \
     php8.2-redis \
     mariadb-client \
     redis-tools \ 
     curl \
     gosu \
     && rm -rf /var/lib/apt/lists/* 
     
# 2. Download and install WP-CLI (still as root)
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar  && \
    mv wp-cli.phar /usr/local/bin/wp

# 3. Create directories and fix permissions BEFORE switching
# /var/www/html: standard directory for web files
# /run/php: required for PHP-FPM to store its process ID (PID) file
RUN mkdir -p /var/www/html /run/php && \
    chown -R www-data:www-data /var/www/html /run/php && \
    touch /var/log/php8.2-fpm.log && \
    chown www-data:www-data /var/log/php8.2-fpm.log

# 4. Configure PHP-FPM
# config: location ~ \.php$ { fastcgi_pass wordpress:9000;
# By default PHP-FPM listens on a Unix socket (local file).
# We change it to Port 9000 so Nginx can communicate with it over the Docker network.
RUN sed -i 's|listen = /run/php/php8.2-fpm.sock|listen = 9000|g' /etc/php/8.2/fpm/pool.d/www.conf


# Copy the script that will handle the auto-configuration using secrets
COPY wp_entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# 6 All subsequent commands (like WP-CLI) will execute in this folder
WORKDIR /var/www/html

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]