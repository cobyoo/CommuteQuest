.PHONY: up down logs restart db-shell api-shell test

up:
	docker compose up --build -d

down:
	docker compose down

logs:
	docker compose logs -f

restart:
	docker compose restart api

db-shell:
	docker compose exec db psql -U postgres -d commutequest

api-shell:
	docker compose exec api bash

test:
	docker compose exec api pytest tests/ -v

clean:
	docker compose down -v
