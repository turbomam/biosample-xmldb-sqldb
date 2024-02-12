CREATE INDEX attribute_name_fts ON public.all_attribs USING gin (to_tsvector('english'::regconfig, attribute_name));
CREATE INDEX harmonized_name_fts ON public.all_attribs USING gin (to_tsvector('english'::regconfig, harmonized_name));
CREATE INDEX value_fts ON public.all_attribs USING gin (to_tsvector('english'::regconfig, value));