-- all_attribs definition
-- <BioSample submission_date="2009-07-09T15:04:26.787" last_update="2013-06-12T08:44:53.437" publication_date="2010-01-26T11:30:53.720" access="public" id="2646" accession="SAMN00002646">
-- <Attribute attribute_name="barcode" unit="AACG">March</Attribute>

--        Attribute: 162404219x, leaf
--          @attribute_name: 162404219x, strings, leaf
--          text(): 161850291x, strings, leaf
--          @harmonized_name: 116706130x, strings, leaf
--          @display_name: 116706130x, strings, leaf
--          @unit: 16966x, strings, leaf

CREATE TABLE IF NOT EXISTS all_attribs(
  "raw_id" INTEGER,
  "attribute_name" TEXT,
  "harmonized_name" TEXT,
  "value" TEXT
);

CREATE INDEX all_attribs_idx on all_attribs("harmonized_name", "raw_id", "attribute_name");
