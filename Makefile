.DEFAULT_GOAL := build
DOCKER_COMPOSE = docker compose -p subscription_rebilling -f docker-compose.yml

build:
	$(DOCKER_COMPOSE) build app
bash:
	$(DOCKER_COMPOSE) run --rm app bash
start:
	$(DOCKER_COMPOSE) up app -d
stop:
	$(DOCKER_COMPOSE) stop
restart: stop start
clean:
	$(DOCKER_COMPOSE) down -v
