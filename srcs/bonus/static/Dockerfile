
# pulls from DockerHub
# bookworm: 120 Mb, slim: 75 Mb
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    nginx \
    curl \
    && rm -rf /var/lib/apt/lists/* 

# 1. Remove the default Debian site to ensure your bonus.conf is used
RUN rm -rf /etc/nginx/sites-enabled/default

# 2. Create the directory for your static site
RUN mkdir -p /var/www/aquamemoria

# 3. Copy your HTML file into the folder
COPY --chown=www-data:www-data html/aqua.html /var/www/aquamemoria
    
# 4. Copy your specific bonus configuration
COPY --chown=www-data:www-data bonus.conf /etc/nginx/conf.d/default.conf

# Redirect nginx logs to docker log collector
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# 5. Expose port 8080 for HTTPS
EXPOSE  8080

CMD ["nginx", "-g", "daemon off;"]