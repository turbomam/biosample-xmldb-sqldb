import logging
import time
from datetime import datetime
import pprint
import pandas as pd
from sqlalchemy import create_engine, text

# Configure logging
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger(__name__)

last_id_expected = 40_000_000
# last_id_expected = 100_000
ids_per_chunk = 10_000

# Define the table name
write_table = 'ncbi_attributes_harmonized_wide'

# Define the connection
db_settings = {
    "host": "localhost",
    "port": 5433,
    "dbname": "biosample",
    "user": "biosample",
    "password": "biosample-password"
}


def add_unit(row):
    if pd.isnull(row['unit']) or row['unit'] == '':
        return str(row['value'])
    else:
        return str(row['value']) + ' ' + str(row['unit'])


# Construct the connection string
connection_string = f"postgresql://{db_settings['user']}:{db_settings['password']}@{db_settings['host']}:{db_settings['port']}/{db_settings['dbname']}"

# Create the SQLAlchemy engine
engine = create_engine(connection_string)

# Get current datetime before executing the query
start_time = datetime.now().isoformat()
logger.info(f"Start finding harmonized_names")

harmonized_names = []

# Query distinct harmonized names
query = text("""
    SELECT DISTINCT harmonized_name
    FROM ncbi_attributes_all_long naal
    WHERE harmonized_name IS NOT NULL
    ORDER BY harmonized_name
""")

with engine.connect() as connection:
    results = connection.execute(query)
    for row in results:
        harmonized_names.append(row[0])

# Get current datetime after executing the query
end_time = datetime.now().isoformat()
logger.info(f"Done finding harmonized_names")

# logger.info("Harmonized Names:")
# pprint.pprint(harmonized_names)

# Construct the DROP TABLE query
drop_table_query = f"DROP TABLE IF EXISTS {write_table}"

# Execute the DROP TABLE query
with engine.connect() as connection:
    connection.execute(text(drop_table_query))
    connection.commit()
    logger.info(f"Dropped table {write_table}")

# Construct the CREATE TABLE query dynamically
create_table_query = f"""
    CREATE TABLE IF NOT EXISTS {write_table} (
        raw_id INTEGER PRIMARY KEY,
        {", ".join(f'"{name}" TEXT' for name in harmonized_names)}
    )
"""

try:
    # Execute the CREATE TABLE query
    with engine.connect() as connection:
        connection.execute(text(create_table_query))
        # Commit the transaction
        connection.commit()
    logger.info("Table created successfully!")
except Exception as e:
    logger.error(f"Error creating table: {e}")

# Process data in chunks
for start_id in range(1, last_id_expected, ids_per_chunk):
    end_id = min(start_id + ids_per_chunk - 1, last_id_expected)
    logger.info(
        f"Processing through raw_id {start_id:,} of {last_id_expected:,} ({start_id / last_id_expected:.1%} complete)")

    # Construct and execute query to retrieve chunk
    query = text(f"""SELECT raw_id, harmonized_name, value, unit
    FROM ncbi_attributes_all_long 
    WHERE raw_id > {start_id} 
    AND raw_id <= {end_id} 
    AND harmonized_name is not null""")

    with engine.connect() as connection:
        results = connection.execute(query)
        chunk_results = pd.DataFrame(results.fetchall(), columns=results.keys())
        chunk_results['with_unit'] = chunk_results.apply(add_unit, axis=1)
        pivot_df = chunk_results.pivot_table(index='raw_id', columns='harmonized_name', values='with_unit',
                                             aggfunc=lambda x: '|||'.join(str(v) for v in x))

    # logger.info(pivot_df)

    # Insert DataFrame into database using to_sql()
    pivot_df.to_sql(name=write_table, con=engine, if_exists='append', index=True, index_label='raw_id')
