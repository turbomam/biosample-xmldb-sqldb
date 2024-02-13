# biosample-xmldb-sqldb
Tools for loading [NCBI BioSample](https://www.ncbi.nlm.nih.gov/biosample) into an XML database and then transforming that into a SQL database

- _This is a replacement for https://github.com/turbomam/biosample-basex_
    - _required a more complicated system setup_
    - _used SQLite as an intermediary between XML and Postgres_
- _Inspired by https://github.com/INCATools/biosample-analysis_
- _Could include tools for normalizing NCBI BioSample values in the future._

Requirements:
- Docker is installed and running
- Python 3.10+ is installed
- Python poetry is installed
- an environment has been created with `poetry install`

The Makefile does not provide an `all` target at this point.
If none of the containers are running yet and the downloads and chunks files have not been created yet,
then **a typical flow would be** `make pre-basex-all basex-all postgres-all`

If you want to **see what you're getting yourself into** first, try `make --dry-run pre-basex-all basex-all postgres-all`

The Makefile provides lots of hints about how to interact with the databases from the host.

The Makefile in this repo downloads **all** of NCBI's BioSample collection and unpacks it, using ~ 100 GB of storage. However, due to these limits...

```shell
  --biosamples-per-file 1000  \
  --last-biosample 9000
```

...it only populates a subset of 9000 Biosamples into the XML and Postgres databases. Remove those lines to load the entire collection. That takes ~ 24 hours and requires ~ 400 GB of storage.

If containers have been built or some of those files have been created, then the user could either run `make clean` and start over **losing** all of that data,
or manually select make targets (or other commands) that pick up at the desired point. No automation is provided for that case yet.


----

To do:
- reasonable Docker settings (CPU, RAM...)_
