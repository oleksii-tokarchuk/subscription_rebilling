build:
	docker compose -p subscription_rebilling -f docker-compose.yml build
bash:
	docker compose -p subscription_rebilling -f docker-compose.yml run --rm app bash
start:
	docker compose -p subscription_rebilling -f docker-compose.yml up app -d
stop:
	docker compose -p subscription_rebilling -f docker-compose.yml stop
clean:
	docker compose -p subscription_rebilling -f docker-compose.yml down -v
