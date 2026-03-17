This project has been created as part of the 42 curriculum by Helene Tharrault (htharrau).

### Description

Inception is a system administration project from the 42 curriculum focusing on *Docker Compose* orchestration. The goal is to set up a *multi-container infrastructure on a Debian Virtual Machine*, adhering to strict security and networking rules.


### Services

| Service | Description |
|---|---|
| **MariaDB** | Database server for WordPress |
| **WordPress** | CMS with PHP-FPM, no nginx |
| **Nginx** | Reverse proxy, sole entry point via port 443 (TLS only) |
| **Redis** *(bonus)* |	High-performance Object Cache used to reduce database load.|
| **Adminer** *(bonus)* | Web-based database management UI |
| **Static site** *(bonus)* | A custom static HTML page served via nginx |


_____________________________________________________________________________
|                                                                           |
|                          INCEPTION NETWORK (Bridge)                       |
|___________________________________________________________________________|
       |                                                              
       |      [Port 443]                                              
       ▼           |                                                  
+--------------+   |   Requests for:                                  
|    NGINX     | <---+   - htharrau.42.fr  --> [WordPress:9000]       
| (Entry Point)|         - adminer         --> [Adminer:8081]         
+--------------+         - aquamemoria     --> [Static:8080]          
       |                                                              
       | (FastCGI)                                                    
       ▼                                                              
+--------------+           (Object Cache)           +--------------+  
|  WORDPRESS   | <--------------------------------> |    REDIS     |  
|  (PHP-FPM)   |             [Port 6379]            |   (Bonus)    |  
+--------------+                                    +--------------+  
       |                                                              
       | (SQL Query)                                                  
       ▼                                                              
+--------------+                                    +--------------+  
|   MARIADB    | <--------------------------------- |   ADMINER    |  
|  (Database)  |             [Port 3306]            |   (Bonus)    |  
+--------------+                                    +--------------+  
       |                                                              
       | (Bind Mount)                                                 
       ▼                                                              
+---------------------------------------+                             
|        VM PERSISTENT STORAGE          |                             
|  /home/htharrau/data/mariadb          |                             
|  /home/htharrau/data/wordpress        |                             
+---------------------------------------+


### Requirements

- Docker and Docker Compose installed
- Linux (the project was developed and tested on a Debian VM)
- The following entries in `/etc/hosts`:
```
  127.0.0.1  htharrau.42.fr
  127.0.0.1  adminer
  127.0.0.1  aquamemoria
```

### Instructions

1. Clone the repository:
```bash
   git clone git@vogsphere.42berlin.de:vogsphere/intra-uuid-... inception
   cd inception
```

2. Create the secrets files:
```bash
   mkdir secrets
   echo "yourpassword" > secrets/mysql_password.txt
   echo "yourrootpassword" > secrets/mysql_root_password.txt
   echo "yoursuperpassword" > secrets/super_password.txt
   echo "youruserpassword" > secrets/user_password.txt
```

3. Create a `.env` file in `srcs/`, taking example of the .env.example file. 
```env
   DOMAIN_NAME=htharrau.42.fr
   STATIC_NAME=aquamemoria
   ADMINER_NAME=adminer
   MYSQL_DATABASE=
   MYSQL_USER=
   WP_ADMIN_USER=
   WP_ADMIN_EMAIL=
   WP_USER=
   WP_EMAIL=
```

4. Build and start all services:
```bash
   make or make up
```

### Useful Commands
```bash
make logs     # Follow logs for all services
make status   # Show running containers
make down     # Stop all services
make clean    # Remove containers and networks
make fclean   # Remove containers, images, and volumes
make reset    # Full wipe including data on disk (caution)
make re       # Rebuild everything from scratch (fclean + up)
make size     # Show the size of each container
```


### Access

| Service | URL |
|---|---|
| WordPress | https://htharrau.42.fr |
| Adminer | https://adminer |
| Static site | https://aquamemoria |



#### External References & Documentation
Docker Official Docs: Dockerfile reference  https://docs.docker.com/reference/dockerfile — Used for defining service orchestration and volume management.

WordPress CLI: WP-CLI Command Index https://developer.wordpress.org/cli/commands/ — Primary tool used in the wordpress_entrypoint.sh for non-interactive installation and Redis configuration.

Nginx Documentation: Module ngx_http_fastcgi_module https://nginx.org/en/docs/http/ngx_http_fastcgi_module.html — Essential for configuring the bridge between Nginx and the PHP-FPM container.

MariaDB Knowledge Base: Environment Variables https://mariadb.com/docs?q=mariadb-docker-environment-variables — Used to configure the initial database, users, and root privileges.

Redis Object Cache: Plugin Documentation https://github.com/rhubarbgroup/redis-cache — Used to implement the "Graceful Fail" logic and connection timeouts for high availability.

Youtube videos explaining Docker and Redis were also used for the understanding of the project.