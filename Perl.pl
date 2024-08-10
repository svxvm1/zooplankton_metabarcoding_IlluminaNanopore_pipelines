#!/usr/bin/perl
use strict;
use Getopt::Long;                #-- deal with command line options

# determine species rank in sample from custom blast report

## example of custom blast output to process
## 0		    	1	    	2   	3	4	5	6	     7	    8
## gp18-BC22_586_6	NC_011571	97.22	107	108	1	3e-46	 182	Pungitius etc etc
my $version = 1.0;
#my $cutoff = 100;
my $cutoff  = 10;
my $percent = 90;
#my $percent = 95;
my $qald    = 6;
my $pcreadsco = 0;
#my $pcreadsco = 0.1;
my $name = 'REPORT';
my $help;
#print "#ARGV:".$#ARGV."\n";
#if (  $#ARGV == -1 ){ print "Minimum reqirement: list / glob of blastn tab results files\n";}

GetOptions(
  'percent=i' => \$percent,   # blast % identity cutoff
  'cutoff=i'  => \$cutoff,    # read count cutoff
  'qald=i'    => \$qald,      # query - alignment length difference
  'pcreads=f' => \$pcreadsco, # percentage reads cutoff
  'name=s'    => \$name,      # oprional run name
  'help'      => \$help,
);

my $requires = <<"REQUIRES";

sprank.pl:
         script to produce a list of species ranked according to read counts
    n.b. requires custom tabular blastn outputs with: 
         1] species info in description/stitle field (blastn params: -max_target_seqs 1 \
            -outfmt '6 qseqid sseqid pident qlen length mismatch evalue bitscore stitle')
         2] query sequence names tagged with the number of reads represented (name_<int>)
         3] file names including the barcode name formatted as *_BC??_*
         
REQUIRES
         
my $usage = <<"USAGE";
Usage:

  sprank.pl *blastn.tab  >  sprank_report.txt
	  
    --cutoff <int>      [$cutoff] Don't report hits with read counts below this number
    --pcreads <float>   [$pcreadsco] Don't report hits with read counts below this % 
                         of total reads with blast matches
    --percent <int>     [$percent] Skip hits with blastn % identity below this 
    --qald <int>        [$qald] Skip hits with qlen - alignment length > this number of bases                     
    --name <string>     [$name] Optional report name for output header line
    --help              Print this message

Vesion: $version
USAGE

#print "#ARGV:".$#ARGV."\n";
#print "ARGV[0]:".$ARGV[0]."\n";
if (( $#ARGV == -1 ) || ($help)){	
	print $usage;
	print $requires;
	exit;
}
unless(-e $ARGV[0]){ 
	print "\nblastn result files not found\n\n";
	print $usage;
	exit;
}



print "# ${name}: species rank by read count\n"
    . "# cutoff > $cutoff reads\n# alignment >= ${percent}% match\n"
    . "# ql-al <= ${qald}bp\n# %reads cutoff >= ${pcreadsco}%\n\n";
foreach my $file (@ARGV) {
my $short_alignment_reads = 0;
my $low_percent_reads = 0;
my $total_passed_read_count = 0;
    if ( -e $file ) {  # double check existence
        my %blastinfo = ();
        #push @data, $file;
        open FILE , '<'.$file  or die $!;
        while( <FILE> ) { 
                         chomp;
                         my @fields = split /\t/, $_;
                         my ($readname, $readcount) = $fields[0] =~ /(.+)_(\d+)$/;
                         if ($fields[2] < $percent ){$low_percent_reads += $readcount; next} # skip if % match is below threshold
                         if(($fields[3] - $fields[4]) > $qald){$short_alignment_reads += $readcount; next}
                          $total_passed_read_count  += $readcount;

                          $blastinfo{$fields[1]}[0] +=  $readcount; 							# readcount
                          $blastinfo{$fields[1]}[1] += ($fields[2] * $readcount); 				# %
                          $blastinfo{$fields[1]}[2] +=(($fields[3] - $fields[4]) * $readcount); # ql-al
                          $blastinfo{$fields[1]}[3] += ($fields[5] * $readcount);				# mismatch
                          $blastinfo{$fields[1]}[4] += ($fields[7] * $readcount);				# score
                          $blastinfo{$fields[1]}[5]  =  $fields[8]; 							# description/species info
                          $blastinfo{$fields[1]}[6] ++;                                         # increment
                          #print $readcount.'  ';
                        }
                        close FILE;
        my ($PX, $BC) = $file =~ /(.+)_(BC\d{2})_/;
        print "## $BC ##\n";
        print "%reads\tread_count\t%match\tql-al\tmm\tbit_score\taccession\tdescription\n\n";

    for my $key ( sort { $blastinfo{$b}[0] <=> $blastinfo{$a}[0] } keys %blastinfo ) {

 #   for my $key ( keys %blastinfo ) {
        my $tempinfo =$blastinfo{$key};
        if ($$tempinfo[0] < $cutoff ){next}
        my $local_percent_reads = (($$tempinfo[0]/$total_passed_read_count) * 100);
        if ($local_percent_reads < $pcreadsco) {next}
        printf ("%6.2f\t",$local_percent_reads);

        printf ("%8d\t", $$tempinfo[0]);			        # read count
        printf ("%5.1f\t",($$tempinfo[1]/$$tempinfo[0]));	# mean %
        printf ("% 3.1f\t", ($$tempinfo[2]/$$tempinfo[0]));	# mean ql-al
        printf ("%2.1f\t", ($$tempinfo[3]/$$tempinfo[0]));	# mean mismatch
        printf ("%4.0f\t", ($$tempinfo[4]/$$tempinfo[0]));	# mean blast bit score
        printf ("%-14s\t",${key});				            # accession
        printf ("%s\n", $$tempinfo[5]);				        # description/species info
       # print "${key}:\t";
       # print join("\t", @$tempinfo )."\n";
    }
        print "\n";
        print "# skipped for low % match < ${percent}%: $low_percent_reads reads\n";
        print "# skipped for short alignments ( > $qald bases difference): $short_alignment_reads reads\n";
        print "# Total $BC reads passing blast: $total_passed_read_count reads\n";
        print "\n";

         }
}

