RUN=poetry run

# TODO reinstate shared storage for basex and postgres

# Default target
.PHONY: all 
all:
	@echo No all target is provided at this point.
	@echo If none of the containers are running yet and the downlaods and chunks files have not been created yet,
	@echo Then a typical flwo would been
	@echo make pre-basex-all basex-all postgres-all

aggressive-clean:
	docker rm -f biosample-basex || true
	docker rm -f biosample-postgres || true
	docker system prune --force
# 	sudo rm -rf shared-postgres/*
	rm -rf downloads/*
	rm -rf shared-chunks/*
	

.PHONY: setup-shared-dirs
setup-shared-dirs:
	mkdir -p shared-chunks shared-queries shared-results downloads
	touch shared-chunks/.gitkeep shared-queries/.gitkeep shared-results/.gitkeep downloads/.gitkeep  

downloads/biosample_set.xml.gz:
	mkdir -p  downloads
	curl -o $@ https://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz

downloads/biosample_set.xml: downloads/biosample_set.xml.gz
	date
	time gunzip -c $< > $@ # expect ~ 90 GB in XXX minutes


## https://github.com/Quodatum/basex-docker#readme

## this mapping isn't working in Ubuntu
# 		-v `pwd`/shared-basex-data:/srv/basex/data \
# and the user launching the makefile can't delete the pg data directory

.PHONY: basex-up
basex-up:
	docker run \
		--name biosample-basex \
		-p 8080:8080 \
		-v $(shell pwd)/shared-queries:/srv/basex/shared-queries \
		-v $(shell pwd)/shared-results:/srv/basex/shared-results \
		-v $(shell pwd)/shared-chunks:/srv/basex/shared-chunks \
		-d quodatum/basexhttp
	# skipping #chown -R 1000:1000 shared-basex-data
	sleep 5
	docker exec -it biosample-basex basex -c "PASSWORD basex-password"
	sleep 5
	docker container restart biosample-basex
	sleep 5
	curl -u admin:basex-password http://localhost:8080/rest

## basic access:
# docker exec -it biosample-basex /bin/bash 
## or
# visit localhost:8080


.PHONY: postgres-up
postgres-up:
	docker run \
		--name biosample-postgres \
		-p 5433:5432 \
		-e POSTGRES_PASSWORD=postgres-password \
		-d postgres
	sleep 10

# could check with
# docker exec -it biosample-postgres /bin/bash

.PHONY: postgres-create
postgres-create:
	docker exec -it biosample-postgres psql -U postgres -c "CREATE DATABASE biosample;"
	docker exec -it biosample-postgres psql -U postgres -c "CREATE USER biosample WITH PASSWORD 'biosample-password';"
	docker exec -it biosample-postgres psql -U postgres -c "ALTER ROLE biosample SET client_encoding TO 'utf8';"
	docker exec -it biosample-postgres psql -U postgres -c "ALTER ROLE biosample SET default_transaction_isolation TO 'read committed';"
	docker exec -it biosample-postgres psql -U postgres -c "ALTER ROLE biosample SET timezone TO 'UTC';"
	docker exec -it biosample-postgres psql -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE biosample TO biosample;"
	docker exec -it biosample-postgres psql -U postgres -d biosample -c "GRANT CREATE ON SCHEMA public TO biosample;"
	PGPASSWORD=biosample-password psql -h localhost -p 5433 -U biosample -d biosample -f sql/all-ncbi-attributes-long.sql
	PGPASSWORD=biosample-password psql -h localhost -p 5433 -U biosample -d biosample -f sql/non-attribute-metadata.sql
	sleep 10

.PHONY: biosample-set-xml-chunks
# 1000000 biosamples-per-file -> 35x ~ 3 GB output files/databases ~ 30 seconds per chunk # loading: ~ 8 min per chunk # todo larger chunks crash load with "couldn't write tmp file..."
biosample-set-xml-chunks: downloads/biosample_set.xml
	mkdir -p shared-chunks
	$(RUN) python biosample_xmldb_sqldb/split_into_N_biosamples.py \
		--input-file-name $< \
		--output-dir shared-chunks \
		--biosamples-per-file 1000  \
		--last-biosample 9000

BIOSAMPLE-SET-XML-CHUNK-FILES=$(shell ls shared-chunks)

BIOSAMPLE-SET-XML-CHUNK-NAMES=$(notdir $(basename $(BIOSAMPLE-SET-XML-CHUNK-FILES)))

biosample_set_from_%:
	echo $@
	date
	time docker exec -it biosample-basex basex -c "CREATE DB $@ basex/shared-chunks/$@.xml"

load-biosample-sets: $(BIOSAMPLE-SET-XML-CHUNK-NAMES) # 5 hours? could possibly do in parallel on a big machine

# docker exec -it biosample-basex  basex -c list
# docker exec -it biosample-basex  basex -c "open biosample_set_from_0; info db"
# docker exec -it biosample-basex  basex -c "open biosample_set_from_0; info index"

PHONY: all-ncbi-attributes-long-file # make sure computer doesn't go to sleep # 70 minutes
all-ncbi-attributes-long-file:
	date
	time docker exec -it biosample-basex basex basex/shared-queries/$@.xq > shared-results/$@.tsv

PHONY: non-attribute-metadata-file
non-attribute-metadata-file:
	date
	docker exec -it biosample-basex basex basex/shared-queries/$@.xq > shared-results/$@.tsv


## psql access from the host: PGPASSWORD=biosample-password psql -h localhost -p 5433 -U biosample -d biosample

## dealing with incomplete data files ?
# sed -n -e :a -e '1,2!{P;N;D;};N;ba' shared-queries/non-attribute-metadata-file.tsv > shared-queries/non-attribute-metadata-file-minus_two_lines.tsv # basex ouput my have a few garbage lines if the queries are executed before all of the chunks are loaded into databases
# or 
# psql -h localhost -p 5433 -U your_username -d your_database -c "\COPY your_table FROM 'your_csv_file.csv' WITH (FORMAT CSV, NULL 'NULL', HEADER);"


## dump structure
# docker exec -it biosample-postgres pg_dump -U postgres -d biosample --table=non_attribute_metadata --schema-only > non_attribute_metadata_structure.sql


.PHONY: all-ncbi-attributes-long-postgres
all-ncbi-attributes-long-postgres:
	PGPASSWORD=biosample-password \
		psql \
		-h localhost \
		-p 5433 \
		-U biosample \
		-d biosample \
		-c "\COPY all_ncbi_attributes_long FROM 'shared-results/all-ncbi-attributes-long-file.tsv' WITH DELIMITER E'\t' CSV HEADER;"

.PHONY: non-attribute-metadata-postgres
non-attribute-metadata-postgres:
	PGPASSWORD=biosample-password \
		psql \
		-h localhost \
		-p 5433 \
		-U biosample \
		-d biosample \
		-c "\COPY non_attribute_metadata FROM 'shared-results/non-attribute-metadata-file.tsv' WITH DELIMITER E'\t' CSV HEADER;"

# optionally make aggressive-clean # this deletes downloads, basex data, extracted chunks, and postgres data
.PHONY: pre-basex-all
pre-basex-all: setup-shared-dirs downloads/biosample_set.xml biosample-set-xml-chunks

# make pre-basex-all
.PHONY: basex-all
basex-all: basex-up load-biosample-sets all-ncbi-attributes-long-file non-attribute-metadata-file


# make basex-all
.PHONY: postgres-all
postgres-all: postgres-up postgres-create all-ncbi-attributes-long-postgres non-attribute-metadata-postgres 
	poetry run python biosample_xmldb_sqldb/pivot_harmonized_attributes.py

