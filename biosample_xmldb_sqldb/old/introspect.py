from sqlalchemy import MetaData, create_engine, Table

# Define your PostgreSQL database connection settings
db_settings = {
    "host": "localhost",
    "port": 5433,
    "dbname": "biosample",
    "user": "biosample",
    "password": "biosample-password"
}

# Construct the connection string
connection_string = f"postgresql://{db_settings['user']}:{db_settings['password']}@{db_settings['host']}:{db_settings['port']}/{db_settings['dbname']}"

# Create a SQLAlchemy engine
engine = create_engine(connection_string)

# Reflect the existing table
metadata = MetaData()
table_name = 'non_attribute_metadata'  # Replace 'existing_table' with the name of your existing table
reflected_table = Table(table_name, metadata, autoload_with=engine)

# Generate Python code to recreate the table definition
python_code = f"from sqlalchemy import Table, Column, {reflected_table.__class__.__name__}, MetaData\n\n"
python_code += f"metadata = MetaData()\n\n"
python_code += f"{table_name} = Table('{table_name}', metadata,\n"

for column in reflected_table.columns:
    python_code += f"    Column('{column.name}', {repr(column.type)}, "
    if column.primary_key:
        python_code += "primary_key=True"
    python_code += "),\n"

python_code += ")\n"

print(python_code)