.PHONY: test lint run-local docker-smoke tf-validate
test:
	cd app && python3 -m unittest -v
lint:
	shellcheck deploy/healthcheck.sh
	python3 -m ruff check app
run-local:
	PORT=8080 python3 app/server.py
docker-smoke:
	docker build -t msd-hello . && docker run -d --rm --name msd-hello -p 8080:8080 msd-hello
	sleep 2; curl -fsS localhost:8080/health; docker stop msd-hello
tf-validate:
	cd terraform && terraform init -backend=false && terraform validate
