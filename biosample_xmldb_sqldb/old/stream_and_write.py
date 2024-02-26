import time

import click
import pprint

import pandas as pd
import psycopg2
import psycopg2.pool
import lxml.etree as ET
import logging
import yaml


@click.command()
@click.option('--biosample-file', type=str, default="../downloads/biosample_set.xml",
              help='Path to the BioSample XML file.')
@click.option('--max-biosamples', type=int, default=50_000, help='Maximum number of biosamples to process.')
@click.option('--batch-size', type=int, default=1_000, help='Size of each batch.')
def main(biosample_file, max_biosamples, batch_size):
    logger = logging.getLogger('biosamples')
    logger.setLevel(logging.INFO)

    # Set log output format
    formatter = logging.Formatter('%(asctime)s %(message)s')

    # Log to stdout
    handler = logging.StreamHandler()
    handler.setFormatter(formatter)
    logger.addHandler(handler)

    logger.info('Script started')

    logger.info(f'Processing biosamples from: {biosample_file}')

    # Database Connection Pool Configuration
    DB_CONN_POOL_MIN = 5
    DB_CONN_POOL_MAX = 20

    # Database Connection Pool Initialization
    db_conn_pool = psycopg2.pool.SimpleConnectionPool(
        DB_CONN_POOL_MIN,
        DB_CONN_POOL_MAX,
        host="localhost",
        port=5433,
        dbname="biosample",
        user="biosample",
        password="biosample-password"
    )

    # Function to get a connection from the pool
    def get_connection():
        return db_conn_pool.getconn()

    # Function to release a connection back to the pool
    def release_connection(conn):
        db_conn_pool.putconn(conn)

    conn = get_connection()
    cur = conn.cursor()

    cur.execute("""
        CREATE TABLE IF NOT EXISTS ncbi_attributes_all_long (
            raw_id INTEGER,
            attribute_name TEXT,
            harmonized_name TEXT,
            display_name TEXT,
            unit TEXT,
            value TEXT
        )
    """)

    cur.execute("""
      CREATE TABLE IF NOT EXISTS non_attribute_metadata(
        id TEXT,
        accession TEXT,
        raw_id INTEGER PRIMARY KEY,
        primary_id TEXT,
        sra_id TEXT,
        bp_id TEXT,
        model TEXT,
        package TEXT,
        package_name TEXT,
        status TEXT,
        status_date TEXT,
        taxonomy_id TEXT,
        taxonomy_name TEXT,
        title TEXT,
        samp_name TEXT,
        paragraph TEXT
      )
    """)

    context = ET.iterparse(biosample_file, tag="BioSample")

    biosample_count = 0
    batch_num = 1

    path_counts = {}

    start_time = time.time()

    attributes_frame = pd.DataFrame(columns=["raw_id", "attribute_name", "harmonized_name", "display_name", "unit", "value"])

    for event, elem in context:
        if elem.tag == 'BioSample':
            root = ET.fromstring(ET.tostring(elem))

            def count_paths_with_text(node, path):
                if len(node) == 0:
                    path_str = "/".join(path)

                    if path_str not in path_counts:
                        path_counts[path_str] = {"count": 0, "attributes": {}, "text_count": 0, "attribute_values": {}}

                    path_counts[path_str]["count"] += 1

                    if node.text and node.text.strip():
                        path_counts[path_str]["text_count"] += 1

                    for key, value in node.attrib.items():
                        path_counts[path_str]["attributes"][key] = 1 + path_counts[path_str]["attributes"].get(key, 0)
                        if "/".join(path + [key]) in (
                                'BioSample/Ids/Id/db',
                                'BioSample/Ids/Id/db_label',
                                'BioSample/Ids/Id/is_hidden',
                                'BioSample/Ids/Id/is_primary',
                                'BioSample/Links/Link/label',
                                'BioSample/Links/Link/target',
                                'BioSample/Links/Link/type',
                        ):
                            if key not in path_counts[path_str]["attribute_values"]:
                                path_counts[path_str]["attribute_values"][key] = {}
                            if value not in path_counts[path_str]["attribute_values"][key]:
                                path_counts[path_str]["attribute_values"][key][value] = 1
                            else:
                                path_counts[path_str]["attribute_values"][key][value] += 1
                else:
                    for child in node:
                        count_paths_with_text(child, path + [child.tag])

            count_paths_with_text(root, [root.tag])

        if event == "end":
            biosample_count += 1

            if biosample_count > max_biosamples:
                logger.info(f'Reached max bio samples: {max_biosamples}')
                break

            if biosample_count % batch_size == 0:
                batch_start = batch_num * batch_size - batch_size + 1
                batch_end = min(biosample_count, max_biosamples)
                logger.info(
                    f'Processed {batch_start:,} to {batch_end:,} of {max_biosamples:,} biosamples ({batch_end / max_biosamples:.2%})')
                batch_num += 1

            raw_id = int(elem.attrib["id"])

            attributes_rows = [] # list of tuples. each tuple is about one attribute. the list is about one biosample.

            for attribute in elem.findall("Attributes/Attribute"):
                attribute_name = attribute.attrib["attribute_name"]
                display_name = attribute.attrib.get("display_name")
                harmonized_name = attribute.attrib.get("harmonized_name")
                unit = attribute.attrib.get("unit")
                value = attribute.text

                attributes_rows.append((raw_id, attribute_name, harmonized_name, display_name, unit, value))

            temp_frame = pd.DataFrame(attributes_rows, columns=["raw_id", "attribute_name", "harmonized_name", "display_name", "unit", "value"])
            # print(attributes_frame)
            # add temp_frame to attributes_frame
            attributes_frame = pd.concat([attributes_frame, temp_frame], ignore_index=True)
            # print(attributes_frame)

            cur.executemany("""
                INSERT INTO ncbi_attributes_all_long (raw_id, attribute_name, harmonized_name, display_name, unit, value)
                VALUES (%s, %s, %s, %s, %s, %s)
            """, attributes_rows)

            accession = str(elem.attrib["accession"])

            primary_ids = []
            prefixed_ids = []
            for id_elem in elem.findall('Ids/Id[@is_primary="1"]'):
                if id_elem.text:
                    primary_ids.append(id_elem.text)
                    prefixed_ids.append("BIOSAMPLE:" + id_elem.text)
            if len(primary_ids) > 0:
                primary_id = '|||'.join(primary_ids)
            else:
                primary_id = None
            if len(prefixed_ids) > 0:
                prefixed_id = '|||'.join(prefixed_ids)
            else:
                prefixed_id = None

            sra_ids = []
            for sra_id in elem.findall('Ids/Id[@db="SRA"]'):
                if sra_id.text:
                    sra_id = sra_id.text
                    sra_ids.append(sra_id)
            if len(sra_ids) > 0:
                sra_id = '|||'.join(sra_ids)
            else:
                sra_id = None

            bp_ids = []
            for bp_id in elem.findall('Links/Link[@type="entrez"][@target="bioproject"]'):
                if bp_id.text:
                    bp_id = bp_id.text
                    bp_ids.append(bp_id)
            if len(bp_ids) > 0:
                bp_id = '|||'.join(bp_ids)
            else:
                bp_id = None

            models = []
            for model in elem.findall('Models/Model'):
                if model.text:
                    model = model.text
                    models.append(model)
            if len(models) > 0:
                model = '|||'.join(models)
            else:
                model = None

            package_texts = []
            package_names = []
            for package in elem.findall('Package'):
                if package.text:
                    package_text = package.text
                    package_texts.append(package_text)
                if package.attrib.get('display_name'):
                    package_name = package.attrib.get('display_name')
                    package_names.append(package_name)
            if len(package_texts) > 0:
                package = '|||'.join(package_texts)
            else:
                package = None
            if len(package_names) > 0:
                package_name = '|||'.join(package_names)
            else:
                package_name = None

            statuses = []
            status_dates = []
            for status in elem.findall('Status'):
                if status.text:
                    status_status = status.attrib.get('status')
                    statuses.append(status_status)
                if status.attrib.get('when'):
                    status_date = status.attrib.get('when')
                    status_dates.append(status_date)
            if len(statuses) > 0:
                status = '|||'.join(statuses)
            else:
                status = None
            if len(status_dates) > 0:
                status_date = '|||'.join(status_dates)
            else:
                status_date = None

            taxonomy_ids = []
            taxonomy_names = []
            for taxonomy in elem.findall('Description/Organism'):
                if taxonomy.attrib.get('taxonomy_id'):
                    taxonomy_id = taxonomy.attrib.get('taxonomy_id')
                    taxonomy_ids.append(taxonomy_id)
                if taxonomy.attrib.get('taxonomy_name'):
                    taxonomy_name = taxonomy.attrib.get('taxonomy_name')
                    taxonomy_names.append(taxonomy_name)
            if len(taxonomy_ids) > 0:
                taxonomy_id = '|||'.join(taxonomy_ids)
            else:
                taxonomy_id = None
            if len(taxonomy_names) > 0:
                taxonomy_name = '|||'.join(taxonomy_names)
            else:
                taxonomy_name = None

            titles = []
            for title in elem.findall('Description/Title'):
                if title.text:
                    title = title.text
                    titles.append(title)
            if len(titles) > 0:
                title = '|||'.join(titles)
            else:
                title = None

            paragraph_texts = []
            for paragraph in elem.findall('Description/Comment/Paragraph'):
                if paragraph.text:
                    paragraph_text = paragraph.text
                    paragraph_texts.append(paragraph_text)
            if len(paragraph_texts) > 0:
                paragraph = '|||'.join(paragraph_texts)
            else:
                paragraph = None

            samp_names = []
            for samp_name in elem.findall('Ids/Id[@db_label="Sample name"]'):
                if samp_name.text:
                    samp_name = samp_name.text
                    samp_names.append(samp_name)
            if len(samp_names) > 0:
                samp_name = '|||'.join(samp_names)
            else:
                samp_name = None

            cur.execute("""
               INSERT INTO non_attribute_metadata
               (raw_id, accession, primary_id, id, sra_id, bp_id, model, package, package_name, status, status_date, taxonomy_id, taxonomy_name, title, samp_name, paragraph)
               VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
             """, (
                raw_id, accession, primary_id, prefixed_id, sra_id, bp_id, model, package, package_name, status,
                status_date, taxonomy_id, taxonomy_name, title, samp_name, paragraph))

            conn.commit()

            elem.clear()

    logger.info('Done parsing biosamples')

    conn.close()

    # Save the current time at the end of the loop
    end_time = time.time()

    # Calculate the difference
    elapsed_time = end_time - start_time

    # Print the difference
    print("Elapsed time:", elapsed_time, "seconds")

    def filter_attribute_values(path_counts):
        filtered_attribute_values = path_counts.copy()
        for path, path_data in filtered_attribute_values.items():
            if "attribute_values" in path_data and path_data["attribute_values"]:
                attributes_data = path_data.get("attributes", {})
                for attribute, values in list(path_data["attribute_values"].items()):
                    for value, count in list(values.items()):
                        if count / attributes_data[attribute] < 0.05:
                            del path_data["attribute_values"][attribute][value]
        return filtered_attribute_values

    filtered_path_counts = filter_attribute_values(path_counts)

    sorted_paths = {path: filtered_path_counts[path] for path in sorted(filtered_path_counts.keys())}

    yaml_string = yaml.dump(sorted_paths, default_flow_style=False)
    with open("path_counts.yaml", "w") as f:
        f.write(yaml_string)

    logger.info('Done parsing biosamples')


if __name__ == '__main__':
    main()
