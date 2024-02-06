declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

let $delim := "|||"

for $db in db:list()
  let $coll := db:open($db)
  where fn:starts-with($db, "biosample_set_from")

  for $attrib in $coll/BioSampleSet/BioSample/Attributes/Attribute

    let $id_val := data($attrib/../../@id)

    let $attrib_name := fn:normalize-space(
      string-join(
        data($attrib/@attribute_name),$delim
      )
    )

    let $hn := fn:normalize-space(
      string-join(
        data($attrib/@harmonized_name),$delim
      )
    )

    let $attrib_val := fn:normalize-space(
      string-join(
        data($attrib),$delim
      )
    )

    return

    <csv><record> 

    <raw_id>{
      $id_val
    }</raw_id>

    <attribute_name>{
      $attrib_name
    }</attribute_name>

    <harmonized_name>{
      $hn
    }</harmonized_name>

    <value>{
      $attrib_val
    }</value>

</record></csv>
