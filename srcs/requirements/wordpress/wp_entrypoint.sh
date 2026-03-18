#!/bin/bash
set -e    # exit immediately if any command fails

# Read all secrets immediately as root, before any privilege drop
ROOT_PASSWORD=$(cat /run/secrets/mysql_root_password)
DB_PASSWORD=$(cat /run/secrets/mysql_password)
SUPER_PASSWORD=$(cat /run/secrets/super_password)
USR_PASSWORD=$(cat /run/secrets/user_password)


# 2. Check if the WordPress is installed by checking if the wp-config.php file exists
if [ ! -f "/var/www/html/wp-config.php" ]; then
    echo "First boot detected: Installing WordPress as $(whoami)......"

    # 1. Wait for MariaDB to be healthy
    # Even with the YAML healthcheck, this loop ensures the script 
    # doesn't move forward until the network connection is "clean".
    # :-h"mariadb" hostname 
    # mariadb-client installed -> we can use mariadb-admin
    echo "Checking MariaDB connectivity..."
    until mariadb-admin ping -h mariadb -u ${MYSQL_USER} -p"${DB_PASSWORD}" --silent; do
        echo "MariaDB is not ready yet... sleeping"
        sleep 2
    done


    # Ensure WP-CLI is ready (should be installed via Dockerfile)
    # Download WordPress core files into the current directory (/var/www/html)
    wp core download --allow-root

    # Create config using the hardcoded secret path
    wp config create --allow-root \
        --dbname=$MYSQL_DATABASE \
        --dbuser=$MYSQL_USER \
        --dbpass="${DB_PASSWORD}" \
        --dbhost=mariadb:3306


    wp core install --allow-root \
        --url=$DOMAIN_NAME \
        --title="Inception" \
        --admin_user=$WP_ADMIN_USER \
        --admin_password="${SUPER_PASSWORD}" \
        --admin_email=$WP_ADMIN_EMAIL \
        --skip-email

    wp user create $WP_USER $WP_EMAIL \
        --user_pass="${USR_PASSWORD}" \
        --role=author --allow-root

    wp plugin install redis-cache --activate --allow-root

    echo "WordPress installation complete!"
else
    echo "WordPress is already installed. Starting PHP-FPM..."
fi



# Redis Config
wp config set WP_REDIS_HOST redis --allow-root
wp config set WP_REDIS_PORT 6379 --raw --allow-root
wp config set WP_CACHE true --raw --allow-root
wp config set WP_REDIS_TIMEOUT 1 --raw --allow-root
wp config set WP_REDIS_READ_TIMEOUT 1 --raw --allow-root
wp config set WP_REDIS_GRACEFUL true --raw --allow-root


# Force-refresh the drop-in so it always matches the installed plugin version
wp redis disable --allow-root 2>/dev/null || true
wp redis enable --allow-root


# Ensure the web server owns the files it needs to write to
chown -R www-data:www-data /var/www/html

# 3. Final step: Hand over control to PHP-FPM
# The '-F' flag keeps it running in the foreground so the container stays alive.
echo "Starting PHP-FPM..."
exec gosu www-data /usr/sbin/php-fpm8.2 -F



