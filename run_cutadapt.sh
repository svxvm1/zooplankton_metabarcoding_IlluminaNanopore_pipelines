#!/bin/bash

# Specify the directory containing your FASTA files
input_dir="/nfs/production/cochrane/ena/users/azyoud/nanopore/production/fastq_passed_porechopped/illumina_samples_output_afterSeqtk"
output_dir="/nfs/production/cochrane/ena/users/azyoud/nanopore/production/fastq_passed_porechopped/illumina_samples_output_afterSeqtk/illumina_samples_output_cutadapt"
# Loop through each .fasta file in the input directory
for fasta_file in "$input_dir"/*.fasta; do
    # Extract the filename without extension
    filename=$(basename -- "$fasta_file")
    filename_no_ext="${filename%.*}"

    # Run the first cutadapt command
    output1="${output_dir}/${filename_no_ext}_cutadapt.fasta"
    cutadapt -g CCCTGCCHTTTGTACACAC --match-read-wildcards --trimmed-only --overlap 20 -e 0.11 -o "$output1" "$fasta_file"

    # Run the second cutadapt command using the output of the first command
    output2="${output_dir}/${filename_no_ext}_cutadapt2.fasta"
    cutadapt -g GTAGGTGAACCTGCGAAGG --match-read-wildcards --trimmed-only --overlap 20 -e 0.11 -o "$output2" "$output1"

    echo "Processing $fasta_file completed. Output saved to $output2"
done

