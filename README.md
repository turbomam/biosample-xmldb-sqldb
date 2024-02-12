# biosample-xmldb-sqldb
Tools for loading NCBI Biosample into an XML database and then transforming that into a SQL database

Requires Docker, Python and `poetry install`

The Makefile does not provide an `all` target at this point.
If none of the containers are running yet and the downlaods and chunks files have not been created yet,
then a typical flwo would been
`make pre-basex-all basex-all postgres-all`
