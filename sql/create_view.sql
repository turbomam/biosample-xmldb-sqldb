CREATE VIEW attributes_plus_view AS
                             select
                             id,
                             accession,
                             primary_id,
                             sra_id,
                             bp_id,
                             model,
                             package,
                             package_name,
                             status,
                             status_date,
                             taxonomy_id,
                             taxonomy_name,
                             title,
                             samp_name,
                             paragraph,
                             harmonized_attributes_wide.*
                             FROM non_attribute_metadata 
                             FULL OUTER JOIN harmonized_attributes_wide ON non_attribute_metadata.raw_id = harmonized_attributes_wide.raw_id