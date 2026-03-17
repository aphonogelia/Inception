
# pulls from DockerHub
# bookworm: 120 Mb, slim: 75 Mb
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    nginx \
    php8.2-fpm \
    php8.2-mysql \
    mariadb-client \
    curl \
    && rm -rf /var/lib/apt/lists/* 

# copy the adminer file
RUN mkdir -p /var/www/adminer
COPY --chown=www-data:www-data php/adminer.php /var/www/adminer/index.php
    
# copy nginx configuration
RUN rm -rf /etc/nginx/sites-enabled/default
COPY --chown=www-data:www-data bonus.conf /etc/nginx/conf.d/default.conf

# PHP-FPM config: Keep the socket! 
# Ensure the socket directory exists and is owned by www-data
RUN mkdir -p /run/php && chown www-data:www-data /run/php

# 1. Redirect Nginx logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# 2. Redirect PHP-FPM logs (Standard for PHP 8.2)
RUN ln -sf /dev/stderr /var/log/php8.2-fpm.log

# Copy the script that will handle the auto-configuration using secrets
COPY --chown=www-data:www-data adminer_entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Expose port 8081 for HTTPS
EXPOSE  8081

ENTRYPOINT ["entrypoint.sh"]