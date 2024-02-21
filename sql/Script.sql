-- TODO not sure whether last pandas chunk will get written to naal since the script looks for completing chunks by count
-- TODO will the script terminate?
-- TODO will the YAML index be written to disk?

-- TODO outside of loop, check if there are still any rows in either of the pandas dataframes
-- write yaml index to file on every database write?

-- TODO add resume at feature. Might also require a “cleanup from” feature.

-- TODO indexing

-- TODO pivoting by chunks of specified biosample ids

-- date && time grep -c '<BioSample' biosample_set.xml # 37 551 803 # 10 minutes

-- tail -n 100 biosample_set.xml | grep '<BioSample' # 39 991 140

-- don't forget to run database operations inside of `screen`

-- improvements? fewer steps. lower RAM and CPU at least up to pivoting. few containers. empty cells aren't a mixture of empty strings and NULLs?

-- limitation: can't search through xml nodes for data that we didn't insert into database

-- TODO use different disks for reading xml file and writing to database

-- TODO change prefixed id in 'id' column to BIOSAMPLE: + accession, (not primary id)

-- TODO keep A and B databases (prod and stage)


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
-- index on bp_id? doesn't help?
--

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
-- TODO special parsing for Keywords?
-- TODO delimiter orhter than ||| ?

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
