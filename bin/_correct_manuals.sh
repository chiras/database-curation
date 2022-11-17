#!/bin/bash
source bin/externals.txt

corfolder="corrections"
db=$(basename $1 | sed "s/.fa//g")

echo "-- Copying new file to $db.cor.fa"
cp $db.fa $db.cor.fa

rm -f $db.cor.removed_ids.txt
rm -f $db.cor.replaced_ids.txt

for corfile in $(ls $corfolder/*.txt); do
  echo "-- Processing correction file: $corfile"
  while read p; do
    cor_acc=$(echo $p | cut -f1 -d";" | sed "s/\..*//" | tr -d '\n')
    cor_old=$(echo $p | cut -f2 -d";" | sed "s/[[:space:]]/_/" | tr -d '\n')
    cor_new=$(echo $p | cut -f3 -d";" | sed "s/[[:space:]]/_/" | tr -d '\n')
    result=$(grep "$cor_acc" $db.fa) # this can be sped up by grepping all first

    if [ -z "$cor_acc" ]
      then
        echo "skipped (no Accession)"
      else
        if [ -z "$result" ]
        then
          echo "skipped (not in DB)"
        else
        if [ -z "$cor_new" ]
          then
            echo "$cor_acc --> removing from DB <--"
            echo $cor_acc >>  $db.cor.removed_ids.txt
          else
            echo "$cor_old: $cor_acc --> replacing by $cor_new <--"
            #result=$(grep "$cor_acc" $db.fa)
            cor_tax=$(grep -m 1 "$cor_new" $db.fa | sed "s/^>.*;tax=//")
            if [ -z "$cor_tax" ]
              then
                echo ":::Fetching with eUtils"
                cor_tax=$(esearch -db taxonomy -query "$cor_new[ORGN]" | efetch -format xml -stop 1 |  xtract -pattern Taxon -block "*/Taxon" -tab "\n" -element Id,Rank,ScientificName | grep "^kingdom\|^domain\|^phylum\|^order\|^family\|^genus\|^species" |  sed "s/\t/_/g"| tr -s "\n" "," |  sed -e "s/kingdom_/\nk:/g" -e "s/domain/d:/g" -e "s/phylum_/p:/g" -e "s/class_/c:/g" -e "s/order_/o:/g" -e "s/family_/f:/g" -e "s/genus_/g:/g" -e"s/species_/s:/g" | sed '/^\s*$/d')
                cor_tax="${cor_tax}s:$cor_new"
            fi
            if [ "$cor_tax" == "s:$cor_new" ]
              then
                echo ":::No taxonomy found --> added to remove list"
                echo $cor_acc >>  $db.cor.removed_ids.txt
            fi
            sed -i.bak "/$cor_acc/ s/$cor_acc.*$/$cor_acc;tax=$cor_tax/" $db.cor.fa
            #echo $result
            echo $cor_tax
            echo "$cor_old: $cor_acc -->  $cor_tax " >>  $db.cor.replaced_ids.txt
          fi  # end empty replacement name
        fi # end not in DB
        fi # end empty acc
  done < $corfile
done

$sf --ids-pattern $db.cor.removed_ids.txt --ids-exclude -o $db.mc.fa $db.cor.fa
rm -f $db.cor.fa
rm -f $db.cor.fa.bak

echo "Patching done. Your corrected database is called: $db.mc.fa"
