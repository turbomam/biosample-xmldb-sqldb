from urllib.parse import urlencode
from Bio import Entrez

Entrez.email = "MAM@lbl.gov"
handle = Entrez.esummary(db="pubmed", id="19304878,14630660", retmode="xml")
records = Entrez.parse(handle)
for record in records:
    # each record is a Python dictionary or list.
    print(record['Title'])

#
# # # Set API key and database
# # Entrez.email = "your_email@example.com"  # Replace with your NCBI email
# # Entrez.api_key = "your_api_key"  # Replace with your NCBI API key
# db = "biosample"
#
# # Define search parameters
# params = {
#     "term": "bioproject[PRJNA656268]",
#     "retmode": "text",
#     "rettype": "uid",
#     "sort": "accession",
# }
#
# # URL encode parameters
# url = "https://eutils.ncbi.nlm.nih.gov/entrez/eutils/" + db + ".fcgi?" + urlencode(params)
#
# # Fetch data and parse
# handle = Entrez.urlopen(url)
# data = handle.read()
# handle.close()
#
# # Extract biosample identifiers
# biosample_ids = []
# for line in data.splitlines():
#     if line.startswith("BS"):
#         biosample_ids.append(line.split("=")[1])
#
# # Print or use the list of biosample identifiers
# print(f"Biosample identifiers for PRJNA656268: {biosample_ids}")
