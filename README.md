# Reference database curation

## Intro
This is the repository of the database curation pipline for (meta-)barcoding. The corresponding article is available as preview while being under review: [https://www.biorxiv.org/content/10.1101/2023.06.12.544582v1](https://www.biorxiv.org/content/10.1101/2023.06.12.544582v1)

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
* VSEARCH 

## Tested
This was tested under
* Mac OSX 11.0.1
* Ubuntu 20.04

## Functions:

### Automatized curation
1) Fungal removal
2) Non-target (non-ITS2) sequence removal
3) Removing incomplete taxonomies
4) Chlorophyta removal
5) Identify and remove iterative intra-spec outliers

(Details on these filters are provided in the article above)

This function performs the automated curation:
```
bash /bin/_curation.sh YOUR.DB.NAME.fa
```


### Manual list curation by identified wrong NCBI taxonomies
* taxonomy corrections
* sequence removal

1. Place a ```.txt``` in the format as in the examples into the folder ```corrections```.
The format is
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

1. Place one or more ```.fasta``` in the format as in the examples into the folder ```additions```.
The format is
```
>Scientific_name
ACGT
```
 Multiple separate files can be made, all ```.fasta``` files in that folder will be used for additions.

2. Then call the function on your database
```
bash /bin/_add_manuals.sh YOUR.DB.NAME.fa
```
This can take a while for large number of sequences.


### Subsetting: Input DB, list -> Output DB
Subsetting your input database into a geographically database
 ```
SeqFilter --ids_pattern LOCAL.FLORA.csv YOUR.DB.NAME.fa -o LOCAL.FLORA.DB.fa
```
