-- non_attribute_metadata definition

CREATE TABLE IF NOT EXISTS non_attribute_metadata(
  "id" TEXT,
  "accession" TEXT,
  "raw_id" INTEGER PRIMARY KEY,
  "primary_id" TEXT,
  "sra_id" TEXT,
  "bp_id" TEXT,
  "model" TEXT,
  "package" TEXT,
  "package_name" TEXT,
  "status" TEXT,
  "status_date" TEXT,
  "taxonomy_id" TEXT,
  "taxonomy_name" TEXT,
  "title" TEXT,
  "samp_name" TEXT,
  "paragraph" TEXT

);

--  INTEGER PRIMARY KEY,

--CREATE INDEX non_attribute_metadata_raw_id_idx on non_attribute_metadata("raw_id");

