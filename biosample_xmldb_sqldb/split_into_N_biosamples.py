import os

import click

from datetime import datetime

# todo use logging not print statements

# todo refactor esp repetitive sections
#   also, not writing last split after hitting last_biosample

openers_to_write = ['<?xml version="1.0" encoding="UTF-8"?>\n', '<BioSampleSet>\n']
closer_to_write = '</BioSampleSet>\n'
file_prefix = 'biosample_set_from_'
opening_trigger = '</BioSample>'


@click.command()
@click.option('--input-file-name', required=True, type=click.Path(exists=True),
              help='un-packed NCBI biosample set XML file')
@click.option('--output-dir', required=True, type=click.Path(exists=True),
              help='destination for smaller BioSampleSet XML files')
@click.option('--biosamples-per-file', default=300000, help='Number of biosamples to put in each output file.')
@click.option('--last-biosample', help='Stop after this many biosamples have been written to output files.')
def cli(input_file_name, biosamples_per_file, last_biosample, output_dir):
    """Chunks the NCBI biosample set into smaller but valid BioSampleSet XML files."""
    biosamples_seen = 0
    last_biosample = int(last_biosample) if last_biosample else None
    # expect ~ 30 000 000 biosamples
    # want ~ 10 chunks
    # start with more, smaller chunks
    smallfile = None
    print(f"{datetime.now().time()}")
    with open(input_file_name) as bigfile:
        for lineno, line in enumerate(bigfile):
            if not smallfile:
                small_filename = os.path.join(output_dir, f"{file_prefix}{biosamples_seen}.xml")
                smallfile = open(small_filename, "w")
                for i in openers_to_write:
                    smallfile.write(i)
            offset = biosamples_seen % biosamples_per_file
            # print(
            #     f"{biosamples_seen} complete biosamples have been seen as of line #{lineno}. For chunks of {biosamples_per_file}, the modulo is {offset}. Active output file =  {small_filename}")
            if not (line.startswith("<?xml") or line.startswith("<BioSampleSet>") or line.startswith(
                    "</BioSampleSet>")):
                smallfile.write(line)
            if line.startswith(opening_trigger):
                biosamples_seen += 1
                if offset == 0 and biosamples_seen > 1:

                    print(
                        f"{datetime.now().time()} ... {biosamples_seen} complete biosamples have been seen as of line #{lineno}. For chunks of {biosamples_per_file}, the modulo is {offset}. Active output file =  {small_filename}")

                    smallfile.write(closer_to_write)
                    smallfile.close()
                    if last_biosample and biosamples_seen >= last_biosample:
                        print(f"Stopping here because {last_biosample} or more biosamples have been processed.")
                        break
                    small_filename = os.path.join(output_dir, f"{file_prefix}{biosamples_seen}.xml")
                    smallfile = open(small_filename, "w")
                    for i in openers_to_write:
                        smallfile.write(i)
        if smallfile:
            print(
                f"{biosamples_seen} complete biosamples have been seen as of line #{lineno}. For chunks of {biosamples_per_file}, the modulo is {offset}. Final output file =  {small_filename}")
            smallfile.write(closer_to_write)
            smallfile.close()


if __name__ == '__main__':
    cli()
