# Commands to query SARS-CoV-2 variant database

The commands below define a Variant Query Language that can be used to search the mutational landscape of SARS-CoV-2 genomes.

Notation:  
cluster = group of viruses             < > = user input     n = an integer  
pattern = group of mutations            [ ] = optional  
"world"  = all viruses in database        -> result  

To define a variable for a cluster or pattern:  \<name> = cluster or pattern  
Set operations +, -, and * (intersection) can be applied to clusters or patterns  
If no cluster is entered, all viruses will be used ("world")  

## Filter commands
\<cluster> from \<country or state>               → cluster  
\<cluster> containing [\<n>] \<pattern>           -> cluster  alias with, w/  
\<cluster> not containing \<pattern>              -> cluster  alias without, w/o (full pattern)  
\<cluster> before \<date>                         -> cluster  
\<cluster> after \<date>                          -> cluster  
\<cluster> > or < \<n>                            -> cluster     filter by # of mutations  
\<cluster> named \<state_id or EPI_ISL>           -> cluster  
\<cluster> lineage \<Pango lineage>               -> cluster  

## Commands to find mutation patterns
consensus [for] \<cluster or country or state>  -> pattern  
patterns [in] [\<n>] \<cluster>                  -> pattern  

## Listing commands
list [\<n>] \<cluster>  
[list] countries [for] \<cluster>  
[list] states [for] \<cluster>  
[list] lineages [for] \<cluster>  
[list] frequencies [for] \<cluster>          alias freq  
[list] monthly [for] \<cluster> [\<cluster2>]  
[list] weekly [for] \<cluster> [\<cluster2>]  
[list] patterns         lists built-in and user defined patterns  
[list] clusters         lists built-in and user defined clusters  

## Other commands
sort \<cluster>  (by date)  
help  
license  
history  
load \<vdb database file>  
char \<Pango lineage>    prints characteristics of lineage  
quit  

## Program switches
debug/debug off  
listAccession/listAccession off  
listAverageMutations/listAverageMutations off  
includeSublineages/includeSublineages off  
simpleNuclPatterns/simpleNuclPatterns off  

minimumPatternsCount = \<n>  
