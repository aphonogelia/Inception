


## Terms

# Docker Image
A read-only blueprint built from a Dockerfile (a list of commands to install an OS + dependencies).
Composed of stacked layers; every instruction in your Dockerfile (like RUN, COPY, or ADD) creates a new layer. These layers are cached, meaning if you change one line, Docker only rebuilds from that layer down.

# Docker Container
A running instance of an image. It is a set of isolated processes sharing the host’s OS kernel. When a container starts, Docker adds a thin writable layer on top of the read-only image layers.

# Docker Volume
A volume is a persistent storage on your host machine that gets mounted inside a container. Managed by Docker, exists outside the container's lifecycle. The container can read/write to it
- Persistence: Data survives even if the container is deleted (docker rm).
- Storage: Usually stored on the host machine but managed by the Docker engine.
- Without a volume: All data inside a container is "ephemeral" and is lost when the container is removed.


## docker-compose.yml

# YAML stands for 
"YAML Ain't Markup Language" — a recursive acronym (and joke).
Originally "Yet Another Markup Language", changed to distinguish it from markup languages like HTML/XML. YAML is about data, not document formatting.
Why not json? Early Docker did use JSON for some things. But json is not very readable, does not support comments, is less verbose.

# SYNTAX RULES:
- Indentation matters — use 2 spaces, never tabs
- Key/value pairs: separated by a colon and a space
- list: items need a -. Volumes is a list:
  <volumes:
    - type: bind      
      source: /home/htharrau/data/wordpress
      target: /var/www/html>

single items: list or not:
ports:
  - "443:443"
  - "80:80"  
depends_on:
  - wordpress
  - mariadb   
volumes:
  - /home/htharrau/data/wordpress:/var/www/html
  - /home/htharrau/data/other:/var/other   # easy to add more

Without - (inline syntax)
<ports: "443:443">        # only works for single value
<depends_on: wordpress>   # only works for single value
<volumes: 
 - /home/htharrau/data/wordpress:/var/www/html>
volumes inline syntax doesn't actually work in Docker Compose. It always requires list syntax

# top-level keywords
<services:> defines your containers - always required 
<volumes:> defines named volumes
<networks:> defines networks
<secrets:> defines secrets
<configs:> similar to secrets but for non-sensitive config files
<version:> used to be required, now deprecated




### Volumes

# Named volume (required in inception) 
Docker manages the path. You give it a name (e.g. wp_database)
It is the most robust way to persist data in Docker.
- Storage: Docker stores it at /var/lib/docker/volumes/wp_database/_data by default
- You can override the location with driver_opts (what we do for Inception)
- Advantages:
  + Easy to inspect: <docker volume ls>
  + Easy to backup: you know exactly what to back up
  + Survives container deletion
  + Reusable across containers
  + Portable — no hardcoded host paths in your compose file
- Lifecycle: 
  + created when <docker compose up> runs for the first time. 
  + NOT deleted on <down>, 
  + only deleted explicitly with <docker volume rm> or <docker compose down -v>

<services:
  mariadb:
    volumes:
      - wp_database:/var/lib/mysql  # name:container_path>
<volumes:
  wp_database:          # basic
    driver: local

  wp_database:          # with custom host location (what we use)
    driver: local
    driver_opts:
      type: none
      o: bind
      device: /home/htharrau/data/mariadb>


# Bind mount
Directly maps a host path to a container path. You are in full control of where the data lives.
How it works:
- Path must exist on host before container starts
- No Docker management — it's just a direct filesystem link
- Changes on host are instantly reflected in container and vice versa
- Often used in development to live-edit code without rebuilding

Long form syntax: 
<volumes:
  - type: bind
    source: /home/htharrau/data/mariadb
    target: /var/lib/mysql>
Short form syntax:
<volumes:
  - /home/htharrau/data/mariadb:/var/lib/mysql>


# tmpfs
Temporary File System — stores data in RAM instead of disk.
- Super fast (RAM speed)
- Completely gone when container stops (inception: data needs to persist)
- Useful for sensitive data you never want written to disk (like session tokens)
Syntax:
+ In services section
<services:
  wordpress:
    tmpfs:
      - /tmp          # short form>
+ Long form
<volumes:
      - type: tmpfs
        target: /tmp
        tmpfs:
          size: 100m  # optional size limit>


# Anonymous volume
- Created automatically when you specify only a container path (<volumes: /var/lib/mysql>)
- Docker stores it at /var/lib/docker/volumes/<randomID>/_data
- Nearly impossible to track or reuse -> ❌ Bad practice


# services:
  <myservice:
    volumes:
      - wp_database:/var/lib/mysql          # named volume
      - /home/htharrau/data:/var/lib/mysql  # bind mount
      - /var/lib/mysql                       # anonymous volume
      - type: tmpfs                          # tmpfs
        target: /tmp>


## LINUX PATH CONVENTIONS
<Application         Default data path>
MariaDB               /var/lib/mysql
WordPress             /var/www/html
nginx config          /etc/nginxlogs/var/log
Docker secrets        /run/secrets


## Top level declaration?
 
# service alone IS enough for simple cases
<services:
  mariadb:
    volumes:
      - wp_database:/var/lib/mysql>

<volumes:
  wp_database:    # empty! no config needed>

(Bind mount syntax goes inside the service, not in the top level volumes: block. Top level volumes: is only for named volumes.)

# top level declaration needed wwen extra config
- Custom host path (Inception): Need <driver_opts>
- External volume (created outside compose) (If a volume was created manually before compose runs:<docker volume create my_data>): Need <external: true>
- Specific size limit: Need <driver_opts>
- Shared between multiple compose files: Need <external: true>


### MAIN SERVICES KEYWORDS

services:
  myservice:
    # IMAGE / BUILD
    build:          # path to Dockerfile
    image:          # pull from registry (forbidden in Inception)

    # IDENTITY
    container_name: # custom name for the container
    hostname:       # hostname inside the network

    # RUNTIME
    restart:        # restart policy
    command:        # override default command
    entrypoint:     # override default entrypoint
    working_dir:    # set working directory inside container

    # ENVIRONMENT
    env_file:       # load variables from a file
    environment:    # set variables directly
    secrets:        # mount secrets into container

    # STORAGE
    volumes:        # mount volumes or bind mounts

    # NETWORKING
    networks:       # which networks to join
    ports:          # expose ports to host

    # DEPENDENCIES
    depends_on:     # start order

    # RESOURCES
    deploy:         # resource limits (memory, CPU)

    # OTHER
    user: "1000:1000"    # run container as specific user:group (security)
    stdin_open: true     # keep stdin open (like docker run -i)
    tty: true            # allocate terminal (like docker run -t)
    logging:
      driver: json-file
      options:
         max-size: "10m"    # max log file size
         max-file: "3"      # keep last 3 log files
    labels:
      com.example.version: "1.0"    # metadata, useful for tooling


## IMAGE/BUILD

# image alone: image: wordpress:latest

# build alone: → Docker auto-names it
With image: → you control the name
Version tag → totally optional, your choice
Any string works as a tag

# example: 
<build: ./requirements/wordpress>
<image: wordpress:1.0>

<image: wordpress:latest>

<image: mariadb:10.11>


## IDENTITY

# container_name: wordpress 
How YOU refer to it from the host (docker logs, docker exec)
if not defined, inception-wordpress-1 

# hostname: hostname inside the network
How OTHER CONTAINERS reach it on the network

# Redundant? Yes, often
In 99% of cases people just let both default to the service name and never touch either. You only need them when:

container_name → you want cleaner CLI commands
hostname → you want containers to connect using a different name


## RUNTIME

# restart: always 
restart policy (<no/always/on-failure/unless-stopped>)

# command: mysqld --innodb-buffer-pool-size=256M
Overrides the CMD instruction in your Dockerfile. Runs after the container starts.

# entrypoint: /bin/bash /tools/setup.sh
Overrides the ENTRYPOINT instruction in your Dockerfile. The main process of the container.

# Difference between command and entrypoint:
- entrypoint = the executable that runs
- command = arguments passed to that executable
<entrypoint: mysqld>          # the program
<command: --verbose>         # the argument → runs: mysqld --verbose

# working_dir: /var/www/html    # sets current directory inside container
Like running cd /var/www/html before anything else executes.


## ENVIRONMENT

# env_file:
  - .env              # loads all variables from file into container
  - .env.local        # can load multiple files, later ones override earlier

# environment:
  <MYSQL_DATABASE: wordpress>    # set directly in compose file
  <MYSQL_USER: htharrau>
  # or
  <MYSQL_DATABASE: ${MYSQL_DATABASE}>  # reference from .env file

# secrets:
  - <db_password>   # mounts secret at /run/secrets/db_password
  - <db_root_password>  # mounts secret at /run/secrets/db_root_password



### NETWORKS 


## NETWORKS DRIVERS

<networks:
  mynetwork:
    driver: bridge      # single host, most common
    driver: overlay     # multi-host, Docker Swarm
    driver: host        # shares host network, no isolation
    driver: macvlan     # container gets its own MAC address
    driver: ipvlan      # container gets its own IP, shares MAC
    driver: none        # no networking>

# bridge:  
Private internal network between containers on the same host.
Default, most common, what we use in inception
It's the default Docker network driver. It creates a private internal network between your containers — like a virtual switch.
Containers on the same bridge network can talk to each other by service name
They are isolated from other networks
Only what you explicitly expose reaches the outside world
        
# host:
Container shares your host machine's network directly — no isolation at all. The container acts as if it's running directly on your machine.
No virtual network, No container isolation -> security risk (therefore forbidden in the subject)
        
# overlay:
Network spanning multiple hostsDocker Swarm, production clusters

# macvlan:
Gives container its own MAC address, appears as physical device on network
Advanced, when container needs to look like a real machine on LAN
        
# ipvlan:
Similar to macvlan but shares MAC address
Advanced networking setups - When switch limits MAC addresses

# none:
No networking at all
Completely isolated containers

For 99% of projects you only ever use:
- bridge → local development, single host (us)
- overlay → production multi-host setups
- host → sometimes for performance (but risky)




# Important: only expose ports that need to be reachable from outside. Internal container-to-container communication needs no port declaration.
ports vs expose:

<ports:
  - "443:443">    # accessible from host AND other containers

<expose:
  - "9000" >      # only accessible from other containers on same network

<expose>: Technically correct but rarely used, because containers on the same network already have access to all ports. <expose> is mostly documentation.

## what happens without any network config
Every container gets put on a default bridge network automatically. But on the default network, containers cannot reach each other by name — only by IP address. Since IPs change, this is unreliable.
That's why we always define a custom network.


## Full network configuration options

networks:
  mynetwork:
    driver: bridge
    
    # Custom IP range
    ipam:
      driver: default
      config:
        - subnet: 172.20.0.0/16     # IP range for this network
          gateway: 172.20.0.1       # gateway IP
          ip_range: 172.20.10.0/24  # range Docker assigns from

    # Driver options
    driver_opts:
      com.docker.network.bridge.name: my_bridge    # custom bridge name
      com.docker.network.driver.mtu: "1500"        # max packet size

    # Makes network available to other compose projects
    external: false     # default, Docker manages it
    
    # Attach to existing network created outside compose
    external: true

    # Custom name (otherwise gets project prefix)
    name: my_custom_network

    # Prevent accidental external access
    internal: true      # containers can't reach internet

    # Enable IPv6
    enable_ipv6: true

    # Labels for metadata
    labels:
      com.example.env: production


## Assigning static IPs to containers
<services:
  mariadb:
    networks:
      inception:
        ipv4_address: 172.20.0.2    # static IP for this container
  wordpress:
    networks:
      inception:
        ipv4_address: 172.20.0.3>

and ip range declaration in networks:
<networks:
  inception:
    ipam:
      config:
        - subnet: 172.20.0.0/16>


# Why would you need static IPs then?
Docker's DNS handles name resolution automatically
Static IPs are only needed when something outside Docker needs to reach a specific container at a known IP, like 
- a firewall rule, 
- a monitoring system, or 
- legacy software that only understands IPs

Inside Docker → always use service names
Outside Docker → sometimes need static IPs


## Multiple networks — isolation example
services:
  nginx:
    networks:
      - frontend        # nginx only on frontend

  wordpress:
    networks:
      - frontend        # wordpress on both
      - backend

  mariadb:
    networks:
      - backend         # mariadb only on backend

networks:
  frontend:
    driver: bridge
  backend:
    driver: bridge
    internal: true      # no internet access for backend

# Result:
- nginx → can reach wordpress ✅
- nginx → cannot reach mariadb ✅ (more secure)
- wordpress → can reach both ✅
- mariadb → cannot reach internet ✅


### SECRETS


environment:
  MYSQL_PASSWORD: supersecret123   # ❌ visible in:

- `docker inspect mycontainer` → shows all env vars
- `docker exec mycontainer env` → lists all env vars
- Your git history if you commit compose file
- Process list on host (`ps aux`)
- Container logs if accidentally printed

## Docker Secrets

A file mounted inside the container at `/run/secrets/` with strict permissions:
- Only root and the container process can read it
- Never shown in `docker inspect`
- Never in environment variables
- Never in logs

/run/secrets/
├── db_password        # contains: mysecretpassword
├── db_root_password   # contains: myroотpassword
└── credentials        # contains: myadminpassword

## TOP LEVEL DECLARATION
secrets:
  db_password:
    file: ../secrets/db_password.txt    # path relative to compose file
  db_root_password:
    file: ../secrets/db_root_password.txt
  credentials:
    file: ../secrets/credentials.txt

## SERVICE LEVEL DECLARATION
services:
  mariadb:
    secrets:
      - db_password         # mounted at /run/secrets/db_password
      - db_root_password    # mounted at /run/secrets/db_root_password

## How to read a secret in a script
# in a shell script inside container
DB_PASSWORD=$(cat /run/secrets/db_password)
//in PHP
#$password = file_get_contents('/run/secrets/db_password');


## CASE _FILE
Some applications (MariaDB, PostgreSQL) support a special convention:
envMYSQL_PASSWORD_FILE=/run/secrets/db_password
The application sees _FILE suffix and automatically reads the password from that path. This is built into the application — not a Docker feature.
Not all apps support this — WordPress doesn't natively, so you need a script to read the secret and pass it to WordPress.



## External secrets (advanced)
Instead of files, secrets can come from secret managers:
yamlsecrets:
  db_password:
    external: true        # secret was created with: docker secret create


Used in production with Docker Swarm or Kubernetes where secrets are managed centrally, not as files.


## Summary

.env file          → configuration, non-sensitive
environment:       → quick overrides, non-sensitive  
secrets:           → passwords, keys, tokens

env var  → stored in process environment, visible to inspection
secret   → stored as file, restricted access, never in inspection

# Important limitation of Compose secrets
Compose secrets are not encrypted. They are simply mounted files.
True encrypted secrets exist only in Docker Swarm.

## Docker secrets vs .env / environment variables

# General setup
- in a directory on the host (e.g. secrets/) - sensitive values as files
<secrets/db_password.txt>
<secrets/api_key.txt>
- In Docker Compose, declare the secret and mount it into the container.
- Inside the container it appears as a read-only file, typically in /run/secrets/.

# How secrets work
- Docker mounts the file into the container filesystem.
- Applications read the file when needed.
- The value is not stored in container configuration.
- The secret is not baked into the image.

It exists only:
- on the host filesystem
- as a mounted file in the running container.

# Problems with environment variables
Environment variables (.env or environment: in Compose):
- Become part of container metadata (on mount)
- Visible with <docker inspect container>
- Visible inside the container: <env>, <printenv>
- Often leak through: logs, debugging output, stack traces, process listings (ps)


# Advantages of Docker secrets
Not exposed in docker inspect
Not visible in env or printenv
Not automatically printed in logs
Read only when explicitly opened
Keeps secrets separate from configuration
Prevents accidental exposure through environment dumps

# What docker inspect shows:
mount source path
mount destination
permissions

# What it does not show:
secret value

# Important limitation
With plain Docker / Compose: Secrets are essentially read-only bind mounts. Someone with host access can still read the file. The security goal is mainly to prevent leaks through:
container metadata
environment variables
logs and debugging tools.

# Good practice
Use:
.env        → configuration
secrets/    → passwords, tokens, keys

Example:
<.env>
APP_PORT=8080
DB_NAME=mydb

<secrets/db_password.txt>
very_strong_password

Application reads:
/run/secrets/db_password



## 🛠️ Dockerfile Optimization (Add to IMAGE/BUILD)

### Layer Caching & Size
Every `RUN`, `COPY`, and `ADD` instruction creates a new layer.
* **The Cache:** Docker remembers layers. If you change line 10, lines 1-9 stay cached, but 10-20 must rebuild.
* **Chain Commands:** Use `&&` to combine commands in a single `RUN` instruction. This prevents temporary files from being saved in an intermediate layer.
* **Cleanup:** Always delete the cache in the same `RUN` command.
    ```dockerfile
    # GOOD PRACTICE
    RUN apt-get update && \
        apt-get install -y mariadb-server && \
        rm -rf /var/lib/apt/lists/*
    ```



---

## ⚡ The PID 1 Problem (Add to RUNTIME)

### The `exec` Form
In Linux, **PID 1** is the "init" process. It is responsible for reaping "zombie" processes and handling signals like `SIGTERM` (the "please stop" signal).
* **The Problem:** If you start your service via a shell script (e.g., `ENTRYPOINT ["/setup.sh"]`), the script is PID 1, and your app (MariaDB) is a child. Shell scripts **do not** pass signals to children.
* **The Consequence:** When you run `docker stop`, MariaDB never hears the signal. Docker waits 10 seconds, then "kills" it forcefully (`SIGKILL`), which can **corrupt your database**.
* **The Solution:** Use `exec` in your shell script. It replaces the shell process with the application process, making the app PID 1.
    ```bash
    # Inside setup.sh
    # ... setup logic ...
    exec mysqld  # Now mysqld becomes PID 1 and shuts down gracefully
    ```

---

## 🌐 Internal DNS (Add to NETWORKS)

### How containers "find" each other
Docker includes a built-in DNS server at the static IP **127.0.0.11**.
1.  **WordPress** wants to connect to `mariadb:3306`.
2.  It asks the Docker DNS: "Where is the service named `mariadb`?"
3.  Docker DNS replies with the internal IP (e.g., `172.20.0.2`).
4.  **No hardcoded IPs needed.** This only works on user-defined bridge networks (not the default "bridge").



---

## 💾 The "Copy-on-Mount" Rule (Add to VOLUMES)

### Named Volumes vs. Bind Mounts
A subtle but critical difference for the Inception project:
* **Named Volumes:** If the volume is **empty** when the container starts, Docker **automatically copies** the files from the image's target folder into the volume. (Great for initializing WordPress files).
* **Bind Mounts:** Docker does **not** copy files. If your host folder is empty, the container folder will appear empty (it "hides" the image data).

---

## 🧹 The "Down" Commands (Add to Lifecycle)

| Command | Effect |
| :--- | :--- |
| `docker compose stop` | Stops containers (data in volumes is safe). |
| `docker compose down` | Stops and **removes** containers and networks. |
| `docker compose down -v` | Stops, removes containers, AND **deletes all volumes**. (Total reset). |



### CMDS


COMPOSE_FILE = srcs/docker-compose.yml

docker compose -f $(COMPOSE_FILE) up -d --build

mkdir -p → creates data directories if they don't exist
-d → detached mode (runs in background)
--build → always rebuilds images

docker-compose    # ❌ old v1, separate binary, deprecated
docker compose    # ✅ v2, built into Docker, what we installed