.PHONY: init up prod-up prod-down prod-logs down logs ps pull backup

init:
	./scripts/init-env.sh

up: init
	docker compose up --build --wait

prod-up: init
	docker compose -f compose.yaml -f compose.prod.yaml pull
	docker compose -f compose.yaml -f compose.prod.yaml up -d --no-build --wait

prod-down:
	docker compose -f compose.yaml -f compose.prod.yaml down

prod-logs:
	docker compose -f compose.yaml -f compose.prod.yaml logs -f --tail=200

down:
	docker compose down

logs:
	docker compose logs -f --tail=200

ps:
	docker compose ps

pull:
	docker compose pull

backup:
	mkdir -p backups
	docker compose exec -T mongo mongodump --archive --gzip --username "$${MONGO_ROOT_USERNAME:-lab_admin}" --password "$${MONGO_ROOT_PASSWORD}" --authenticationDatabase admin > backups/lab-$$(date +%Y%m%d-%H%M%S).archive.gz
