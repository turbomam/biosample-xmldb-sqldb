import lxml.etree as ET
import psycopg2
import psycopg2.pool
from concurrent.futures import ThreadPoolExecutor
import logging

MAX_BIOSAMPLES = 500_000
BATCH_SIZE = 10_000
biosample_file = "../downloads/biosample_set.xml"

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

# Connection Pooling
conn_pool = psycopg2.pool.ThreadedConnectionPool(
    minconn=1,
    maxconn=5,
    dbname="biosample",
    user="biosample",
    password="biosample-password",
    host="localhost",
    port=5433
)

path_counts = {}


def count_paths_with_text(node, path):
    """
    Count the paths with text value recursively.
    """
    nonlocal path_counts

    if len(node) == 0:
        path_str = "/".join(path)

        if path_str not in path_counts:
            path_counts[path_str] = {"count": 0, "attributes": {}, "text_count": 0}

        path_counts[path_str]["count"] += 1

        # Check if the node has text
        if node.text and node.text.strip():
            path_counts[path_str]["text_count"] += 1

        for key, value in node.attrib.items():
            path_counts[path_str]["attributes"][key] = 1 + path_counts[path_str]["attributes"].get(key, 0)

    else:
        for child in node:
            count_paths_with_text(child, path + [child.tag])


def process_biosample_batch(batch):
    conn = conn_pool.getconn()
    cur = conn.cursor()

    rows_ncbi_attributes = []
    rows_non_attribute_metadata = []

    for elem in batch:
        # Your existing processing code here
        # (removed for brevity)

        # Update path_counts
        if elem.tag == 'BioSample':
            root = ET.fromstring(ET.tostring(elem))
            count_paths_with_text(root, [root.tag])

    # Bulk inserts and commit
    # You need to adapt this section based on your actual insert statements and data
    # Here, I'm assuming rows_ncbi_attributes and rows_non_attribute_metadata contain the data to insert
    if rows_ncbi_attributes:
        cur.executemany("""
            INSERT INTO ncbi_attributes_all_long (raw_id, attribute_name, harmonized_name, display_name, unit, value)
            VALUES (%s, %s, %s, %s, %s, %s)
        """, rows_ncbi_attributes)

    if rows_non_attribute_metadata:
        cur.executemany("""
            INSERT INTO non_attribute_metadata 
            (raw_id, accession, primary_id, id, sra_id, bp_id, model, package, package_name, status, status_date, taxonomy_id, taxonomy_name, title, samp_name, paragraph)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, rows_non_attribute_metadata)

    conn.commit()
    conn_pool.putconn(conn)


with ThreadPoolExecutor(max_workers=5) as executor:
    context = ET.iterparse(biosample_file, tag="BioSample")
    biosample_batch = []

    biosample_count = 0

    for event, elem in context:
        # Your existing parsing code here
        # (removed for brevity)

        if biosample_count >= MAX_BIOSAMPLES:
            logger.info(f'Reached max bio samples: {MAX_BIOSAMPLES}')
            break

        # Add element to batch
        biosample_batch.append(elem)

        if len(biosample_batch) >= BATCH_SIZE:
            executor.submit(process_biosample_batch, biosample_batch)
            biosample_batch = []

        if event == "end":
            biosample_count += 1
            elem.clear()

# Display sorted paths
sorted_paths = sorted(path_counts.items(), key=lambda x: x[0])

pprint.pprint(sorted_paths)

logger.info('Done parsing biosamples')
