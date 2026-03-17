#!/bin/bash
# Start PHP-FPM in the background
service php8.2-fpm start
# Start Nginx in the foreground
nginx -g "daemon off;"