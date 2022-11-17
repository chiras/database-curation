#!/bin/bash
addfolder="additions"
db=$(basename $1 | sed "s/.fa//g")

#echo "-- Copying new file to $db.add.fa"
#cp $db.fa $db.add.fa

cat $addfolder/*.fasta > all_additions.fasta

i=1
j=1
nohit="No Hits found for: "

for addheader in $(grep "^>" all_additions.fasta | sort | uniq ); do
    cor_new=$(echo $addheader | sed -e "s/[[:space:]]/_/" -e "s/>//" | tr -d '\n')
    echo $cor_new
    cor_tax=$(grep -m 1 "s:$cor_new" all_additions.fasta | sed "s/^>.*;tax=//")

    if [ "$cor_new" == *";tax="* ]
      then
        echo "skipping"
      else

        if [ -z "$cor_tax" ]
          then
            echo ":::Fetching with original large DB"
            cor_tax=$(grep -m 1 "$cor_new" $db.fa | sed "s/^>.*;tax=//")
        fi

        if [ -z "$cor_tax" ]
          then
            echo ":::Fetching with eUtils"
            cor_tax=$(esearch -db taxonomy -query "$cor_new[ORGN]" | efetch -format xml -stop 1 |  xtract -pattern Taxon -block "*/Taxon" -tab "\n" -element Id,Rank,ScientificName | grep "^kingdom\|^domain\|^phylum\|^order\|^family\|^genus\|^species" |  sed "s/\t/_/g"| tr -s "\n" "," |  sed -e "s/kingdom_/\nk:/g" -e "s/domain/d:/g" -e "s/phylum_/p:/g" -e "s/class_/c:/g" -e "s/order_/o:/g" -e "s/family_/f:/g" -e "s/genus_/g:/g" -e"s/species_/s:/g" | sed '/^\s*$/d')
            cor_tax="${cor_tax[0]}s:$cor_new"
        fi
        if [ "$cor_tax" == "s:$cor_new" ]
          then
            echo ":::No taxonomy found "
            nohit[$j]=$cor_new
            j=$((j+1))
        fi
        sed -i.bak "/^>${cor_new}/ s/>$cor_new.*$/>XXX$i;tax=$cor_tax/" all_additions.fasta
        #echo $result
        echo $cor_tax
        i=$((i+1))
      fi # end if tax already done
done

sed -i.bak "s/s:[a-zA-Z]*[[:space:]][a-zA-Z]*,//" all_additions.fasta
while read line; do n=$((++n)) &&  echo $line|sed -e 's/XXX/'XXX-$n-'/' ; done < all_additions.fasta > all_additions2.fasta

cat all_additions2.fasta $db.fa > $db.add.fa
#rm all_additions.fasta
rm all_additions.fasta.bak

echo "Done batching and adding to DB"
echo "${nohit[*]}"
