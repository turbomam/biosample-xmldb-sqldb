import click
import pandas as pd
from sqlalchemy import create_engine, text
from datetime import datetime


@click.command()
@click.option('--bp-id', required=True, help='Numeric BioProject id')
@click.option('--values-from', default='harmonized_name', type=click.Choice(['attribute_name', 'harmonized_name']),
              help='Should the pivot table contain harmonized_names or attribute_names?')
@click.option('--output', default='wide_for_bioproject.tsv', help='Output file name')
def main(bp_id, values_from, output):
    conn_string = "postgresql://biosample:biosample-password@localhost:5433/biosample"
    engine = create_engine(conn_string)

    with engine.connect() as conn:
        sql = f"""select
            nam.*
        from
            non_attribute_metadata nam
        where
            bp_id = '{bp_id}';"""

        non_attribute_result = conn.execute(text(sql)).fetchall()

        non_attribute_frame = pd.DataFrame(non_attribute_result)

        sql = f"""select
            anal.raw_id ,
            anal.{values_from} ,
            anal.value
        from
            non_attribute_metadata nam
        left join all_ncbi_attributes_long anal on
            nam.raw_id = anal.raw_id
        where
            bp_id = '{bp_id}';"""  # 30 + seconds. needs better indexing?

        click.echo(f"{datetime.now().isoformat()}")

        long_result = conn.execute(text(sql)).fetchall()

        click.echo(f"{datetime.now().isoformat()}")

        long_frame = pd.DataFrame(long_result, columns=["raw_id", values_from, "value"])

        wide_frame = long_frame.pivot_table(
            index="raw_id",
            columns=values_from,
            values="value",
            aggfunc=lambda x: "|||".join(x.dropna()),
            fill_value=""
        )

        wide_frame = wide_frame[sorted(wide_frame.columns)]

        joined_frame = non_attribute_frame.join(wide_frame, on="raw_id", how="outer")

        joined_frame.to_csv(output, sep="\t", index=False)
        click.echo(f"Output written to {output}")


if __name__ == '__main__':
    main()
