# **************************************************************************** #
#                                                                              #
#                                                         :::      ::::::::    #
#    Makefile                                           :+:      :+:    :+:    #
#                                                     +:+ +:+         +:+      #
#    By: htharrau <htharrau@student.42.fr>          +#+  +:+       +#+         #
#                                                 +#+#+#+#+#+   +#+            #
#    Created: 2026/03/12 13:04:56 by htharrau          #+#    #+#              #
#    Updated: 2026/03/15 11:34:22 by htharrau         ###   ########.fr        #
#                                                                              #
# **************************************************************************** #

# --- Colors ---
GREEN		= \033[1;32m
RED			= \033[1;31m
YELLOW		= \033[1;33m
CYAN		= \033[1;36m
PINK		= \033[1;35m
RESET		= \033[0m

# --- Variables ---
COMPOSE_FILE = srcs/docker-compose.yml
DATA_DIR = /home/htharrau/data


# --- Rules ---

up:
	mkdir -p $(DATA_DIR)/mariadb
	mkdir -p $(DATA_DIR)/wordpress
	docker compose -f $(COMPOSE_FILE) up -d --build
	@echo "$(PINK)System is up.$(RESET)"

down:
	docker compose -f $(COMPOSE_FILE) down
	@echo "$(CYAN)System is stopped.$(RESET)"


# --remove-orphans removes containers that are no longer defined in the compose file.
clean:
	docker compose -f $(COMPOSE_FILE) down --remove-orphans
	@echo "$(CYAN)Containers and networks removed.$(RESET)"


# removes images (--rmi) and volumes (-v) via Compose
fclean:
	docker compose -f $(COMPOSE_FILE) down -v --rmi all
	@echo "$(YELLOW)Containers, images, and internal volumes removed."

re: fclean up


# Reset also wipes the physical files on the VM, use with caution
reset: fclean
	@sudo rm -rf $(DATA_DIR)
	@echo "$(YELLOW)Physical data folders deleted.$(RESET)"

size:
	docker system df

logs:
	docker compose -f $(COMPOSE_FILE) logs -f

status:
	docker compose -f $(COMPOSE_FILE) ps

.PHONY: all up down clean fclean reset re logs status