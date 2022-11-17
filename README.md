# Reference database curation 

## Intro

## Requirements
### Compatible Database 
These functions are intented for usage with databases that have a taxonomy stored in a specific format used for classifiers. 
Such databases can be created using BCdatabase: https://github.com/molbiodiv/bcdatabaser

Dokumentation: https://molbiodiv.github.io/bcdatabaser/

And particuarly syntax information: https://molbiodiv.github.io/bcdatabaser/output.html

## Dependencies

Software dependencies are declared in ```bin/externals.txt```
These are 
* Seqfilter: https://github.com/BioInf-Wuerzburg/SeqFilter
* NCBI eUtils Command line Tools: https://www.ncbi.nlm.nih.gov/books/NBK179288/

## Tested 
This was tested under 
* Mac OSX 11.0.1
* Ubuntu 20.04

## Functions:

### Automatized curation
* fungal removal
* iterative intra-spec outliers

### Manual list curation by identified wrong NCBI taxonomies
* taxonomy corrections
* sequence removal

1. Place a ```.txt``` in the format as in the examples into the folder ```corrections```
Format is 
```
NCBI-Accession;Wrong_ScientificName;Corrected_ScientificName;Your_Name
```
 Multiple separate files can be made, all ```.txt``` files in that folder will be used for corrections.

2. Then call the function on your database 
```
bash /bin/_correct_manuals.sh YOUR.DB.NAME.fa
```
This can take a while for large databases.


### Manual addition of sequences by patching taxonomy and inclusion
* adding taxonomy and appending to DB

1. Place one or more ```.fasta``` in the format as in the examples into the folder ```additions```
Format is 
```
>Scientific_name
ACGT
```
 Multiple separate files can be made, all ```.fasta``` files in that folder will be used for additions.

2. Then call the function on your database 
```
bash /bin/_add_manuals.sh YOUR.DB.NAME.fa
```
This can take a while for large databases.


### Subsetting: Input DB, list -> Output DB
