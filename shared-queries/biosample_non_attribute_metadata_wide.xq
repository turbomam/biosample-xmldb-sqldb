declare option output:method "csv";
declare option output:csv "header=yes, separator=tab";

(: see https://github.com/turbomam/biosample-basex/issues/8 :)

let $delim := "|||"

for $db in db:list()
  let $coll := db:open($db)
  where fn:starts-with($db, "biosample_set_")

for $bs in $coll/BioSampleSet/BioSample

let $accession :=  fn:normalize-space(
  string-join(
    data(
      $bs/@accession
    ),$delim
  )
)


let $id := fn:normalize-space(
  string-join(
    data(
      $bs/@id
    ),$delim
  )
)

let $primary_id := fn:normalize-space(
  string-join(
    data(
      $bs/Ids/Id[@is_primary="1"]
    ),$delim
  )
)

(: string join without distinct/unique prob causes dupes :)
let $curie_id := fn:normalize-space(
concat(
      "BIOSAMPLE:",$primary_id
  )
)


let $sraid :=  fn:normalize-space(
  string-join(
    data(
      $bs/Ids/Id[@db="SRA"]
    ),$delim
  )
)

(: <Id db_label="Sample name">14_0903_02_20cm</Id> :)

let $samp_name :=  fn:normalize-space(
  string-join(
    data(
      $bs/Ids/Id[@db_label="Sample name"]
    ),$delim
  )
)


let $bp_link := $bs/Links/Link[@type='entrez' and @target='bioproject']

let $bp_ids := fn:normalize-space(
  string-join($bp_link,$delim))


let $model := fn:normalize-space(
  string-join(
    data(
      $bs/Models/Model
    ),$delim
  )
)
let $package := fn:normalize-space(
  string-join(
    data(
      $bs/Package
    ),$delim
  )
)
let $package_display_name := fn:normalize-space(
  string-join(
    data(
      $bs/Package/@display_name
    ),$delim
  )
)
let $paragraph := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Comment/Paragraph
    ),$delim
  )
)

let $status := fn:normalize-space(
  string-join(
    data(
      $bs/Status/@status
    ),$delim
  )
)

let $status_date := fn:normalize-space(
  string-join(
    data(
      $bs/Status/@when
    ),$delim
  )
)

let $taxonomy_id := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Organism/@taxonomy_id
    ),$delim
  )
)
let $taxonomy_name := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Organism/@taxonomy_name
    ),$delim
  )
)
let $title := fn:normalize-space(
  string-join(
    data(
      $bs/Description/Title
    ),$delim
  )
)

return

<result><csv>


<id>{
  $curie_id
}
</id>

<accession>{
  $accession
}
</accession>

<raw_id>{
  $id
}
</raw_id>

<primary_id>{
  $primary_id
}</primary_id>

<sra_id>{
  $sraid
}</sra_id>


<bp_id>{
  $bp_ids
}</bp_id>


<model>{
  $model
}</model>

<package>{
  $package
}</package>
<package_name>{
  $package_display_name
}</package_name>

<status>{
  $status
}</status>

<status_date>{
  $status_date
}</status_date>

<taxonomy_id>{
  $taxonomy_id
}</taxonomy_id>
<taxonomy_name>{
  $taxonomy_name
}</taxonomy_name>


<title>{
  $title
}</title>


<samp_name>{
  $samp_name
}</samp_name>


<paragraph>{
  $paragraph
}</paragraph>


</csv></result>

