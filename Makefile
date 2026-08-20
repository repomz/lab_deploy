.PHONY: up down logs ps pull backup

up:
	docker compose up --build --wait

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
