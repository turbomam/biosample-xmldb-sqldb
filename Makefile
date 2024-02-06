RUN=poetry run

DOWNLOADS_FOLDER := downloads
CHUNKS_FOLDER := data/biosample-set-xml-chunks # todo git-ignore data/
XML_FILE := $(DOWNLOADS_FOLDER)/biosample_set.xml.gz
UNPACKED_FILE := $(DOWNLOADS_FOLDER)/biosample_set.xml

# Default target
.PHONY: all
all: $(UNPACKED_FILE) biosample-set-xml-chunks create-biosample-set-logs

# Target to download the file
$(XML_FILE):
	mkdir -p $(DOWNLOADS_FOLDER)
	curl -o $(XML_FILE) https://ftp.ncbi.nlm.nih.gov/biosample/biosample_set.xml.gz

# Target to unpack the file
$(UNPACKED_FILE): $(XML_FILE)
	gunzip -c $(XML_FILE) > $(UNPACKED_FILE)

# Clean target to remove downloaded files
clean:
	rm -rf $(DOWNLOADS_FOLDER)
	rm -rf $(CHUNKS_FOLDER)/*

# Declare targets as not phony
.SECONDARY: $(XML_FILE) $(UNPACKED_FILE)


## https://github.com/Quodatum/basex-docker#readme

.PHONY: setup-shared-dirs
setup-shared-dirs:
	mkdir -p shared-chunks shared-queries shared-results shared-basex-data shared-postgres

.PHONY: basex-up
basex-up:
	docker run \
		--name basex10 \
		-p 8080:8080 \
		-v `pwd`/shared-basex-data:/srv/basex/data \
		-v `pwd`/shared-queries:/srv/basex/shared-queries \
		-v `pwd`/shared-results:/srv/basex/shared-results \
		-v `pwd`/shared-chunks:/srv/basex/shared-chunks \
		-d quodatum/basexhttp
	# skipping #chown -R 1000:1000 shared-basex-data
	sleep 5
	docker exec -it basex10 basex -c "PASSWORD basex-password"
	sleep 5
	docker container restart basex10
	sleep 5
	curl -u admin:basex-password http://localhost:8080/rest

## basic access:
# docker exec -it basex10 /bin/bash 
## or
# visit localhost:8080


.PHONY: postgres-up
postgres-up:
	rm -rf shared-postgres/*
	mkdir -p shared-postgres/pg_data
	docker rm -f biosample-postgres || true
	docker run \
		--name biosample-postgres \
		-p 5433:5432 \
		-v $(shell pwd)/shared-results:/root/shared-results \
		-v $(shell pwd)/shared-postgres/pg_data:/var/lib/postgresql/data \
		-e POSTGRES_PASSWORD=postgres-password \
		-d postgres
	sleep 30

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
	PGPASSWORD=biosample-password psql -h localhost -p 5433 -U biosample -d biosample -f sql/non_attribute_metadata.sql
	PGPASSWORD=biosample-password psql -h localhost -p 5433 -U biosample -d biosample -f sql/all_attribs.sql
	sleep 30

.PHONY: biosample-set-xml-chunks
biosample-set-xml-chunks: $(UNPACKED_FILE)
	mkdir -p $(CHUNKS_FOLDER)
	$(RUN) python biosample_xmldb_sqldb/split_into_N_biosamples.py \
		--input-file-name $< \
		--output-dir shared-chunks \
		--biosamples-per-file 1000000 # 35x ~ 3 GB output files/databases? ~ 30 seconds per chunk # load: ~ 8 min per chunk # todo larger chunks crash load "couldn't write tmp file..."

# --last-biosample 900002 # todo script crashes and last chunk isn't written

BIOSAMPLE-SET-XML-CHUNK-FILES=$(shell ls shared-chunks)

BIOSAMPLE-SET-XML-CHUNK-NAMES=$(notdir $(basename $(BIOSAMPLE-SET-XML-CHUNK-FILES)))

biosample_set_from_%:
	echo $@
	date
	time docker exec -it basex10 basex -c "CREATE DB $@ basex/shared-chunks/$@.xml"

load-biosample-sets: $(BIOSAMPLE-SET-XML-CHUNK-NAMES) # 5 hours? could possibly do in parallel on a big machine

# docker exec -it basex10  basex -c list
# docker exec -it basex10  basex -c "open biosample_set_from_0; info db"

# docker exec -it basex10  basex -c "open biosample_set_from_0; info index"



PHONY: biosample_non_attribute_metadata_wide
biosample_non_attribute_metadata_wide:
	docker exec -it basex10 basex basex/shared-queries/$@.xq > shared-results/$@.tsv


PHONY: all_biosample_attributes_values_by_raw_id # make sure computer doesn't go to sleep # 70 minutes
	all_biosample_attributes_values_by_raw_id:
	date
	time docker exec -it basex10 basex basex/shared-queries/$@.xq > shared-results/$@.tsv

## psql access from the host: PGPASSWORD=biosample-password psql -h localhost -p 5433 -U biosample -d biosample

## dealing with incomplete data files ?
# sed -n -e :a -e '1,2!{P;N;D;};N;ba' shared-queries/biosample_non_attribute_metadata_wide.tsv > shared-queries/biosample_non_attribute_metadata_wide-minus_two_lines.tsv # basex ouput my have a few garbage lines if the queries are executed before all of the chunks are loaded into databases
# or 
# psql -h localhost -p 5433 -U your_username -d your_database -c "\COPY your_table FROM 'your_csv_file.csv' WITH (FORMAT CSV, NULL 'NULL', HEADER);"


## dump structure
# docker exec -it biosample-postgres pg_dump -U postgres -d biosample --table=non_attribute_metadata --schema-only > non_attribute_metadata_structure.sql


.PHONY: postgres-non-attribute
postgres-non-attribute:
	PGPASSWORD=biosample-password \
		psql \
		-h localhost \
		-p 5433 \
		-U biosample \
		-d biosample \
		-c "\COPY non_attribute_metadata FROM 'shared-results/biosample_non_attribute_metadata_wide.tsv' WITH DELIMITER E'\t' CSV HEADER;"


.PHONY: postgres-all-attribs
postgres-all-attribs:
	PGPASSWORD=biosample-password \
		psql \
		-h localhost \
		-p 5433 \
		-U biosample \
		-d biosample \
		-c "\COPY all_attribs FROM 'shared-results/all_biosample_attributes_values_by_raw_id.tsv' WITH DELIMITER E'\t' CSV HEADER;"


.PHONY: postgres-all
postgres-all: postgres-up postgres-create postgres-non-attribute postgres-all-attribs

