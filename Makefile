.PHONY: help up down restart build shell logs status clean install dev

# Variables
COMPOSE := docker compose
SERVICE := devkit
CONTAINER := $(shell $(COMPOSE) ps -q $(SERVICE) 2>/dev/null)

# Couleurs pour l'affichage
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Affiche cette aide
	@echo "$(GREEN)Commandes disponibles:$(NC)"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(YELLOW)%-15s$(NC) %s\n", $$1, $$2}'

check-docker: ## Vérifie que Docker est installé
	@which docker > /dev/null || (echo "$(RED)Docker n'est pas installé$(NC)" && exit 1)
	@docker info > /dev/null 2>&1 || (echo "$(RED)Docker daemon n'est pas démarré$(NC)" && exit 1)

check-running: check-docker ## Vérifie que le container tourne
	@if [ -z "$(CONTAINER)" ]; then \
		echo "$(RED)Le container $(SERVICE) n'est pas lancé$(NC)"; \
		echo "$(YELLOW)Lancez 'make up' pour démarrer les containers$(NC)"; \
		exit 1; \
	fi

up: check-docker ## Lance les containers en arrière-plan
	@echo "$(GREEN)Démarrage des containers...$(NC)"
	$(COMPOSE) up -d --build

down: check-docker ## Arrête les containers
	@echo "$(YELLOW)Arrêt des containers...$(NC)"
	$(COMPOSE) down

restart: check-docker ## Redémarre les containers
	@echo "$(YELLOW)Redémarrage des containers...$(NC)"
	$(COMPOSE) restart

build: check-docker ## Rebuild l'image Docker
	@echo "$(GREEN)Build de l'image...$(NC)"
	$(COMPOSE) build --no-cache

bash: check-running ## Ouvre un shell bash dans le container
	@echo "$(GREEN)Connexion au container $(SERVICE)...$(NC)"
	$(COMPOSE) exec $(SERVICE) bash

logs: check-docker ## Affiche les logs du container
	$(COMPOSE) logs -f $(SERVICE)

status: check-docker ## Affiche le statut des containers
	@echo "$(GREEN)Statut des containers:$(NC)"
	@$(COMPOSE) ps

install: check-running ## Installe les dépendances (pnpm install)
	@echo "$(GREEN)Installation des dépendances...$(NC)"
	$(COMPOSE) exec $(SERVICE) pnpm install

dev: check-running ## Lance le mode développement (Tauri + Svelte + FrankenPHP)
	@echo "$(GREEN)Lancement du mode dev...$(NC)"
	$(COMPOSE) exec $(SERVICE) pnpm dev

clean: check-docker ## Nettoie les containers, volumes et images
	@echo "$(RED)Nettoyage complet...$(NC)"
	$(COMPOSE) down -v --rmi local
	@echo "$(GREEN)Nettoyage terminé$(NC)"

prune: check-docker ## Nettoie les ressources Docker inutilisées (prudence!)
	@echo "$(YELLOW)Nettoyage des ressources Docker inutilisées...$(NC)"
	docker system prune -af --volumes

database-init: check-running ## Crée la base de données (Doctrine)
	@echo "$(GREEN)Création de la base de données...$(NC)"
	$(COMPOSE) exec -it $(SERVICE) php backend/bin/console doctrine:schema:create
