#!/bin/sh



###################################
#
# This script sits in the uparse directory and executes from there. 
# When 
#
###################################


# first, set up macqiime so we can run these commands in a subshell
source /macqiime/configs/bash_profile.txt


########################
# Set some directory shortcuts
#   !! This assumes a default macqiime 1.8 install and the same directory architecture. 

export QIIME_DIR=/macqiime
export reference_seqs=$QIIME_DIR/greengenes/gg_13_8_otus/rep_set/97_otus.fasta
export reference_tax=$QIIME_DIR/greengenes/gg_13_8_otus/taxonomy/97_otu_taxonomy.txt
# export reference_tree=$QIIME_DIR/greengenes/gg_13_8_otus/trees/97_otus.tree
export COMBINED=../rawData/combinedRuns
# export UNCOMBINED=../rawData






# join paired ends  - nope, files are way to big, and don"t want to cut them up again. 
# usearch -fastq_mergepairs $COMBINED/r1readCOMBINED.fastq -reverse $COMBINED/r2readCOMBINED.fastq $COMBINED/readsCOMBINEDJOINED.fastq

# Split libraries with QIIME
split_libraries_fastq.py -v -q 0 --store_demultiplexed_fastq -i $COMBINED/seqs.fastq -b $COMBINED/barcodes.fastq -o splitLib/ -m map.txt --barcode_type 16 # -n 300


# get quality stats
usearch -fastq_stats splitLib/seqs.fastq -log splitLib/seqs.stats.log


# remove low quality reads - trimmed short seqs - presumeably didn"t join correctly. 
mkdir qF
usearch -fastq_filter splitLib/seqs.fastq -fastq_maxee 0.5 -fastaout qF/seqs.filtered.tmp.fasta -fastq_minlen 400 # -fastq_trunclen 296 
sed 's/>/>barcodelabel=/' qF/seqs.filtered.tmp.fasta > qF/seqs.filtered.fasta


# dereplicate sequences. Last step with files separate. 
mkdir deRep
usearch -derep_fulllength qF/seqs.filtered.fasta -output deRep/seqs.filtered.derep.fasta -sizeout


# filter singletons 
mkdir filterSingles
usearch -sortbysize deRep/seqs.filtered.derep.fasta -minsize 2 -output filterSingles/seqs.filtered.derep.mc2.fasta


# clusterOTUs
mkdir OTUs
usearch -cluster_otus filterSingles/seqs.filtered.derep.mc2.fasta -otus OTUs/seqs.filtered.derep.mc2.repset.fasta


# reference chimera check
mkdir chiCheck
usearch -uchime_ref OTUs/seqs.filtered.derep.mc2.repset.fasta -db scripts/gold.fa -strand plus -nonchimeras chiCheck/seqs.filtered.derep.mc2.repset.nochimeras.fasta


# label OTUs using puthon script from UPARSE
mkdir labelOTUs
python scripts/fasta_number.py chiCheck/seqs.filtered.derep.mc2.repset.nochimeras.fasta OTU_ > labelOTUs/seqs.filtered.derep.mc2.repset.nochimeras.otus.fasta


# match original quality filtered reads back to otus - this is with bash derep workaround. 
mkdir matchOTUs
usearch -usearch_global qF/seqs.filtered.fasta -db labelOTUs/seqs.filtered.derep.mc2.repset.nochimeras.otus.fasta -strand plus -id 0.97 -uc matchOTUs/otu.map.uc


# make otu table
mkdir otuTable 
# python scripts/uc2otutab.py matchOTUs/otu.map.uc > otuTable/seqs.filtered.derep.mc2.repset.nochimeras.otu-table.txt
python scripts/uc2otutab_jl.py matchOTUs/otu.map.uc > otuTable/seqs.filtered.derep.mc2.repset.nochimeras.otu-table.txt

#### still slow - running pbs script Monday afternoon.  

# convert to biom
biom convert --table-type="OTU table" -i otuTable/seqs.filtered.derep.mc2.repset.nochimeras.otu-table.txt -o otuTable/seqs.filtered.derep.mc2.repset.nochimeras.otu-table.biom


# assign taxonomy
assign_taxonomy.py -t gg_13_5_otus/taxonomy/97_otu_taxonomy.txt -r gg_13_8_otus/rep_set/97_otus.fasta -i labelOTUs/seqs.filtered.derep.mc2.repset.nochimeras.otus.fasta -o assigned_taxonomy


# add taxonomy to BIOM table
biom add-metadata --sc-separated taxonomy --observation-header OTUID,taxonomy --observation-metadata-fp assigned_taxonomy/seqs.filtered.derep.mc2.repset.nochimeras.OTUs_tax_assignments.txt -i otuTable/seqs.filtered.derep.mc2.repset.nochimeras.otu-table.biom -o otuTable/otu_table.biom









