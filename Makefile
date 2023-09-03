run-docker:
	docker-compose up --build -d
	docker logs --follow pypi-mirror-backend

stop-docker:
	docker-compose down
