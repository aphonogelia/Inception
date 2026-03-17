# Inception

> A fully containerized web infrastructure built from scratch with Docker Compose — a 42Berlin system administration project.

Inception sets up a small but complete production-like environment: an NGINX reverse proxy handling TLS termination, a WordPress site backed by MariaDB and accelerated by a Redis object cache, plus Adminer for database management and a static bonus site. Every service runs in its own custom-built Docker container; no pre-made application images.

---

## Architecture

```
                        INCEPTION NETWORK (Bridge)
                                    |
                             [Port 443 / TLS]
                                    |
                          +-------------------+
                          |       NGINX        |
                          |   (Entry Point)    |
                          +-------------------+
                           /         |         \
               htharrau.42.fr     adminer    aquamemoria
                      |               |            |
              [WordPress:9000]  [Adminer:8081]  [Static:8080]
                      |
          +-----------+-----------+
          |                       |
    [MariaDB:3306]          [Redis:6379]
          |
  /home/htharrau/data/
  (Persistent Storage)
```

| Service    | Role                                      |
|------------|-------------------------------------------|
| NGINX      | TLS reverse proxy, single entry point     |
| WordPress  | PHP-FPM application server                |
| MariaDB    | Relational database                       |
| Redis      | Object cache for WordPress (bonus)        |
| Adminer    | Web-based database UI (bonus)             |
| Static     | Lightweight static site (bonus)           |

---

## Requirements

- **Docker** and **Docker Compose**
- **Linux** (developed and tested on Debian — other distros should work)
- The following entries added to `/etc/hosts`:

```
127.0.0.1  htharrau.42.fr
127.0.0.1  adminer
127.0.0.1  aquamemoria
```

> **Note on TLS:** All services are served over HTTPS using a self-signed certificate. Your browser will show a security warning on first visit — this is expected. You can safely proceed past it.

---

## Setup

### 1. Clone the repository

```bash
git clone git@vogsphere.42berlin.de:vogsphere/intra-uuid-... inception
cd inception
```

### 2. Create the secrets

Each secret is stored as a plain-text file and mounted into the relevant container at runtime. Docker Compose reads them via the `secrets:` key — they are never baked into images or exposed as environment variables.

```bash
mkdir secrets
echo "yourpassword"     > secrets/mysql_password.txt       # MariaDB app user password
echo "yourrootpassword" > secrets/mysql_root_password.txt  # MariaDB root password
echo "yoursuperpassword" > secrets/super_password.txt      # WordPress admin password
echo "youruserpassword"  > secrets/user_password.txt       # WordPress regular user password
```

### 3. Create the environment file

Copy the example and fill in the blanks:

```bash
cp srcs/.env.example srcs/.env
```

```env
DOMAIN_NAME=htharrau.42.fr
STATIC_NAME=aquamemoria
ADMINER_NAME=adminer
MYSQL_DATABASE=            # e.g. wordpress
MYSQL_USER=                # e.g. wpuser
WP_ADMIN_USER=             # WordPress admin username
WP_ADMIN_EMAIL=            # WordPress admin email
WP_USER=                   # WordPress subscriber username
WP_EMAIL=                  # WordPress subscriber email
```

### 4. Configure volumes

The compose file uses bind mounts pointing to `/home/htharrau/data/`. You have two options:

**Option A — Use the default bind mounts**

Make sure the target directories exist on your machine:

```bash
mkdir -p /home/htharrau/data/wordpress /home/htharrau/data/mariadb
```

**Option B — Switch to Docker-managed named volumes (recommended for portability)**

Replace the `volumes:` block at the bottom of `docker-compose.yml` with:

```yaml
volumes:
  wordpress_data:
    driver: local
  mariadb_data:
    driver: local
```

> Named volumes let Docker handle UID/GID ownership automatically, which avoids common permission errors that can occur with bind mounts on different machines.

### 5. Build and start

```bash
make
```

---

## Access

| Service       | URL                     |
|---------------|-------------------------|
| WordPress     | https://htharrau.42.fr  |
| Adminer       | https://adminer         |
| Static site   | https://aquamemoria     |

---

## Useful Commands

| Command        | Description                                         |
|----------------|-----------------------------------------------------|
| `make` / `make up` | Build images and start all services            |
| `make logs`    | Follow live logs for all containers                 |
| `make status`  | Show currently running containers                   |
| `make down`    | Stop all services (preserves volumes)               |
| `make clean`   | Remove containers and networks                      |
| `make fclean`  | Remove containers, images, and volumes              |
| `make reset`   | Full wipe including data on disk ⚠️ destructive     |
| `make re`      | Rebuild everything from scratch (`fclean` + `up`)   |
| `make size`    | Show the disk size of each container image          |

---

## Project Structure

```
inception/
├── Makefile
├── secrets/                  # Secret files (git-ignored)
└── srcs/
    ├── .env                  # Environment variables (git-ignored)
    ├── .env.example
    ├── docker-compose.yml
    └── requirements/
        ├── nginx/
        ├── wordpress/
        ├── mariadb/
    └── bonus/
        ├── redis/
        ├── adminer/
        └── static/
```

---

## Notes

- All Docker images are built from `debian:bullseye` or `alpine` — no pre-made application images (no `wordpress`, `mysql`, or `php` from Docker Hub).
- Containers communicate exclusively over an internal Docker bridge network; only NGINX exposes a port to the host.
- Passwords are never stored in the image layer or in `.env` — they are passed at runtime via Docker secrets.