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