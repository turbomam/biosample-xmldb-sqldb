import pandas as pd
from sqlalchemy import create_engine, text, inspect
import os

# todo add a click cli

conn_string = "postgresql://biosample:biosample-password@localhost:5433/biosample"

destination_table_name = 'harmonized_attributes_wide'
new_view_name = 'attributes_plus_view'
view_creation_file = 'create_view.sql'

view_creation_directory = "sql"
os.makedirs(view_creation_directory, exist_ok=True)
view_creation_path = os.path.join(view_creation_directory, view_creation_file)

engine = create_engine(conn_string)

chunk_size = 1000000
write_chunk_scale_factor = 1
offset = 0

pivoted_data = pd.DataFrame()

with engine.connect() as conn:
    inspector = inspect(engine)
    accessible_tables = inspector.get_table_names()
    print(f"{accessible_tables = }")

    while True:
        print(f"Processing through row {offset}")

        sql = text(
            f"""SELECT raw_id, harmonized_name, value FROM all_ncbi_attributes_long LIMIT {chunk_size} OFFSET {offset}""")

        chunk = conn.execute(sql).fetchall()
        offset = offset + chunk_size

        if not chunk:
            write_chunk_size = int(chunk_size / write_chunk_scale_factor)
            if not pivoted_data.empty:
                print(f"{pivoted_data.shape = }")
                print(f"No more data to read. Writing to database.")  # in chunks of {write_chunk_size}
                sorted_cols = sorted(pivoted_data.columns[1:])
                pivoted_data = pivoted_data[sorted_cols]
                # pivoted_data.to_csv("harmonized_attributes_wide.tsv", sep="\t", index=True)

                # Calculate number of chunks
                num_chunks = int(-(-len(pivoted_data) // write_chunk_size))  # Round up division
                print(f"{num_chunks = }")

                # Iterate over DataFrame in chunks and write to SQL table
                for i in range(num_chunks):
                    print(f"Writing chunk {i + 1} of {num_chunks}")
                    start_idx = i * chunk_size
                    end_idx = (i + 1) * chunk_size
                    chunk_df = pivoted_data.iloc[start_idx:end_idx]
                    chunk_df.to_sql(
                        destination_table_name,
                        engine,
                        index=True,
                        if_exists='append'
                    )

                # Create a view joining non_attribute_metadata with the new table
                # write that to a file, 
                # so it can be executed in the Maekfile, outside of this python script
                # harcoding the non_attribute_metadata columns because a select * query
                # 

                sql = f"""CREATE VIEW {new_view_name} AS
                             select
                             id,
                             accession,
                             primary_id,
                             sra_id,
                             bp_id,
                             model,
                             package,
                             package_name,
                             status,
                             status_date,
                             taxonomy_id,
                             taxonomy_name,
                             title,
                             samp_name,
                             paragraph,
                             harmonized_attributes_wide.*
                             FROM non_attribute_metadata 
                             FULL OUTER JOIN {destination_table_name} ON non_attribute_metadata.raw_id = {destination_table_name}.raw_id"""


                sql.encode('utf-8')
                with open(view_creation_path, "w") as f:
                    f.write(sql)

            else:
                print("No data to write")
            break

        chunk_df = pd.DataFrame(chunk, columns=["raw_id", "harmonized_name", "value"])
        pivoted_chunk = chunk_df.pivot_table(
            index="raw_id",
            columns="harmonized_name",
            values="value",
            aggfunc=lambda x: "|||".join(x.dropna()),
            fill_value=""
        )

        pivoted_data = pd.concat([pivoted_data, pivoted_chunk])
        print(f"{pivoted_data.shape = }")
