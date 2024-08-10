#!/bin/bash

# Set the path to the main directory containing subdirectories (barcode01, barcode02, ...)
main_directory="/nfs/production/cochrane/ena/users/azyoud/nanopore/production/fastq_passed_porechopped/seqtk"

# Set the path to the output directory
output_base_directory="/nfs/production/cochrane/ena/users/azyoud/nanopore/production/fastq_passed_porechopped/seqtk_output"

# Loop through all subdirectories in the main directory
for barcode_directory in "$main_directory"/*; do
    # Check if the item is a directory
    if [ -d "$barcode_directory" ]; then
        # Extract the barcode name from the directory path
        barcode_name=$(basename -- "$barcode_directory")

        # Set the input directory for the current barcode
        input_directory="$barcode_directory"

        # Set the output directory for the current barcode
        output_directory="$output_base_directory/$barcode_name"

        # Create the output directory if it doesn't exist
        mkdir -p "$output_directory"

        # Loop through all FASTQ files in the current barcode directory
        for fastq_file in "$input_directory"/*.fastq.gz; do
            # Extract the filename without extension
            filename=$(basename -- "$fastq_file")
            filename_no_ext="${filename%.*}"

            # Set the output file path
            output_file="$output_directory/$filename_no_ext""_$barcode_name""_seqtk.fasta"

            # Run seqtk on the current FASTQ file
            seqtk seq -A "$fastq_file">"$output_file"

            # Print a message indicating completion
            echo "seqtk completed for $filename"
        done
    fi
done

