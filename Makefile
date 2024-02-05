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

# mkdir data # skipping #chown -R 1000:1000 data
# docker run --name basex10 -p 8080:8080 -v `pwd`/data:/srv/basex/data -d quodatum/basexhttp
# docker exec -it basex10 /bin/sh
# basex -cPASSWORD
# (interactively enter password)
# exit
# docker container restart basex10
# visit localhost:8080, load some test data, and increase the memory limit to 4000 MB and the timeout to 600
# the confirm that the new database is reported by this command
# curl -u admin:password http://localhost:8080/rest

.PHONY: biosample-set-xml-chunks
biosample-set-xml-chunks: $(UNPACKED_FILE)
	mkdir -p $(CHUNKS_FOLDER)
	$(RUN) python biosample_xmldb_sqldb/split_into_N_biosamples.py \
		--input-file-name $< \
		--output-dir $(CHUNKS_FOLDER) \
		--biosamples-per-file 1000000 # 35x ~ 3 GB output files/databases? ~ 30 seconds per chunk # load: ~ 8 min per chunk # todo larger chunks crash load "couldn't write tmp file..."

# --last-biosample 900002 # todo script crashes and last chunk isn't written

BIOSAMPLE-SET-XML-CHUNK-FILES=$(shell ls data/biosample-set-xml-chunks)

BIOSAMPLE-SET-XML-CHUNK-NAMES=$(subst .xml,,$(BIOSAMPLE-SET-XML-CHUNK-FILES))

BIOSAMPLE-SET-XML-CHUNK-LOGS=$(addsuffix .log,$(addprefix data/biosample-set-xml-chunks/,$(BIOSAMPLE-SET-XML-CHUNK-NAMES)))

data/biosample-set-xml-chunks/biosample_set_from_%.log: # todo doesn't actually do any logging yet!
	date
	time docker exec -it basex10 basex -c "CREATE DB $(basename $(notdir $@)) $(subst data/,basex/data/,$(subst .log,.xml,$@))"

create-biosample-set-logs: $(BIOSAMPLE-SET-XML-CHUNK-LOGS) # 2 hours?

followup:  data/biosample-set-xml-chunks/biosample_set_from_10000001.log data/biosample-set-xml-chunks/biosample_set_from_11000001.log data/biosample-set-xml-chunks/biosample_set_from_12000001.log data/biosample-set-xml-chunks/biosample_set_from_13000001.log data/biosample-set-xml-chunks/biosample_set_from_14000001.log data/biosample-set-xml-chunks/biosample_set_from_15000001.log data/biosample-set-xml-chunks/biosample_set_from_16000001.log data/biosample-set-xml-chunks/biosample_set_from_17000001.log data/biosample-set-xml-chunks/biosample_set_from_18000001.log data/biosample-set-xml-chunks/biosample_set_from_19000001.log data/biosample-set-xml-chunks/biosample_set_from_20000001.log data/biosample-set-xml-chunks/biosample_set_from_21000001.log data/biosample-set-xml-chunks/biosample_set_from_22000001.log data/biosample-set-xml-chunks/biosample_set_from_23000001.log data/biosample-set-xml-chunks/biosample_set_from_24000001.log data/biosample-set-xml-chunks/biosample_set_from_25000001.log data/biosample-set-xml-chunks/biosample_set_from_26000001.log data/biosample-set-xml-chunks/biosample_set_from_27000001.log data/biosample-set-xml-chunks/biosample_set_from_28000001.log data/biosample-set-xml-chunks/biosample_set_from_29000001.log data/biosample-set-xml-chunks/biosample_set_from_30000001.log data/biosample-set-xml-chunks/biosample_set_from_3000001.log data/biosample-set-xml-chunks/biosample_set_from_31000001.log data/biosample-set-xml-chunks/biosample_set_from_32000001.log data/biosample-set-xml-chunks/biosample_set_from_33000001.log data/biosample-set-xml-chunks/biosample_set_from_34000001.log data/biosample-set-xml-chunks/biosample_set_from_35000001.log data/biosample-set-xml-chunks/biosample_set_from_36000001.log data/biosample-set-xml-chunks/biosample_set_from_37000001.log data/biosample-set-xml-chunks/biosample_set_from_4000001.log data/biosample-set-xml-chunks/biosample_set_from_5000001.log data/biosample-set-xml-chunks/biosample_set_from_6000001.log data/biosample-set-xml-chunks/biosample_set_from_7000001.log data/biosample-set-xml-chunks/biosample_set_from_8000001.log data/biosample-set-xml-chunks/biosample_set_from_9000001.log