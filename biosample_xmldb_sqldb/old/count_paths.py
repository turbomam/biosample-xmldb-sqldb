import xml.etree.ElementTree as ET
from collections import defaultdict


# Function to extract paths from an element and its descendants
def extract_paths(element, current_path="", paths=None):
    if paths is None:
        paths = defaultdict(int)

    # Combine the current tag with its parent's path
    current_path += "/{}".format(element.tag)

    # Update the count for this path
    paths[current_path] += 1

    # Recursively process children
    for child in element:
        extract_paths(child, current_path, paths)

    return paths


# Open the XML file for streaming parsing
with open("../downloads/biosample_set.xml", "rb") as f:
    paths_count = defaultdict(int)
    biosample_counter = 0
    max_biosamples = 10  # Set the maximum number of biosamples to process

    # Iterate over each element in the XML file
    for event, element in ET.iterparse(f, events=("start",)):
        # print(element.tag)
        # If the element is a Biosample, extract paths and update counts
        if element.tag == "Biosample":
            biosample_counter += 1
            if biosample_counter > max_biosamples:
                break

            paths = extract_paths(element)
            print(paths)
            for path, count in paths.items():
                paths_count[path] += count

# Print the counts
for path, count in paths_count.items():
    print(f"{path}: {count} times")
