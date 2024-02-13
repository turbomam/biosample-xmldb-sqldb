import os
import click
import logging
from datetime import datetime

# expect ~ 35 000 000 biosamples
# want ~ 30 chunks
# start with more, smaller chunks

openers_to_write = ['<?xml version="1.0" encoding="UTF-8"?>\n', '<BioSampleSet>\n']
closer_to_write = '</BioSampleSet>\n'
file_prefix = 'biosample_set_from_'
opening_trigger = '</BioSample>'

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

def create_output_file(output_dir, biosamples_seen):
    """Create and return a new output file."""
    filename = os.path.join(output_dir, f"{file_prefix}{biosamples_seen}.xml")
    return open(filename, "w")

def process_input_file(input_file_name, output_dir, biosamples_per_file, last_biosample):
    """Process the input file and chunk it into smaller files."""
    biosamples_seen = 0
    last_biosample = int(last_biosample) if last_biosample else None
    smallfile = None

    logger.info(f"Script started at {datetime.now().time()}")

    try:
        with open(input_file_name) as bigfile:
            for lineno, line in enumerate(bigfile):
                offset = biosamples_seen % biosamples_per_file

                if not smallfile:
                    smallfile = create_output_file(output_dir, biosamples_seen)
                    for i in openers_to_write:
                        smallfile.write(i)

                if not (line.startswith("<?xml") or line.startswith("<BioSampleSet>") or line.startswith("</BioSampleSet>")):
                    smallfile.write(line)

                if line.startswith(opening_trigger):
                    biosamples_seen += 1
                    if offset == 0 and biosamples_seen > 1:
                        logger.info(f"{datetime.now().time()} ... {biosamples_seen} complete biosamples have been seen as of line #{lineno}. Active output file = {smallfile.name}")
                        smallfile.write(closer_to_write)
                        smallfile.close()
                        smallfile = create_output_file(output_dir, biosamples_seen)
                        for i in openers_to_write:
                            smallfile.write(i)

                if last_biosample and biosamples_seen >= last_biosample:
                    logger.info(f"Stopping here because {last_biosample} or more biosamples have been processed.")
                    if smallfile:
                        smallfile.write(closer_to_write) # todo if we've reached the end of the file then "</BioSampleSet>" needs to be appended too
                        smallfile.close()
                    break

    except Exception as e:
        logger.error(f"An error occurred: {str(e)}")

    finally:
        if smallfile:
            smallfile.close()

@click.command()
@click.option('--input-file-name', required=True, type=click.Path(exists=True),
              help='un-packed NCBI biosample set XML file')
@click.option('--output-dir', required=True, type=click.Path(exists=True),
              help='destination for smaller BioSampleSet XML files')
@click.option('--biosamples-per-file', default=300000, help='Number of biosamples to put in each output file.')
@click.option('--last-biosample', help='Stop after this many biosamples have been written to output files.')
def cli(input_file_name, biosamples_per_file, last_biosample, output_dir):
    """Chunks the NCBI biosample set into smaller but valid BioSampleSet XML files."""
    process_input_file(input_file_name, output_dir, biosamples_per_file, last_biosample)

if __name__ == '__main__':
    cli()
