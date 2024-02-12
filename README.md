# biosample-xmldb-sqldb
Tools for loading [NCBI BioSample](https://www.ncbi.nlm.nih.gov/biosample) into an XML database and then transforming that into a SQL database

REquirements:
- Docker is installed and running
- Python 3.10+ is installed
- Python poetry is installed
- an environment has been created with `poetry install`

The Makefile does not provide an `all` target at this point.
If none of the containers are running yet and the downlaods and chunks files have not been created yet,
then **a typical flow would be** `make pre-basex-all basex-all postgres-all`

If you want to **see what you're getting yourself into** first, try `make --dry-run pre-basex-all basex-all postgres-all`

The Makefile in this repo downloads all of NCBI's BioSample colelctiona nd unpacks it, using ~ 100 GB of storage. Hpowever, due to 

```shell
  --biosamples-per-file 1000  \
  --last-biosample 9000
```

It only populates a subset of that into the XML and Postgres databases. Remove those lines to load the entire colelction. THat requires ~ 400 GB of storage.

If containers have been built or some of those files have been created, then the user could either run `make clean` and start over **losing** all of that data,
or manually selelct make targets (or other commands) that pick up at the deisred point. No automation is provided int hat case yet.

