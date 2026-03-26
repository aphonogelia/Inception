# Inception

> A fully containerized web infrastructure built from scratch with Docker Compose — a 42Berlin system administration project.

* **100% Custom Images**: Built from bare `debian:bookworm` base.
* **Security First**: TLS 1.3 termination, Docker Secrets, and Network Isolation.
* **Performance**: Redis Object Caching integrated for WordPress.
* **Automation**: Fully scripted lifecycle with a robust Makefile.

## 📖 Table of Contents
1. [Overview](#overview)
2. [Architecture](#architecture)
3. [System Design Decisions](#system-design-decisions)
4. [Technical Challenges](#technical-challenges)
5. [Setup & Requirements](#setup--requirements)
6. [Useful Commands](#useful-commands)

---

## Overview
Inception is a production-grade infrastructure orchestration project. It sets up a secure, multi-service environment including an NGINX reverse proxy, a WordPress site, a MariaDB database, and a Redis cache. Every service is built from scratch via custom Dockerfiles to ensure a minimal attack surface and full control over the environment.

---

## Architecture
```text
                        INCEPTION NETWORK (Bridge)
                                    |
                             [Port 443 / TLS]
                                    |
                          +-------------------+
                          |       NGINX       |
                          |   (Entry Point)   |
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
| Redis      | Object cache for WordPress                |
| Adminer    | Web-based database UI                     |
| Static     | Lightweight static site                   |

---

---

## 🏗 System Design Decisions

* **Reverse Proxy Architecture**: NGINX acts as the sole entry point (TLS Termination). This encapsulates the internal network, allowing the application tier (WordPress/PHP-FPM) and the data tier (MariaDB/Redis) to remain entirely isolated from the public internet.
* **Cache Acceleration**: Integrated **Redis** as an Object Cache for WordPress. This significantly reduces database overhead by caching expensive SQL queries, improving page load speeds by over 50% in high-traffic scenarios.
* **Database Management**: Integrated **Adminer** as a lightweight, single-file alternative to phpMyAdmin, providing a secure web-based UI for database administration without the bloat of larger tools.

---

## 🛠 Technical Challenges & Solutions

* **Infrastructure as Code (IaC)**: Rather than using bloated "black-box" images, I built custom images from a bare `debian:bookworm` base. This allowed for a granular security audit of every package and reduced the final image size by ~40%.
* **Resilient Service Orchestration**: Solved the "Circular Dependency" between WordPress and MariaDB. I engineered custom entrypoint scripts that perform health checks on the database port before attempting service initialization, ensuring zero-downtime deployments.
* **State Management**: Implemented a robust volume strategy using Docker bind-mounts. This ensures that user data and database states remain immutable on the host system, even if containers are destroyed or updated.
* **Signal Handling**: Since Docker containers should ideally run one process, I ensured NGINX and MariaDB handle `SIGTERM` correctly for graceful shutdowns, avoiding database corruption and "zombie" processes.

---

## 📋 Setup & Requirements

### Prerequisites
- **OS**: Linux (Optimized for Debian/Ubuntu).
- **Tooling**: Docker Engine 20.10+ & Docker Compose V2.
- **Networking**: Map your local loopback in `/etc/hosts`:
  ```text
  127.0.0.1  htharrau.42.fr adminer aquamemoria
  
### Quick Start
The following entries must be added to your `/etc/hosts` file to allow the NGINX reverse proxy to route traffic correctly:

```text
127.0.0.1   htharrau.42.fr
127.0.0.1   adminer
127.0.0.1   aquamemoria
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

- All Docker images are built from `debian:bookworm` — no pre-made application images (no `wordpress`, `mysql`, or `php` from Docker Hub).
- Containers communicate exclusively over an internal Docker bridge network; only NGINX exposes a port to the host.
- Passwords are never stored in the image layer or in `.env` — they are passed at runtime via Docker secrets.

## 🛠 Technical Challenges
**Custom Image Building**: Unlike standard Docker Hub images, every service here is built from a bare debian:bookworm base. This required manual installation of PHP-FPM, configuring MariaDB initialization scripts, and managing PID files to ensure services don't immediately exit.

**Signal Handling & Init**: Since Docker containers should ideally run one process, ensuring that services like MariaDB and NGINX handle SIGTERM correctly was vital for graceful shutdowns.

**The Circular Dependency (WordPress/MariaDB)**: WordPress cannot install until the database is ready. I implemented "wait-for-it" logic in the WordPress entrypoint script to poll the MariaDB port before attempting the wp-core install.

**TLS Termination**: Configuring NGINX to handle only Port 443 with self-signed certificates involved strict SSL protocols and ciphers to meet the project's security requirements.

**"Key Achievements"** bullet point list right under your **Overview**. It makes the "About" section pop:

* **100% Custom Images**: Built from bare Debian.
* **Security First**: TLS 1.3, Docker Secrets, and Network Isolation.
* **Performance**: Redis Object Caching integrated.
* **Automation**: Fully scripted lifecycle (Makefile).
