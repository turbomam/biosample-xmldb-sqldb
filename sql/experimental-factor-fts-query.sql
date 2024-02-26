select
	attribute_name,
	harmonized_name,
	display_name,
	COUNT(*) as match_count
from
	public.ncbi_attributes_all_long
where
	to_tsvector('english'::regconfig,
	((((attribute_name || ' '::text) || harmonized_name) || ' '::text) || display_name)) @@
    to_tsquery('english',
	'''experimental factor'''::text)
group by
	attribute_name,
	harmonized_name,
	display_name
order by
	count(*) desc ;
