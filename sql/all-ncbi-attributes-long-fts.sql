create index attribute_name_fts on
all_ncbi_attributes_long
	using gin (to_tsvector('english'::regconfig,
attribute_name));

create index harmonized_name_fts on
all_ncbi_attributes_long
	using gin (to_tsvector('english'::regconfig,
harmonized_name));

create index value_fts on
all_ncbi_attributes_long
	using gin (to_tsvector('english'::regconfig,
value));

