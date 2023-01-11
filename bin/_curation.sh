#!/bin/bash

# [ToDo] standardized log files, tmp files etc.
# [ToDo] more logs
# [ToDo] Github update
# [ToDo] cleanup sed
# [ToDo] gzip tmpdbs
# [ToDo] rm tmp

#####
# Setup
echo $'\n---------------------------'
echo "# Setup"
echo "$(date +'%d/%m/%Y %H:%M:%S:%3N')"
echo "Start: $(date +'%d/%m/%Y %H:%M:%S:%3N')" > filtering.log

# load global settings, e.g. binary paths
source ./bin/externals.txt

if [ "$quiet" = "1" ]
  then
    sf="$sf -q "
    vsearch="$vsearch --quiet "
fi

# define variables
curfolder="curation"
#DB=its2.global.2022-03-05.tax.fa
DB=$(basename $1 | sed "s/.tax.fa//g")
#DB=$(basename $DB | sed "s/.tax.fa//g")

# create dirs
mkdir -p tmp
mkdir -p tmpdb
mkdir -p logs

# sed "s/;/ /" $DB.tax.fa  > ./tmpdb/$DB.tax.fa
#
# #DB=its2.global.2022-03-05
# #DB=ARGV[0]

######
# Fungal removal
echo $'\n---------------------------'
echo "# Fungal removal"

# Classification of the database against the RDP database to identify fungi sequences
$vsearch --sintax $DB.tax.fa  -db ./$curfolder/rdp_its_v2.fa -tabbedout ./tmp/zotus.fungi.uc.sintax -strand plus -sintax_cutoff 0.90 --threads $threads

# list of the Fungi sequences
grep "Fungi(" ./tmp/zotus.fungi.uc.sintax | cut -f1 -d";" | cut -f1 -d" "> ./tmp/non.plant.seqs

# removing nFungi sequences
$sf --ids ./tmp/non.plant.seqs --ids-exclude $DB.tax.fa -o ./tmpdb/$DB.nf.tax.fa > ./logs/fungi.sf
rem_fungi=$(sh ./bin/_count.sh fungi.sf)
echo $'\n' $rem_fungi

######
# remove non-ITS2 sequences
echo $'\n---------------------------'
echo "# Non-ITS2 removal"

# Classification of the database against representative sequences for plant families
# from ITS2-database (Ankenband et al. 2015)
$vsearch --usearch_global ./tmpdb/$DB.nf.tax.fa  --db ./$curfolder/ITS2_plant-family-reps_11_25_22.fasta  --id 0.70 --threads $threads --uc ./tmp/zotus.its2.uc.usearch.global
cut -f 4,9 ./tmp/zotus.its2.uc.usearch.global | sed -e "s/tax=[a-zA-Z_,:;]*//" -e "s/;/\t/g" > ./tmp/zotus.its2.uc.usearch.global.cut
grep "*" ./tmp/zotus.its2.uc.usearch.global.cut | cut -f 2 > ./tmp/non.its2.seqs.list
$sf --ids ./tmp/non.its2.seqs.list --ids-exclude ./tmpdb/$DB.nf.tax.fa -o ./tmpdb/$DB.nf.its2.tax.fa  > ./logs/nonits2.sf
rem_nonits2=$(sh ./bin/_count.sh nonits2.sf)
echo $'\n' $rem_nonits2

######
# remove incomplete taxonomy entries
echo $'\n---------------------------'
echo "# Incomplete taxonomy removal"
grep ">" ./tmpdb/$DB.nf.its2.tax.fa | grep -v  "s:" | sed -e "s/>//" -e "s/;.*//" >  ./tmp/rem_incompltax.list
$sf --ids ./tmp/rem_incompltax.list --ids-exclude ./tmpdb/$DB.nf.its2.tax.fa -o ./tmpdb/$DB.nf.its2.comp.tax.fa  > ./logs/incomplete.sf
rem_inc=$(sh ./bin/_count.sh incomplete.sf)
echo $'\n' $rem_inc

# ######
# Remove Algae
echo $'\n---------------------------'
echo "# Algae removal"
sed -i .bak "s/ /;/" ./tmpdb/$DB.nf.its2.comp.tax.fa
$sf --ids_pattern "Streptophyta" ./tmpdb/$DB.nf.its2.comp.tax.fa -o ./tmpdb/$DB.nf.its2.comp.vasc.tax.fa  > ./logs/algae.sf
rem_algae=$(sh ./bin/_count.sh algae.sf)
echo $'\n' $rem_algae

######
# Remove taxa with too high intra-specific variation to others
echo $'\n---------------------------'
echo "# Intra-specific variability removal"

# selecting species with more than 4 sequences in the DB
grep ">" ./tmpdb/$DB.nf.its2.comp.vasc.tax.fa | sed -e "s/^.*s://" -e "s/,.*$//" -e "s/['()]//g" -e "s/;$//" | sort | uniq -c | sed -e "/[[:space:]][0123][[:space:]]/d" | sed -e "s/^.*[[:space:]]//" > ./tmp/species.list

# set tmp directories
rm -rf tmpVS
mkdir -p tmpVS
rm -rf tmpParts
mkdir tmpParts

sed -e "s/^/(/" -e "s/$/)/" ./tmp/species.list > ./tmp/species.list.1
split -l 100 ./tmp/species.list.1 "tmpParts/part_"

echo "...takes a while"

ls tmpParts/part* | cut -f2 -d"/"  > tmp_list_parts
cat "tmp_list_parts" | xargs -P $threads -I § $sf --ids_pattern ./tmpParts/§ ./tmpdb/$DB.nf.its2.comp.vasc.tax.fa  --out ./tmpVS/%s.fa >> ./logs/var_x.sf
#mv ./tmpVS/*/*.fa ./tmpVS/

# pairwise alignment of all seq vs all seq within species in the database
rm -rf ./tmp/allvar.uc

for species in $(ls ./tmpVS/*.fa | sed -e "s/^.*\///" -e "s/\.fa$//")
  do
        $vsearch --allpairs_global ./tmpVS/$species.fa --uc ./tmpVS/$species.uc --acceptall --threads $threads
        cat ./tmpVS/$species.uc >> ./tmp/allvar.uc ;
        #echo ".";
      # this could be sped up here to do the calcs on shell not R
  done

#file with ID, Accession number, Genus and Species

sed "/^N/d" ./tmp/allvar.uc | cut -f 4,9,10  | sed  -E -e "s/tax=[a-zA-Z_,:]*,g://g" -e $"s/;/\t/g" -e  $"s/\t\t/\t/" -e $"s/,s:/\t/g" > ./tmp/$DB.Streptophyta.allpairs.cut
sed -e $'s/\t/|/g' ./tmp/$DB.Streptophyta.allpairs.cut | awk -F"[|]" '$4==$7' > ./tmp/$DB.Streptophyta.allpairs.cut.two
cp ./tmp/$DB.Streptophyta.allpairs.cut.two tmp.cut

# Threshold iteration
# Running R script - creates a list of species according to best suited threshold

$R --no-save < ./bin/iterations.R
mv Badseqs.txt ./tmp/

# File containing only the Accession number
cat ./tmp/Badseqs.txt | cut -f2 -d" " | sed -e 's/\"//g' -e "/^x$/d" > ./tmp/$DB.iter.list

# Looks for the Accession number and removes from the original database
sed "s/;/ /" ./tmpdb/$DB.nf.its2.comp.vasc.tax.fa > ./tmpdb/$DB.nf.its2.comp.vasc2.tax.fa

$sf --ids ./tmp/$DB.iter.list --ids-exclude ./tmpdb/$DB.nf.its2.comp.vasc2.tax.fa -o ./tmpdb/$DB.nf.its2.comp.vasc.var.tax.fa > ./logs/var.sf
rem_var=$(sh ./bin/_count.sh var.sf)

sed  "s/ /;/" ./tmpdb/$DB.nf.its2.comp.vasc.var.tax.fa > ./$DB.curated.tax.fa

######
# Cleanup

rm -rf tmp*

######
# Final curated database


echo "----------------------------------------" >> filtering.log
echo "" >> filtering.log
echo "# Filtering Summary " >> filtering.log
echo "" >> filtering.log
echo "Starting sequences: " $(grep -c "^>" ./$DB.tax.fa) >> filtering.log
echo "Starting number of taxa: " $(grep ">" ./$DB.tax.fa | cut -f2 -d" " | sort | uniq -c | wc -l)  >> filtering.log
echo "----------------------------------------" >> filtering.log
echo "Filtered Fungi sequences:" $rem_fungi >> filtering.log
echo "Filtered non-ITS2 sequences:" $rem_nonits2 >> filtering.log
echo "Filtered incomplete taxonomy:" $rem_inc >> filtering.log
echo "Filtered Algae sequences:" $rem_algae >> filtering.log
echo "Filtered by high inter-spc variation:" $rem_var >> filtering.log
echo "----------------------------------------" >> filtering.log
echo "Final sequences: " $(grep -c "^>" ./$DB.curated.tax.fa) >> filtering.log
echo "Final number of taxa: " $(grep ">" ./$DB.curated.tax.fa | cut -f2 -d";" | sort | uniq -c | wc -l)  >> filtering.log
echo "" >> filtering.log
echo "----------------------------------------" >> filtering.log
echo "End: $(date +'%d/%m/%Y %H:%M:%S:%3N')" >> filtering.log

cat filtering.log
