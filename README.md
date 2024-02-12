# biosample-xmldb-sqldb
Tools for loading [NCBI BioSample](https://www.ncbi.nlm.nih.gov/biosample) into an XML database and then transforming that into a SQL database

Requires Docker, Python and `poetry install`

The Makefile does not provide an `all` target at this point.
If none of the containers are running yet and the downlaods and chunks files have not been created yet,
then a typical flow would been
`make pre-basex-all basex-all postgres-all`

If containers have been built or some of those files have been created, then the user could either run `make clean` and start over **losing** all of that data,
or manually selelct make targets (or other commands) that pick up at the deisred point. No automation is provided int hat case yet.
