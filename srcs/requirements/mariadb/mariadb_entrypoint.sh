#!/bin/bash
set -e    # exit immediately if any command fails

# Ensure directories exist and have right permissions
# When Docker mounts a volume, it can sometimes change the permissions 
# of the directory you set up during the build phase. Running chown in 
# your entrypoint.sh ensures that the permissions are correct
mkdir -p /var/run/mysqld
chown -R mysql:mysql /var/run/mysqld
chown -R mysql:mysql /var/lib/mysql

# 1. Check if the 'mysql' system database exists in the volume
if [ ! -d "/var/lib/mysql/mysql" ]; then
    echo "First boot detected: Initializing database files..."
    # This command creates the system tables (users, permissions, etc.)
    mysql_install_db --user=mysql --datadir=/var/lib/mysql 
    echo "Initialization complete."
else
    echo "Database files already exist. Skipping initialization."
fi


# 2. Check secret files exist
if [ ! -f "$MYSQL_PASSWORD_FILE" ]; then
    echo "Error: $MYSQL_PASSWORD_FILE not found"
    exit 1
fi
if [ ! -f "$MYSQL_ROOT_PASSWORD_FILE" ]; then
    echo "Error: $MYSQL_ROOT_PASSWORD_FILE not found"
    exit 1
fi

# Read passwords from secrets
DB_PASSWORD=$(cat $MYSQL_PASSWORD_FILE)
ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)

# Check passwords are not empty
if [ -z "$DB_PASSWORD" ] || [ -z "$ROOT_PASSWORD" ]; then
    echo "Error: passwords cannot be empty"
    exit 1
fi


# 3. Start MariaDB temporarily in background - no user can connect to it, but we can run SQL commands to set up the database and user.
mysqld_safe --skip-networking &
MYSQL_PID=$!

# wait for MariaDB to start up before running SQL commands
TIMEOUT=30
COUNTER=0
until mysqladmin -u root -p"${ROOT_PASSWORD}" --socket=/var/run/mysqld/mysqld.sock ping --silent 2>/dev/null \
   || mysqladmin -u root --socket=/var/run/mysqld/mysqld.sock ping --silent 2>/dev/null; do
    echo "Waiting for MariaDB to start..."
    sleep 1
    COUNTER=$((COUNTER + 1))
    if [ $COUNTER -ge $TIMEOUT ]; then
        echo "Error: Timeout waiting for MariaDB to start"
        exit 1
    fi
done





# 4. Set the root password and create the database and user for WordPress.
if [ ! -d "/var/lib/mysql/${MYSQL_DATABASE}" ]; then
    echo "Configuring MariaDB for the first time..."
    mysql -u root << EOF
CREATE DATABASE IF NOT EXISTS ${MYSQL_DATABASE};
CREATE USER IF NOT EXISTS '${MYSQL_USER}'@'%' IDENTIFIED BY '${DB_PASSWORD}';
GRANT ALL PRIVILEGES ON ${MYSQL_DATABASE}.* TO '${MYSQL_USER}'@'%';
ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASSWORD}';
FLUSH PRIVILEGES;
EOF
# Shut down using the NEW password
    mysqladmin -u root -p"${ROOT_PASSWORD}" shutdown
else
    echo "Database ${MYSQL_DATABASE} already exists. Skipping SQL setup."
    # Shut down the background process so 'exec' can take over the port
    mysqladmin -u root -p"${ROOT_PASSWORD}" shutdown
    #kill $MYSQL_PID
fi

wait $MYSQL_PID

# The exec command replaces the current shell with the mysqld process, so that it becomes the main process of the container. This is important for proper signal handling and graceful shutdown of the container.
echo "MariaDB setup complete. Starting mysqld..."
exec "$@" --user=mysql
