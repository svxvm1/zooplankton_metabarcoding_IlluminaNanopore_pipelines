for f in "$1"/cutadapt2_output/*_cutadapt2.fasta; do
  if [ -e "$f" ]; then
    outdir_aftercutadapt="$1/aftercutadapt_output"
    if [ ! -d "$outdir_aftercutadapt" ]; then
      mkdir "$outdir_aftercutadapt"
    fi
    filename=$(basename "$f")
    output_file="$outdir_aftercutadapt/${filename%.fasta}_uq.fasta"
    command="grep -v '>' $f | sort | uniq -c | sort -nr | nl | sed  -e 's/^\s*\([0-9]\+\)\s\+\([0-9]\+\)\s\+/>*.cutadapt2.fasta_\1_\2\n/'  > $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done

for f in "$1"/cutadapt2_output/*_cutadapt2.fasta; do
  echo "Processing file: $f"
  if [ -e "$f" ]; then
    outdir_cutadapt2="$1/aftercutadapt2_output"
    if [ ! -d "$outdir_aftercutadapt2" ]; then
      mkdir "$outdir_aftercutadapt2"
    fi
    filename=$(basename "$f")
    output_file="$outdir_cutadapt2/${filename%.fasta}_uq5.fasta"
    command="grep -v '>' $f | sort | uniq -c | sort -nr | awk '$1>=5' | nl | sed -e 's/^\s*\([0-9]\+\)\s\+\([0-9]\+\)\s\+/>*.cutadapt2.fasta_\1_\2\n/' > $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done

for f in "$1"/aftercutadapt_output/*_cutadapt2_uq.fasta; do
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

for f in "$1"/aftercutadapt2_output/*_cutadapt2_uq5.fasta; do
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

for f in "$1"/blast_output/*_cutadapt2_uq.megablast.tab; do
  if [ -e "$f" ]; then
    outdir_perl="$1/perl"
    if [ ! -d "$outdir_perl" ]; then
      mkdir "$outdir_perl"
    fi
    filename=$(basename "$f")
    output_file="$outdir_perl/${filename%_uq.megablast.tab}_sprank99.txt"
    command="perl sprank.pl $f --percent 97 --cutoff 0 --qald 6 --pcreads 0 --name $filename > $output_file"
    echo "************ $command ***************"
    eval "$command"
    echo ""
  fi
done
