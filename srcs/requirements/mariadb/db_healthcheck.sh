#!/bin/bash

# healthcheck script for MariaDB container

ROOT_PASSWORD=$(cat $MYSQL_ROOT_PASSWORD_FILE)
mysqladmin -u root -p"${ROOT_PASSWORD}" ping --silent || exit 1
exit 0


