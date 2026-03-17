
# pulls from DockerHub
# bookworm: 120 Mb, slim: 30 Mb
FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y \
    redis-server && \
    rm -rf /var/lib/apt/lists/* 

# By default, Redis only listens to 127.0.0.1. 
# We need to change 'bind' to 0.0.0.0 to allow other containers to connect.
RUN sed -i "s|bind 127.0.0.1|bind 0.0.0.0|g" /etc/redis/redis.conf

# 5. Expose port 6379 for Redis
EXPOSE  6379

# if running without a password and default settings: goes in Protected Mode"
# -> only answers to localhost (127.0.0.1)
# our WordPress is in a different container -> connecting via the Docker network IP
CMD ["redis-server", "/etc/redis/redis.conf", "--daemonize", "no", "--protected-mode", "no", "--logfile", ""]