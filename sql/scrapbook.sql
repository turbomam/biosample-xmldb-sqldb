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
