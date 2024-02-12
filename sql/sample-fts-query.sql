select
	distinct value
from
	all_attribs
where
	to_tsvector('english',
	value) @@ phraseto_tsquery('english',
	'african');
