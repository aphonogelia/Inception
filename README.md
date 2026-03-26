# Inception

> A fully containerized web infrastructure built from scratch with Docker Compose — a 42Berlin system administration project.

- **100% Custom Images** — Built from bare `debian:bookworm`, no pre-made Docker Hub images.
- **Security First** — TLS 1.3 termination, Docker Secrets, and network isolation.
- **Performance** — Redis object caching integrated for WordPress.
- **Automation** — Fully scripted lifecycle with a robust Makefile.

---

## Table of Contents

1. [Overview](#overview)
2. [Architecture](#architecture)
3. [Design Decisions](#design-decisions)
4. [Technical Challenges](#technical-challenges)
5. [Project Structure](#project-structure)
6. [Commands](#commands)

---

## Overview

Inception is a production-grade infrastructure orchestration project. It sets up a secure, multi-service environment including an NGINX reverse proxy, a WordPress site, a MariaDB database, and a Redis cache. Every service is built from scratch via custom Dockerfiles to ensure a minimal attack surface and full control over the environment.

---

## Architecture

```
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

| Service    | Role                                  |
|------------|---------------------------------------|
| NGINX      | TLS reverse proxy, single entry point |
| WordPress  | PHP-FPM application server            |
| MariaDB    | Relational database                   |
| Redis      | Object cache for WordPress            |
| Adminer    | Web-based database UI                 |
| Static     | Lightweight static site               |

---

## Design Decisions

**Reverse Proxy Architecture** — NGINX acts as the sole entry point and handles TLS termination. This encapsulates the internal network, keeping the application tier (WordPress/PHP-FPM) and data tier (MariaDB/Redis) entirely isolated from the public internet.

**Cache Acceleration** — Redis is integrated as a WordPress object cache, reducing database overhead by caching expensive SQL queries and improving page load speeds significantly under load.

**Database Management** — Adminer is used as a lightweight, single-file alternative to phpMyAdmin, providing a web-based database UI without unnecessary bloat.

---

## Technical Challenges

**Custom Image Building** — Every service is built from a bare `debian:bookworm` base, requiring manual installation of PHP-FPM, MariaDB initialization scripts, and PID file management. This reduced final image sizes by ~40% and allowed a granular audit of every installed package.

**Circular Dependency (WordPress/MariaDB)** — WordPress cannot initialize until the database is ready. The WordPress entrypoint script implements health-check polling on the MariaDB port before attempting `wp-core install`, ensuring zero-downtime startup ordering.

**Signal Handling** — NGINX and MariaDB are configured to handle `SIGTERM` gracefully, preventing database corruption and zombie processes on container shutdown.

**TLS Termination** — NGINX is configured to accept only port 443 with strict SSL protocols and cipher suites. Certificates are self-signed for the local domain, meeting the project's security requirements.

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
        └── mariadb/
    └── bonus/
        ├── redis/
        ├── adminer/
        └── static/
```

> Passwords are never stored in image layers or `.env` — they are injected at runtime via Docker Secrets. Containers communicate exclusively over an internal bridge network; only NGINX exposes a port to the host.

---

## Commands

| Command              | Description                                       |
|----------------------|---------------------------------------------------|
| `make` / `make up`   | Build images and start all services               |
| `make logs`          | Follow live logs for all containers               |
| `make status`        | Show currently running containers                 |
| `make down`          | Stop all services (preserves volumes)             |
| `make clean`         | Remove containers and networks                    |
| `make fclean`        | Remove containers, images, and volumes            |
| `make reset`         | Full wipe including data on disk ⚠️               |
| `make re`            | Rebuild everything from scratch (`fclean` + `up`) |
| `make size`          | Show disk size of each container image            |

---

> For setup and installation instructions, see [SETUP.md](SETUP.md).