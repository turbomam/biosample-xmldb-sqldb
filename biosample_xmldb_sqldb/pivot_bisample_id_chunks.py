import time

import click
import pprint

import pandas as pd

from sqlalchemy import create_engine, text

last_id_expected = 40_000_000
# last_id_expected = 100_000
ids_per_chunk = 10_000

# Define the connection
db_settings = {
    "host": "ec2-3-19-76-231.us-east-2.compute.amazonaws.com",
    "port": 5433,
    "dbname": "biosample",
    "user": "biosample",
    "password": "biosample-password"
}


# Function to concatenate value and unit
def add_unit(row):
    if pd.isnull(row['unit']) or row['unit'] == '':
        return str(row['value'])
    else:
        return str(row['value']) + ' ' + str(row['unit'])


# Construct the connection string
connection_string = f"postgresql://{db_settings['user']}:{db_settings['password']}@{db_settings['host']}:{db_settings['port']}/{db_settings['dbname']}"

# Create the SQLAlchemy engine
engine = create_engine(connection_string)

cumulative_results = pd.DataFrame()

for start_id in range(1, last_id_expected, ids_per_chunk):
    end_id = min(start_id + ids_per_chunk - 1, last_id_expected)
    print(f"Processing through raw_id {start_id} of {last_id_expected}")
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
        # # print out the maximum raw)id value for pivot_df
        # print(f"{pivot_df.index.max() = }")

        cumulative_results = pd.concat([cumulative_results, pivot_df], ignore_index=False)
        # print(f"{cumulative_results.index.max() = }")

cumulative_results = cumulative_results.reindex(sorted(cumulative_results.columns), axis=1)
# print(f"{cumulative_results.index.max() = }")

cumulative_results.to_csv("harmonized_attributes_wide.tsv", sep="\t", index=True)

# cumulative_results.to_sql("ncbi_attributes_harmonized_wide", engine, if_exists="append", index=True)

# Calculate the total number of chunks needed
total_chunks = (cumulative_results.shape[0] - 1) // ids_per_chunk + 1

# Iterate over chunks and write them to the database
for i in range(total_chunks):
    print(f"Writing chunk {i + 1} of {total_chunks}")
    start_idx = i * ids_per_chunk
    end_idx = min((i + 1) * ids_per_chunk, cumulative_results.shape[0])
    chunk_df = cumulative_results.iloc[start_idx:end_idx]
    # Write the chunk to the database
    chunk_df.to_sql('ncbi_attributes_harmonized_wide', con=engine, if_exists='append', index=True)
