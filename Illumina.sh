#!/bin/bash
#SBATCH --partition=shortq,defq,mmemq
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=1
#SBATCH --mem=128g
#SBATCH --time=1:00:00


# Check if directory path is provided
if [ -z "$1" ]; then
  echo "Error: Directory path is missing."
  echo "Usage: bash script.sh /home/svxvm1/DeepSeq2023"
  exit 1
fi

# Activate conda environment if needed
# Make sure to replace 'NEWENVIRONMENT' with the actual environment name
if command -v conda >/dev/null 2>&1; then
  conda activate NEWENVIRONMENT
fi

# Process files
for f in "$1"/*_L001_R1_001.fastq.gz; do
  if [ -e "$f" ]; then
    outdir_flash="flash_output"
    if [ ! -d "$outdir_flash" ]; then
      mkdir "$outdir_flash"
    fi
    filename=$(basename "$f")
    filename="${filename%_L001_R1_001.fastq.gz}"
    command="flash -z -m 10 -M 180 -o $outdir_flash/$filename $f $1/${filename}_L001_R2_001.fastq.gz"
    echo "************ $command ***************"
    $command
    echo ""
  fi
done

for f in "$1"/flash_output/*.extendedFrags.fastq.gz; do
echo $f
  if [ -e "$f" ]; then
    outdir_trim="$1/trim_output"
    if [ ! -d "$outdir_trim" ]; then
      mkdir "$outdir_trim"
    fi
    filename=$(basename "$f")
    filename="${filename%.extendedFrags.fastq.gz}"
    command="trimmomatic SE -phred33 $f $outdir_trim/${filename}.extendedFrags_trimmed.fastq.gz SLIDINGWINDOW:5:30"
    echo "************ $command ***************"
    $command
    echo ""
  fi
done

for f in "$1"/trim_output/*.extendedFrags_trimmed.fastq.gz; do
  if [ -e "$f" ]; then
    outdir_cutadapt="$1/cutadapt_output"
    if [ ! -d "$outdir_cutadapt" ]; then
      mkdir "$outdir_cutadapt"
    fi
    filename=$(basename "$f")
    command="cutadapt -g CCCTGCCHTTTGTACACAC --match-read-wildcards --trimmed-only --overlap 20 -e 0.11 -o $outdir_cutadapt/cag_${filename} $f"
    echo "************ $command ***************"
    $command
    echo ""
  fi
done

for f in "$1"/cutadapt_output/*.extendedFrags_trimmed.fastq.gz; do
  if [ -e "$f" ]; then
    outdir_cutadapt2="$1/cutadapt_output2"
    if [ ! -d "$outdir_cutadapt2" ]; then
      mkdir "$outdir_cutadapt2"
    fi
    filename=$(basename "$f")
    cut1="$f"
    cut2="$outdir_cutadapt2/caga_${filename:4}"
    command="cutadapt --minimum-length=120 -a GTAGGTGAACCTGCGAAGG --match-read-wildcards --trimmed-only --overlap 20 -e 0.11 -o $cut2 $cut1"
    echo "************ $command ***************"
    $command
    echo ""
  fi
done

for f in "$1"/cutadapt_output2/caga_*.extendedFrags_trimmed.fastq.gz; do
  if [ -e "$f" ]; then
    outdir_seqtk="$1/seqtk_output"
    if [ ! -d "$outdir_seqtk" ]; then
      mkdir "$outdir_seqtk"
    fi
    filename=$(basename "$f")
    command="seqtk seq -a $f > $outdir_seqtk/${filename%.fastq.gz}.fasta"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done


for f in "$1"/seqtk_output/caga_*.extendedFrags_trimmed.fasta; do
  if [ -e "$f" ]; then
    outdir_afterseqtk="$1/afterseqtk_output"
    if [ ! -d "$outdir_afterseqtk" ]; then
      mkdir "$outdir_afterseqtk"
    fi
    filename=$(basename "$f")
    output_file="$outdir_afterseqtk/${filename%.fasta}_uq.fasta"
    command="grep -v '>' $f | sort | uniq -c | sort -nr | nl | sed  -e 's/^\s*\([0-9]\+\)\s\+\([0-9]\+\)\s\+/>*.extendedFrags_trimmed.fasta_\1_\2\n/'  > $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done

for f in "$1"/seqtk_output/caga_*.extendedFrags_trimmed.fasta; do
  echo "Processing file: $f"
  if [ -e "$f" ]; then
    outdir_afterseqtk2="$1/afterseqtk2_output"
    if [ ! -d "$outdir_afterseqtk2" ]; then
      mkdir "$outdir_afterseqtk2"
    fi
    filename=$(basename "$f")
    output_file="$outdir_afterseqtk2/${filename%.fasta}_uq5.fasta"
    command="grep -v '>' $f | sort | uniq -c | sort -nr | awk '$1>=5' | nl | sed -e 's/^\s*\([0-9]\+\)\s\+\([0-9]\+\)\s\+/>*.extendedFrags_trimmed.fasta_\1_\2\n/' > $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done

for f in "$1"/afterseqtk_output/caga_*.extendedFrags_trimmed_uq.fasta; do
  echo "Processing file: $f"
  if [ -e "$f" ]; then
    outdir_blast="blast_output"
    echo "Output directory: $outdir_blast"
    if [ ! -d "$outdir_blast" ]; then
      echo "Creating directory: $outdir_blast"
      mkdir "$outdir_blast" || { echo "Failed to create directory: $outdir_blast"; exit 1; }
    fi
    filename=$(basename "$f")
    output_file="$outdir_blast/${filename%_uq.fasta}_uq.megablast.tab"
    command="blastn -task megablast -db /gpfs01/home/svxvm1/DeepSeq2023/DATABASE/DATABASE_DEC/DATABASE_23_DECEMBER_onlynew -query $f -outfmt '6 qseqid sseqid pident qlen length mismatch evalue bitscore stitle' -evalue '1e-15' -max_target_seqs 1 -num_threads 8 -dust no -out $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  else
    echo "File not found: $f"
  fi
done

for f in "$1"/afterseqtk2_output/caga_*.extendedFrags_trimmed_uq5.fasta; do
  if [ -e "$f" ]; then
    outdir_blast2="$1/blast_output2"
    if [ ! -d "$outdir_blast2" ]; then
      mkdir "$outdir_blast2"
    fi
    filename=$(basename "$f")
    output_file="$outdir_blast2/${filename%_uq5.fasta}_uq5.megablast.tab"
    command="blastn -task megablast -db /gpfs01/home/svxvm1/DeepSeq2023/DATABASE/18S_DATABASE/DATABASE_18S_23 -query $f -outfmt '6 qseqid sseqid pident qlen length mismatch evalue bitscore stitle' -evalue '1e-15' -max_target_seqs 1 -num_threads 8 -dust no -out $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done

for f in "$1"/blast_output/caga_*.extendedFrags_trimmed_uq.megablast.tab; do
  if [ -e "$f" ]; then
    outdir_perl="$1/perl"
    if [ ! -d "$outdir_perl" ]; then
      mkdir "$outdir_perl"
    fi
    filename=$(basename "$f")
    output_file="$outdir_perl/${filename%.extendedFrags_trimmed_uq.megablast.tab}_sprank99.txt"
    command="perl sprank.pl $f --percent 97 --cutoff 0 --qald 6 --pcreads 0 --name $filename > $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done
