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

# mkdir -p basex-data # skipping #chown -R 1000:1000 data
# mkdir -p shared-data # skipping #chown -R 1000:1000 data
# docker run --name basex10 -p 8080:8080 -v `pwd`/shared-basex-data:/srv/basex/data -v `pwd`/shared-queries:/srv/basex/shared-queries -v `pwd`/shared-results:/srv/basex/shared-results -v `pwd`/shared-chunks:/srv/basex/shared-chunks -d quodatum/basexhttp
# docker exec -it basex10 /bin/bash
# basex -cPASSWORD
# (interactively enter basex-password)
# exit
# docker container restart basex10

# visit localhost:8080, optionally load some test data into a new database
# then confirm that the new database is reported by this command
# curl -u admin:basex-password http://localhost:8080/rest

.PHONY: setup-shared-dirs
setup-shared-dirs:
	mkdir -p shared-chunks shared-queries shared-results shared-basex-data

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

load-biosample-sets: $(BIOSAMPLE-SET-XML-CHUNK-NAMES) # 2 hours?

PHONY: biosample_non_attribute_metadata_wide
biosample_non_attribute_metadata_wide:
	docker exec -it basex10 basex basex/shared-queries/$@.xq > shared-results/$@.tsv
