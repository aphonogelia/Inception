# Inception — Setup Guide

A Docker-based infrastructure deploying WordPress, MariaDB, Adminer, and a static site — all served over TLS using custom containers.

---

## Prerequisites

- **OS**: Linux (Debian or Ubuntu recommended)
- **Docker Engine**: v20.10.0+
- **Docker Compose**: V2 (Compose plugin)

Add the project domains to your `/etc/hosts`:

```
127.0.0.1   htharrau.42.fr
127.0.0.1   adminer
127.0.0.1   aquamemoria
```

---

## Installation

### 1. Clone the repository

```bash
git clone git@vogsphere.42berlin.de:vogsphere/intra-uuid-... inception
cd inception
```

### 2. Create secrets

Inception uses Docker Secrets instead of environment variables to keep credentials out of image layers and `docker inspect` output. Each secret is a plain-text file:

```bash
mkdir secrets

echo "yourpassword"      > secrets/mysql_password.txt       # MariaDB app user
echo "yourrootpassword"  > secrets/mysql_root_password.txt  # MariaDB root
echo "youradminpassword" > secrets/super_password.txt       # WordPress admin
echo "youruserpassword"  > secrets/user_password.txt        # WordPress subscriber
```

> **Important:** Add `secrets/` to your `.gitignore` to avoid leaking credentials.

### 3. Configure environment variables

```bash
cp srcs/.env.example srcs/.env
```

Edit `srcs/.env` with your values:

```env
DOMAIN_NAME=htharrau.42.fr
STATIC_NAME=aquamemoria
ADMINER_NAME=adminer
MYSQL_DATABASE=           # e.g. wordpress
MYSQL_USER=               # e.g. wpuser
WP_ADMIN_USER=            # WordPress admin username
WP_ADMIN_EMAIL=           # WordPress admin email
WP_USER=                  # WordPress subscriber username
WP_EMAIL=                 # WordPress subscriber email
```

### 4. Set up persistent volumes

The compose file uses bind mounts pointing to `/home/htharrau/data/`. Choose one option:

**Option A — Default bind mounts**

```bash
sudo mkdir -p /home/htharrau/data/wordpress /home/htharrau/data/mariadb
sudo chown -R $USER:$USER /home/htharrau/data
```

**Option B — Docker-managed named volumes** *(recommended for portability)*

Replace the `volumes:` block at the bottom of `docker-compose.yml` with:

```yaml
volumes:
  wordpress_data:
    driver: local
  mariadb_data:
    driver: local
```

Named volumes let Docker handle ownership automatically, avoiding common permission errors on different machines.

### 5. Build and start

```bash
make
```

---

## Access

| Service     | URL                    |
|-------------|------------------------|
| WordPress   | https://htharrau.42.fr |
| Adminer     | https://adminer        |
| Static site | https://aquamemoria    |

> Certificates are self-signed (TLS 1.2/1.3). On first visit, click **Advanced → Proceed** to bypass the browser warning — this is expected for local development.

---

## Commands

| Command         | Description                                      |
|-----------------|--------------------------------------------------|
| `make` / `make up` | Build images and start all services           |
| `make logs`     | Follow live logs for all containers              |
| `make status`   | Show currently running containers                |
| `make down`     | Stop all services (preserves volumes)            |
| `make clean`    | Remove containers and networks                   |
| `make fclean`   | Remove containers, images, and volumes           |
| `make reset`    | Full wipe including data on disk ⚠️              |
| `make re`       | Rebuild everything from scratch (`fclean` + `up`) |
| `make size`     | Show disk size of each container image           |

---

## Troubleshooting

**Permission denied on volumes**
Run the `chown` command from Step 4 on your host data directory.

**Database connection error**
MariaDB may still be initializing. Run `make logs` and wait for it to finish before WordPress retries.

**Port 443 conflict**
Ensure no local NGINX or Apache instance is already bound to port 443.