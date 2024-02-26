-- TODO special parsing for paragraph Keywords?

-- TODO think of a way to extract XML tables into soemthign that could go into Postgres
--   like biosample-caption-row-value?

-- TODO set a lower threshold for id and link attribute detection or just write all of them to a different table?

-- TODO write yaml index to file on every database write?

-- TODO could minimal.py and streaming_pivot_bisample_id_chunks.py be interleaved?

-- TODO check though several columns to see if '|||' is being used as a delimiter
-- TODO what other delimiters could we use?
-- TODO delimiter other than ||| ?
-- TODO remember ||| delimiter when searching columns like bp_id
--   woiuld fts help here? the bp_ids are integers, not words

-- TODO add resume at feature. Might also require a “cleanup from” feature.

-- TODO indexing
-- TODO fts
-- TODO define indexes before starting to extract and insert?

-- TODO use different disks for reading xml file and writing to database

-- TODO keep A and B databases (prod and stage)

-- from repo root
-- date && time grep -c '<BioSample' downloads/biosample_set.xml
--Thu Feb 22 17:20:39 UTC 2024
--37572120
--
--real    6m41.464s
--user    0m46.455s
--sys     0m33.311s

-- tail -n 100 downloads/biosample_set.xml  | grep '<BioSample'
--<BioSample access="public" publication_date="2024-02-22T00:00:00.000" last_update="2024-02-22T01:55:09.056" submission_date="2024-02-22T01:55:09.056" 
--  id="40028294" accession="SAMN40028294">
--<BioSample access="public" publication_date="2024-02-22T00:00:00.000" last_update="2024-02-22T02:28:19.950" submission_date="2024-02-22T02:22:05.510" 
--  id="40028511" accession="SAMN40028511">

-- use minimal.py instead
--time poetry run python stream_and_write.py
--2024-02-21 18:52:52,538 Processed 37,550,001 to 37,551,000 of 50,000,000 biosamples (75.10%)
--2024-02-21 18:52:53,673 Done parsing biosamples
--Elapsed time: 60675.36360359192 seconds
--2024-02-21 18:52:55,738 Done parsing biosamples
--
--real    1011m25.977s
--user    970m59.386s
--sys     1m50.840s

-- don't forget to run database operations inside of `screen`
-- improvements? fewer steps. lower RAM and CPU at least up to pivoting. few containers. empty cells aren't a mixture of empty strings and NULLs?
-- limitation: can't search through xml nodes for data that we didn't insert into database


select
	nam.raw_id,
	nam.id,
	nam.accession,
	nam.primary_id,
	nam.sra_id,
	nam.bp_id,
	nam.model,
	nam.package,
	nam.package_name,
	nam.status,
	nam.status_date,
	nam.taxonomy_id,
	nam.taxonomy_name,
	nam.title,
	nam.samp_name,
	nam.paragraph,
	naal.*
from
	non_attribute_metadata nam
left join ncbi_attributes_all_long naal on
	nam.raw_id = naal.raw_id
where
	bp_id = '19655';


select
	naal.raw_id ,
	naal.harmonized_name ,
	naal.value
from
	non_attribute_metadata nam
left join ncbi_attributes_all_long naal on
	nam.raw_id = naal.raw_id
where
	bp_id = '656268';

select
	raw_id
from
	non_attribute_metadata
where
	bp_id = '656268';

select
	count(raw_id)
from
	non_attribute_metadata
where
	bp_id = '656268';

select
	distinct attribute_name,
	harmonized_name
from
	ncbi_attributes_all_long
where
	to_tsvector('english',
	attribute_name) 
	@@ phraseto_tsquery('english',
	'throat');

select
	harmonized_name,
	count(1)
from
	ncbi_attributes_all_long naal
group by
	harmonized_name
order by
	count(1) desc;

select
	ncbi_attributes_all_long.unit ,
	count(1)
from
	ncbi_attributes_all_long
group by
	ncbi_attributes_all_long.unit;

select
	raw_id,
	count(1)
from
	non_attribute_metadata
group by
	raw_id
having
	count(1) > 1;

select
	*
from
	ncbi_attributes_all_long
where
	value like '%|||%'
limit 9;

select
	raw_id ,
	accession ,
	paragraph
from
	non_attribute_metadata
where
	paragraph like '%|||%'
limit 9;


select
	package_name ,
	count(1)
from
	non_attribute_metadata
group by
	package_name
order by
	count(1) desc ;

select
	raw_id ,
	accession ,
	prefixed_id ,
	primary_id
from
	non_attribute_metadata
where
	accession != primary_id
limit 9 ;

select
	max(raw_id)
from
	non_attribute_metadata ;

select
	max(raw_id)
from
	ncbi_attributes_all_long ;

select
	max(raw_id)
from
	ncbi_attributes_harmonized_wide nahw ;

select
	harmonized_name
from
	ncbi_attributes_all_long naal
where
	harmonized_name is not null
order by
	harmonized_name ;
--

select
	*
from
	non_attribute_metadata
where
	accession like '%|||%';
-- no


select
	*
from
	non_attribute_metadata
where
	accession is null;
-- no


select
	accession,
	count(1)
from
	non_attribute_metadata
group by
	accession
having
	count(1) > 1;
-- no -- 30 sec


select
	*
from
	non_attribute_metadata
where
	bp_id like '%|||%';
-- yes



select
	*
from
	non_attribute_metadata
where
	bp_id is null ;
-- yes



select
	*
from
	non_attribute_metadata
where
	bp_id is not null ;
-- yes



select
	*
from
	non_attribute_metadata
where
	contributors like '%|||%';
-- yes -- seconds -- cached ?



select
	*
from
	non_attribute_metadata
where
	contributors is null ;
-- no




select
	*
from
	non_attribute_metadata
where
	contributors is not null ;
--



select
	*
from
	non_attribute_metadata
where
	model like '%|||%';
-- yes --  seconds

 
select
	*
from
	non_attribute_metadata
where
	model is not null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	model is null ;
-- no

select
	*
from
	non_attribute_metadata
where
	owner_abbreviation like '%|||%';
-- no -- 3 seconds


select
	*
from
	non_attribute_metadata
where
	owner_abbreviation is not null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	owner_abbreviation is null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	owner_text like '%|||%';
-- yes

select
	*
from
	non_attribute_metadata
where
	owner_text is null ;
-- yes

select
	*
from
	non_attribute_metadata
where
	owner_text is not null ; -- yes


select
	*
from
	non_attribute_metadata
where
	owner_url like '%|||%';
-- yes


select
	*
from
	non_attribute_metadata
where
	owner_url is not null ; -- yes


select
	*
from
	non_attribute_metadata
where
	owner_url is null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	package like '%|||%' ;
-- no


select
	*
from
	non_attribute_metadata
where
	package is null ;
-- no


select
	*
from
	non_attribute_metadata
where
	package is not null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	package_name like '%|||%' ;
-- no


select
	*
from
	non_attribute_metadata
where
	package_name is null ;
-- no


select
	*
from
	non_attribute_metadata
where
	package_name is not null ;
-- yes



select
	*
from
	non_attribute_metadata
where
	paragraph like '%|||%' ;
-- yes


select
	*
from
	non_attribute_metadata
where
	paragraph is null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	paragraph is not null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	prefixed_id like '%|||%' ;
-- no


select
	*
from
	non_attribute_metadata
where
	prefixed_id is null ;
-- no


select
	*
from
	non_attribute_metadata
where
	prefixed_id is not null ;
-- yes


select
	prefixed_id,
	count(1)
from
	non_attribute_metadata
group by
	prefixed_id
having
	count(1) > 1 ;
-- no





select
	*
from
	non_attribute_metadata
where
	primary_id like '%|||%' ;
-- no


select
	*
from
	non_attribute_metadata
where
	primary_id is null ;
-- no


select
	*
from
	non_attribute_metadata
where
	primary_id is not null ;
-- yes


select
	primary_id,
	count(1)
from
	non_attribute_metadata
group by
	primary_id
having
	count(1) > 1 ;
-- no



select
	*
from
	non_attribute_metadata
where
	synonym is not null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	synonym like '%|||%' ;
-- yes



select
	*
from
	non_attribute_metadata
where
	table_caption is not null ;
-- yes


select
	*
from
	non_attribute_metadata
where
	table_caption like '%|||%' ;
-- yes
-- TODO extract all unique values after splitting on |||

select
	*
from
	ncbi_attributes_all_long_with_accessions
where
	harmonized_name = 'geo_loc_name'
	and to_tsvector('english',
	value) 
	@@ phraseto_tsquery('english',
	'atlantic');


-- DROP SCHEMA public;

CREATE SCHEMA public AUTHORIZATION pg_database_owner;
-- public.ncbi_attributes_all_long definition

-- Drop table

-- DROP TABLE public.ncbi_attributes_all_long;

CREATE TABLE public.ncbi_attributes_all_long (
	raw_id int8 NULL,
	attribute_name text NULL,
	harmonized_name text NULL,
	display_name text NULL,
	unit text NULL,
	value text NULL
);
CREATE INDEX ncbi_attributes_all_long_harmonized_name_idx ON public.ncbi_attributes_all_long USING btree (harmonized_name);
CREATE INDEX ncbi_attributes_all_long_raw_id_idx ON public.ncbi_attributes_all_long USING btree (raw_id);
CREATE INDEX value_fts ON public.ncbi_attributes_all_long USING gin (to_tsvector('english'::regconfig, value));

--Start time	Fri Feb 23 09:57:01 EST 2024
--Finish time	Fri Feb 23 10:24:05 EST 2024

--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed
--word is too long to be indexed

-- public.non_attribute_metadata definition

-- Drop table

-- DROP TABLE public.non_attribute_metadata;

CREATE TABLE public.non_attribute_metadata (
	raw_id int8 NOT NULL,
	accession text NOT NULL,
	bp_id text NULL,
	contributors text NOT NULL,
	model text NOT NULL,
	owner_abbreviation text NULL,
	owner_text text NULL,
	owner_url text NULL,
	package text NOT NULL,
	package_name text NOT NULL,
	paragraph text NULL,
	prefixed_id text NOT NULL,
	primary_id text NOT NULL,
	samp_name text NULL,
	sra_id text NULL,
	status text NULL,
	status_date text NULL,
	synonym text NULL,
	table_caption text NULL,
	taxonomy_id text NULL,
	taxonomy_name text NULL,
	title text NULL
);
CREATE UNIQUE INDEX non_attribute_metadata_accession_idx ON public.non_attribute_metadata USING btree (accession);
CREATE INDEX non_attribute_metadata_bp_id_idx ON public.non_attribute_metadata USING btree (bp_id);
CREATE UNIQUE INDEX non_attribute_metadata_prefixed_id_idx ON public.non_attribute_metadata USING btree (prefixed_id);
CREATE UNIQUE INDEX non_attribute_metadata_primary_id_idx ON public.non_attribute_metadata USING btree (primary_id);
CREATE UNIQUE INDEX non_attribute_metadata_raw_id_idx ON public.non_attribute_metadata USING btree (raw_id);


-- public.ncbi_attributes_all_long_with_accessions source

CREATE OR REPLACE VIEW public.ncbi_attributes_all_long_with_accessions
AS SELECT nam.accession,
    naal.raw_id,
    naal.attribute_name,
    naal.harmonized_name,
    naal.display_name,
    naal.unit,
    naal.value
   FROM ncbi_attributes_all_long naal
     JOIN non_attribute_metadata nam ON naal.raw_id = nam.raw_id;


create or replace
view attributes_plus
as
select
	nam.accession,
	nam.bp_id,
	nam.contributors,
	nam.model,
	nam.owner_abbreviation,
	nam.owner_text,
	nam.owner_url,
	nam.package,
	nam.package_name,
	nam.paragraph,
	nam.prefixed_id,
	nam.primary_id,
	nam.samp_name,
	nam.sra_id,
	nam.status,
	nam.status_date,
	nam.synonym,
	nam.table_caption,
	nam.taxonomy_id,
	nam.taxonomy_name,
	nam.title,
	nahw.*
from
	non_attribute_metadata nam
join ncbi_attributes_harmonized_wide nahw on
	nam.raw_id = nahw.raw_id;


select
	max(raw_id)
from
	ncbi_attributes_harmonized_wide ;


select
	*
from
	ncbi_attributes_harmonized_wide
where
	raw_id > 100
	and raw_id < 200 ;


create index names_fts on
ncbi_attributes_all_long
	using gin (
    to_tsvector('english'::regconfig,
attribute_name || ' ' || harmonized_name || ' ' || display_name)
);


select
	*
from
	public.ncbi_attributes_all_long
where
	to_tsvector('english',
	attribute_name || ' ' || harmonized_name || ' ' || display_name) @@ to_tsquery('english',
	'nose mouth');

select
	distinct attribute_name,
	harmonized_name
from
	ncbi_attributes_all_long
where
	to_tsvector('english',
	attribute_name || ' ' || harmonized_name || ' ' || display_name)
	@@ to_tsquery('english',
	'context');

