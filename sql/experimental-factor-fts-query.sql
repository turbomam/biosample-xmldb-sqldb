select
	distinct attribute_name,
	harmonized_name
from
	all_ncbi_attributes_long
where
	to_tsvector('english', attribute_name) 
	@@ phraseto_tsquery('english', 'experimental factor');
