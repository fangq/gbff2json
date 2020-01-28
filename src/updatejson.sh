#!/bin/sh

ID=GCF_009858895.2_ASM985889v3
fn=${ID}_genomic.gbff
echo ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/$ID/$fn.gz
wget ftp://ftp.ncbi.nlm.nih.gov/genomes/all/GCF/009/858/895/$ID/$fn.gz
gunzip -f $fn.gz
gbff2json.pl $fn > $fn.json
mv $fn* ../data
