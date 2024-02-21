import time

import click
import pprint

import pandas as pd

from sqlalchemy import create_engine, text

# last_id_expected = 40_000_000
last_id_expected = 5
ids_per_chunk = 2

# Define the connection string
db_settings = {
    "host": "ec2-3-19-76-231.us-east-2.compute.amazonaws.com",
    "port": 5432,
    "dbname": "biosample",
    "user": "biosample",
    "password": "biosample-password"
}

# Construct the connection string
connection_string = f"postgresql://{db_settings['user']}:{db_settings['password']}@{db_settings['host']}:{db_settings['port']}/{db_settings['dbname']}"

# Create the SQLAlchemy engine
engine = create_engine(connection_string)

for start_id in range(1, last_id_expected, ids_per_chunk):
    end_id = min(start_id + ids_per_chunk - 1, last_id_expected)
    query = text(f"SELECT * FROM ncbi_attributes_all_long WHERE raw_id > {start_id} AND raw_id <= {end_id} LIMIT 3")
    # print(query)
    with engine.connect() as connection:
        results = connection.execute(query)
        chunk_results = pd.DataFrame(results.fetchall(), columns=results.keys())
        print(chunk_results)
    # all_results = pd.concat([all_results, chunk_results], ignore_index=True)
