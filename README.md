# biosample-xmldb-sqldb

This repository provides an end-to-end pipeline to extract [NCBI BioSample](https://www.ncbi.nlm.nih.gov/biosample) data from XML, transform it, and load into a normalized PostgreSQL database for analytics and project-specific ETL, like instantiating NMDC Biosample objects.

Don't forget to look though (or contribute to) the [issues](https://github.com/turbomam/biosample-basex/issues) and TODOs below

## Codebase and Architecture 

The repository contains:

- A Makefile for pipeline orchestration
- SQL files that define the PostgreSQL schema
- Python scripts for ETL logic

The key components are:

- The `Makefile` - Defines pipeline tasks and orchestration logic
- `biosample_xmldb_sqldb/biosample_xml_to_relational.py` - Extracts BioSample data and loads into normalized tables
- `biosample_xmldb_sqldb/streaming_pivot_bisample_id_chunks.py` - Pivots attribute data into a wide format

The key scripts are:

**biosample_xml_to_relational.py**

- Extracts BioSample, attribute, and metadata into normalized PostgreSQL tables
- Each BioSample is parsed into rows in the `ncbi_attributes_all_long` and `non_attribute_metadata` tables  
- Supports batching and resuming

**streaming_pivot_bisample_id_chunks.py**

- Pivots the attribute data into a wide table grouped by `raw_id` 
- Streams data in chunks by BioSample ID range to control memory usage
- Outputs to `ncbi_attributes_harmonized_wide` table

## Database Model

The key tables populated are:

**ncbi_attributes_all_long**

- Long format attributes table (BioSample ID, attribute details)

**non_attribute_metadata** 

- Related metadata for each BioSample

**ncbi_attributes_harmonized_wide**

This view combines the two tables described above, avoiding the need to explicitly join them in analytical queries. **It is assume that most ETLs will use this view as input.**

## Overview

The pipeline includes the following phases:

- Downloading the full BioSample XML dataset (100+ GB compressed)
- Extracting and transforming data into relational PostgreSQL tables
- Pivoting data into an analysis-friendly wide format

## Getting Started

The pipeline is orchestrated end-to-end via `make`, with targets for each stage.

**Requirements**

- Docker is installed and running
- Python 3.9+ is installed
- [Python poetry](https://python-poetry.org/docs/) is installed
    -  an environment has been created with `poetry install`

The full pipeline flow and additional options are documented in the [Makefile](Makefile).

Don't forget to run database operations inside a [screen](https://www.gnu.org/software/screen/manual/screen.html) session

The main pipeline tasks are defined in the Makefile and can be run as:

```
make postgres-up         # Start PostgreSQL container  
make postgres-create     # Create DB and user
make postgres-load       # Load data from BioSample XML    
make postgres-pivot      # Pivot attribute data
make postgres-post-pivot-view # Create a view of the  pivoted data
```

The pipeline uses a local `.env` file for database credentials and connections string.

## References

- _This is a replacement for https://github.com/turbomam/biosample-basex_
    - _required a more complicated system setup_
    - _used SQLite as an intermediary between XML and Postgres_
- _Inspired by https://github.com/INCATools/biosample-analysis_


The Makefile downloads **all** of NCBI's BioSample collection and unpacks it, using ~ 100 GB of storage. However, due to the `--biosamples-per-file` limit,
it only populates a subset of the Biosamples into the XML and Postgres databases. Remove those lines to load the entire collection. That takes ~ 24 hours and requires ~ 400 GB of storage.


## NCBI Attributes vs XML Attributes

"NCBI Attributes" refers to specific XML paths under the BioSample records, while "XML attributes" refers to the general attribute properties on XML elements.

The BioSample XML structure contains a distinction between:

**NCBI Attributes** 

- Specific `<Attribute>` nodes under `<Attributes>` in each BioSample  
- Contain metadata like measurement values, units, display names etc
- Extracted into the `ncbi_attributes_all_long` table

**XML Attributes**

- The standard attributes associated with each XML node
- For example `id`, `name`, `url` attributes on XML elements
- Often used to store metadata like identifiers

The Python code extracts both:

- The NCBI Attributes are parsed from the dedicated nodes
- The XML attributes are also captured from nodes like `BioSample`, `Id`, `Link` etc

So in summary:

- **NCBI Attributes**: Dedicated metadata nodes under each BioSample
- **XML Attributes**: Standard attributes on XML elements

The scripts extract and store both into the database tables.

## Performance

The entire build of a 105 GB/35 Million BioSample XML dataset takes approximately 2 days

# Performance notes

## from repo root
`date && time grep -c '<BioSample' downloads/biosample_set.xml`

>Thu Feb 22 17:20:39 UTC 2024
>37572120
>
>real    6m41.464s
>user    0m46.455s
>sys     0m33.311s

`tail -n 100 downloads/biosample_set.xml  | grep '<BioSample'`
> <BioSample access="public" publication_date="2024-02-22T00:00:00.000" last_update="2024-02-22T01:55:09.056" submission_date="2024-02-22T01:55:09.056" 
> id="40028294" accession="SAMN40028294">
> <BioSample access="public" publication_date="2024-02-22T00:00:00.000" last_update="2024-02-22T02:28:19.950" submission_date="2024-02-22T02:22:05.510" 
> id="40028511" accession="SAMN40028511">

`time make postgres-load`
>2024-02-21 18:52:52,538 Processed 37,550,001 to 37,551,000 of 50,000,000 biosamples (75.10%)
>2024-02-21 18:52:53,673 Done parsing biosamples
>Elapsed time: 60675.36360359192 seconds
>2024-02-21 18:52:55,738 Done parsing biosamples
>
>real    1011m25.977s
>user    970m59.386s
>sys     1m50.840s

# Compared to previous methods that included teh BaseX XML database

## Advantages

- fewer steps
- lower RAM and CPU usage
- fewer containers
- empty cells aren't a mixture of empty strings and NULLs

## Limitation
- can't search through data from xml nodes that we didn't insert into SQL database
    - see assets/path_counts.yaml
    - see assets/curl_biosample_xml_examples.txt

# TODOs:

- Could include tools for normalizing NCBI BioSample values. FOr examples, converting all `depth`s into a single numerical column with a consistent unit. May benefit from quantulum3.
- special parsing for paragraph Keywords?
- TODO think of a way to extract XML tables into soemthign that could go into Postgres
    - like biosample-caption-row-value?
- set a lower threshold for id and link attribute detection or just write all of them to a different table?
- write yaml index to file on every database write?
- could minimal.py and streaming_pivot_bisample_id_chunks.py be interleaved?
- check though several columns to see if '|||' is being used as a delimiter
    - what other delimiters could we use?
    - remember ||| delimiter when searching columns like bp_id
    - would fts help here? the bp_ids are integers, not words
- add resume-at feature. Might also require a “cleanup from” feature.
- improve FTS query experience 
    - see `sql/experimental-factor-fts-query.sql`
- use different disks for reading xml file and writing to database
- keep A and B databases (prod and stage)