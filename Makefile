RUN=poetry run
ADMIN_PASSWORD=postgres-password
ADMIN_USER=postgres
BIOSAMPLE_XML_URL=https://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz
CONTAINER_NAME=biosample-postgres
CONTAINER_PORT=5432
DATABASE=biosample_dev
HOST=localhost
HOST_PORT=5433
IMAGE_NAME=postgres
PASSWORD=biosample-password
SCHEMA=public
USER=biosample

# Default target
.PHONY: all 
all:
	@echo No all target is provided at this point.

aggressive-clean:
	docker rm -f $(CONTAINER_NAME) || true
	docker system prune --force
	rm -rf downloads/*

downloads/biosample_set.xml.gz:
	mkdir -p downloads
	curl -o $@ $(BIOSAMPLE_XML_URL)

downloads/biosample_set.xml: downloads/biosample_set.xml.gz
	date
	time gunzip -c $< > $@ # expect ~ 105 GB in 6 minutes

.PHONY: postgres-up
postgres-up:
	docker run \
		--name $(CONTAINER_NAME) \
		-p $(HOST_PORT):$(CONTAINER_PORT) \
		-e POSTGRES_PASSWORD=$(ADMIN_PASSWORD) \
		-d $(IMAGE_NAME)
	sleep 10

# could check with
# docker exec -it $(CONTAINER_NAME) /bin/bash

# DO $$ BEGIN
  #    IF NOT EXISTS (SELECT FROM pg_database WHERE datname = 'biosample-dev') THEN
  #        CREATE DATABASE biosample-dev;
  #    END IF;
  #END $$;

.PHONY: postgres-create
postgres-create:
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -c "CREATE DATABASE $(DATABASE);"
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -c "CREATE USER $(USER) WITH PASSWORD '$(PASSWORD)';"
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -c "ALTER ROLE $(USER) SET client_encoding TO 'utf8';"
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -c "ALTER ROLE $(USER) SET default_transaction_isolation TO 'read committed';"
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -c "ALTER ROLE $(USER) SET timezone TO 'UTC';"
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -c "GRANT ALL PRIVILEGES ON DATABASE $(DATABASE) TO $(USER);"
	docker exec -it $(CONTAINER_NAME) psql -U $(ADMIN_USER) -d $(DATABASE) -c "GRANT CREATE ON SCHEMA $(SCHEMA) TO $(USER);"
	PGPASSWORD=$(PASSWORD) psql -h $(HOST) -p $(HOST_PORT) -U $(USER) -d $(DATABASE) -f sql/setup.sql
	sleep 10
