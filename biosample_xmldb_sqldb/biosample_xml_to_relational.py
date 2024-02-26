import logging
import os
import time

import click
import lxml.etree as ET
import pandas as pd
import yaml
from dotenv import load_dotenv
from sqlalchemy import create_engine

# Load environment variables from local/.env file
dotenv_path = os.path.join("local", ".env")
load_dotenv(dotenv_path)

# Define the connection string
DB_SETTINGS = {
    "host": os.getenv("DB_HOST"),
    "port": int(os.getenv("DB_PORT")),
    "dbname": os.getenv("DB_NAME"),
    "user": os.getenv("DB_USER"),
    "password": os.getenv("DB_PASSWORD")
}

# Construct the connection string
CONNECTION_STRING = f"postgresql://{DB_SETTINGS['user']}:{DB_SETTINGS['password']}@{DB_SETTINGS['host']}:{DB_SETTINGS['port']}/{DB_SETTINGS['dbname']}"

# Create the SQLAlchemy engine
engine = create_engine(CONNECTION_STRING)

path_counts = {}


def filter_attribute_values(path_counts):
    filtered_common_attribute_values = path_counts.copy()
    for path, path_data in filtered_common_attribute_values.items():
        if "common_attribute_values" in path_data and path_data["common_attribute_values"]:
            attributes_data = path_data.get("attributes", {})
            for attribute, values in list(path_data["common_attribute_values"].items()):
                for value, count in list(values.items()):
                    if count / attributes_data[attribute] < 0.05:
                        del path_data["common_attribute_values"][attribute][value]
    return filtered_common_attribute_values


def count_paths_with_text(node, path):
    if len(node) == 0:
        path_str = "/".join(path)

        if path_str not in path_counts:
            path_counts[path_str] = {"count": 0, "attributes": {}, "text_count": 0, "common_attribute_values": {}}

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
                if key not in path_counts[path_str]["common_attribute_values"]:
                    path_counts[path_str]["common_attribute_values"][key] = {}
                if value not in path_counts[path_str]["common_attribute_values"][key]:
                    path_counts[path_str]["common_attribute_values"][key][value] = 1
                else:
                    path_counts[path_str]["common_attribute_values"][key][value] += 1
    else:
        for child in node:
            count_paths_with_text(child, path + [child.tag])


@click.command()
@click.option('--biosample-file', type=str, default="../downloads/biosample_set.xml",
              help='Path to the BioSample XML file.')
@click.option('--max-biosamples', type=int, default=50_000_000, help='Maximum number of biosamples to process.')
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

    context = ET.iterparse(biosample_file, tag="BioSample")

    biosample_count = 0
    batch_num = 1

    start_time = time.time()

    attributes_frame = pd.DataFrame(
        columns=["raw_id", "attribute_name", "harmonized_name", "display_name", "unit", "value"])

    non_attribute_frame = pd.DataFrame()

    for event, elem in context:
        if elem.tag == 'BioSample':
            root = ET.fromstring(ET.tostring(elem))

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
                    f'Processed {batch_start:,} to {batch_end:,} of {max_biosamples:,} requested BioSamples ({batch_end / max_biosamples:.2%})')
                batch_num += 1
                attributes_frame.to_sql("ncbi_attributes_all_long", engine, if_exists="append", index=False)
                attributes_frame = pd.DataFrame(
                    columns=["raw_id", "attribute_name", "harmonized_name", "display_name", "unit", "value"])
                non_attribute_frame.to_sql("non_attribute_metadata", engine, if_exists="append", index=False)
                non_attribute_frame = pd.DataFrame()

            raw_id = int(elem.attrib["id"])

            attributes_rows = []  # list of tuples. each tuple is about one attribute. the list is about one biosample.

            for attribute in elem.findall("Attributes/Attribute"):
                attribute_name = attribute.attrib["attribute_name"]
                display_name = attribute.attrib.get("display_name")
                harmonized_name = attribute.attrib.get("harmonized_name")
                unit = attribute.attrib.get("unit")
                value = attribute.text

                attributes_rows.append((raw_id, attribute_name, harmonized_name, display_name, unit, value))

            temp_frame = pd.DataFrame(attributes_rows,
                                      columns=["raw_id", "attribute_name", "harmonized_name", "display_name", "unit",
                                               "value"])

            attributes_frame = pd.concat([attributes_frame, temp_frame], ignore_index=True)

            accession = str(elem.attrib["accession"])
            prefixed_id = f"BIOSAMPLE:{accession}"

            primary_ids = []
            for id_elem in elem.findall('Ids/Id[@is_primary="1"]'):
                if id_elem.text:
                    primary_ids.append(id_elem.text)
            if len(primary_ids) > 0:
                primary_id = '|||'.join(primary_ids)
            else:
                primary_id = None

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

            synonyms = []
            for synonym in elem.findall('Description/Synonym'):
                synonym_db = ""
                synonym_text = ""
                if synonym.text:
                    synonym_text = synonym.text
                if synonym.attrib.get('db'):
                    synonym_db = synonym.attrib.get('db')
                synonyms.append(f"{synonym_db}:{synonym_text}")
            if len(synonyms) > 0:
                synonym = '|||'.join(synonyms)
            else:
                synonym = None

            owner_abbreviations = []
            owner_texts = []
            owner_urls = []
            for owner in elem.findall('Owner/Name'):
                if owner.text:
                    owner_texts.append(owner.text)
                if owner.attrib.get('url'):
                    owner_urls.append(owner.attrib.get('url'))
                if owner.attrib.get('abbreviation'):
                    owner_abbreviations.append(owner.attrib.get('abbreviation'))
            if len(owner_abbreviations) > 0:
                owner_abbreviation = '|||'.join(owner_abbreviations)
            else:
                owner_abbreviation = None
            if len(owner_texts) > 0:
                owner_text = '|||'.join(owner_texts)
            else:
                owner_text = None
            if len(owner_urls) > 0:
                owner_url = '|||'.join(owner_urls)
            else:
                owner_url = None

            table_captions = []
            for caption in elem.findall('Description/Comment/Table/Caption'):
                if caption.text:
                    table_captions.append(caption.text)
            if len(table_captions) > 0:
                table_caption = '|||'.join(table_captions)
            else:
                table_caption = None

            # # Count the number of Contact nodes
            # contact_nodes = elem.findall('Owner/Contacts/Contact')
            # num_contacts = len(contact_nodes)
            # print(f"Number of Contact nodes: {num_contacts}")

            contributor_name_cats = set()
            for contact in elem.findall('Owner/Contacts/Contact'):
                pretty_contact = ET.tostring(contact, encoding='unicode', method='xml', pretty_print=True)

                # Extract values
                first_name = contact.findtext('Name/First', default='')
                middle_name = contact.findtext('Name/Middle', default='')
                last_name = contact.findtext('Name/Last', default='')
                lab = contact.get('lab', '')
                email = contact.get('email', '')

                # Concatenate the components
                name_and_lab = ' '.join(filter(None, [first_name, middle_name, last_name, lab, email]))

                # Store the result
                contributor_name_cats.add(name_and_lab)

                # # Print the result
                # print(f"Individually: {name_and_lab}")

            # # Print the collected strings
            # print(len(contributor_name_cats))
            # for name_and_lab in contributor_name_cats:
            #     print(f"From concatenation: {name_and_lab}")
            # make a contributors string by concatenating the elements of contributor_name_cats with "|||"
            contributors = "|||".join(contributor_name_cats)

            elem.clear()

            non_attribute_dict = {
                "raw_id": raw_id,
                "accession": accession,
                "bp_id": bp_id,
                "contributors": contributors,
                "model": model,
                "owner_abbreviation": owner_abbreviation,
                "owner_text": owner_text,
                "owner_url": owner_url,
                "package": package,
                "package_name": package_name,
                "paragraph": paragraph,
                "prefixed_id": prefixed_id,
                "primary_id": primary_id,
                "samp_name": samp_name,
                "sra_id": sra_id,
                "status": status,
                "status_date": status_date,
                "synonym": synonym,
                "table_caption": table_caption,
                "taxonomy_id": taxonomy_id,
                "taxonomy_name": taxonomy_name,
                "title": title,
            }

            # add non_attribute_dict to non_attribute_frame
            non_attribute_frame = pd.concat([non_attribute_frame, pd.DataFrame([non_attribute_dict])])

    attributes_frame.to_sql("ncbi_attributes_all_long", engine, if_exists="append", index=False)
    non_attribute_frame.to_sql("non_attribute_metadata", engine, if_exists="append", index=False)

    logger.info('Done parsing biosamples')

    # Save the current time at the end of the loop
    end_time = time.time()

    # Calculate the difference
    elapsed_time = end_time - start_time

    # Print the difference
    print("Elapsed time:", elapsed_time, "seconds")

    filtered_path_counts = filter_attribute_values(path_counts)

    sorted_paths = {path: filtered_path_counts[path] for path in sorted(filtered_path_counts.keys())}

    # dump the sorted paths to a yaml file
    with open("path_counts.yaml", "w") as f:
        yaml.dump(sorted_paths, f, default_flow_style=False)

    logger.info('Done parsing biosamples')


if __name__ == '__main__':
    main()
