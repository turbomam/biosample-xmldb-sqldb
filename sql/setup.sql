-- DROP SCHEMA public;

-- CREATE SCHEMA public AUTHORIZATION pg_database_owner;
-- public.ncbi_attributes_all_long definition

-- Drop table

-- DROP TABLE public.ncbi_attributes_all_long;

CREATE TABLE public.ncbi_attributes_all_long (
	raw_id int8 NULL,
	attribute_name text NOT NULL,
	harmonized_name text NULL,
	display_name text NULL,
	unit text NULL,
	value text NULL
);
CREATE INDEX names_fts ON public.ncbi_attributes_all_long USING gin (to_tsvector('english'::regconfig, ((((attribute_name || ' '::text) || harmonized_name) || ' '::text) || display_name)));
CREATE INDEX ncbi_attributes_all_long_harmonized_name_idx ON public.ncbi_attributes_all_long USING btree (harmonized_name);
CREATE INDEX ncbi_attributes_all_long_raw_id_idx ON public.ncbi_attributes_all_long USING btree (raw_id);
CREATE INDEX value_fts ON public.ncbi_attributes_all_long USING gin (to_tsvector('english'::regconfig, value));


-- public.ncbi_attributes_harmonized_wide definition

-- Drop table

-- DROP TABLE public.ncbi_attributes_harmonized_wide;

-- CREATE TABLE public.ncbi_attributes_harmonized_wide

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


-- public.attributes_plus source

-- CREATE OR REPLACE VIEW public.attributes_plus

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