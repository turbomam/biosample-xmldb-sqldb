import pandas as pd
from sqlalchemy import create_engine, text, inspect

# todo add a click cli

conn_string = "postgresql://biosample:biosample-password@localhost:5433/biosample"

engine = create_engine(conn_string)

chunk_size = 100000
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
            write_chunk_size = int(chunk_size / 10)
            if not pivoted_data.empty:
                print(f"{pivoted_data.shape = }")
                print(f"No more data to read. Writing to database.")  # in chunks of {write_chunk_size}
                sorted_cols = sorted(pivoted_data.columns[1:])
                pivoted_data = pivoted_data[sorted_cols]
                pivoted_data.to_csv("harmonized_attributes_wide.tsv", sep="\t", index=True)

                table_name = 'harmonized_attributes_wide'

                # Calculate number of chunks
                num_chunks = int(-(-len(pivoted_data) // (chunk_size / 3)))  # Round up division
                print(f"{num_chunks = }")

                # Iterate over DataFrame in chunks and write to SQL table
                for i in range(num_chunks):
                    print(f"Writing chunk {i + 1} of {num_chunks}")
                    start_idx = i * chunk_size
                    end_idx = (i + 1) * chunk_size
                    chunk_df = pivoted_data.iloc[start_idx:end_idx]
                    chunk_df.to_sql(
                        table_name,
                        engine,
                        index=True,
                        if_exists='append'
                    )

                # indexed by default since there's only one integer colum?

                sql = f"CREATE INDEX idx_raw_id ON {table_name} (raw_id)"
                print(sql)
                # conn.execute(text(sql))

                # Create a view joining non_attribute_metadata with the new table
                view_name = 'attributes_pus_view'
                sql = f"""CREATE VIEW {view_name} AS
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
                             FULL OUTER JOIN {table_name} ON non_attribute_metadata.raw_id = {table_name}.raw_id"""
                print(sql)
                conn.execute(text(sql))

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
