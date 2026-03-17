
# pulls from DockerHub
# bookworm: 120 Mb, slim: 75 Mb
FROM debian:bookworm-slim

# When you run apt-get update, it downloads package lists — indexes of all available packages. These are stored in /var/lib/apt/lists/ and can be quite large (50-100MB).
# Must be in the same RUN as the install — otherwise Docker caches the layer with the lists still in it and the cleanup has no effect on image size.
RUN apt-get update && \
    apt-get install -y mariadb-server && \
    rm -rf /var/lib/apt/lists/* 

# Create mysql user/group if they don't exist
# mariadb-server package creates the mysql user automatically during install. So you probably don't need the groupadd/useradd line.
#RUN groupadd -r mysql && useradd -r -g mysql mysql

# MariaDB needs to listen on all network interfaces, enabling remote connections.
RUN sed -i 's/bind-address\s*=\s*127.0.0.1/bind-address = 0.0.0.0/' \
    /etc/mysql/mariadb.conf.d/50-server.cnf

COPY mariadb_entrypoint.sh /usr/local/bin/entrypoint.sh
COPY db_healthcheck.sh /usr/local/bin/db_healthcheck.sh

RUN chmod +x /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/db_healthcheck.sh

 # runs the script when the container starts, which sets up the database and user for WordPress.
 # The CMD instruction specifies mysqld as param 
ENTRYPOINT ["entrypoint.sh"]
CMD ["mysqld"]