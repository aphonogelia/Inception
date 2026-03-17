
# pulls from DockerHub
# bookworm: 120 Mb, slim: 75 Mb
FROM debian:bookworm-slim

# When you run apt-get update, it downloads package lists — indexes of all available packages. These are stored in /var/lib/apt/lists/ and can be quite large (50-100MB).
# Must be in the same RUN as the install — otherwise Docker caches the layer with the lists still in it and the cleanup has no effect on image size.
RUN apt-get update && \
    apt-get install -y nginx openssl && \
    rm -rf /var/lib/apt/lists/* 

# Create the directory for the SSL certificates
RUN mkdir -p /etc/ssl/private /etc/ssl/certs /var/www/html /var/www/aquamemoria

# Generate the SSL certificate (Self-signed) for wordpress (443)
ARG DOMAIN_NAME STATIC_NAME ADMINER_NAME
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -keyout /etc/ssl/private/nginx-selfsigned.key \
    -out /etc/ssl/certs/nginx-selfsigned.crt \
    -subj "/C=FR/ST=IDF/L=Paris/O=42/OU=42/CN=${DOMAIN_NAME}" \
    -addext "subjectAltName = DNS:${DOMAIN_NAME}, DNS:${STATIC_NAME}, DNS:${ADMINER_NAME}"


# Configuration and Static Files
COPY --chown=www-data:www-data nginx.conf /etc/nginx/conf.d/default.conf

# logs
RUN ln -sf /dev/stdout /var/log/nginx/access.log \
    && ln -sf /dev/stderr /var/log/nginx/error.log

# Expose port 443 for HTTPS
EXPOSE 443

CMD ["nginx", "-g", "daemon off;"]