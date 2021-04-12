# Commands to query the SARS-CoV-2 variant database

The commands below define a Variant Query Language that can be used to search the mutational landscape of SARS-CoV-2 genomes.  
Many commands have a both a verbose form (`list countries for cluster1`) and a short form (`countries cluster1`).

## Notation
cluster = group of viruses        < > = user input        n = an integer  
pattern = group of mutations        \[ ] = optional  
"world"  = all viruses in database        → result  
If no cluster is entered, all viruses will be used ("world")  

## Variables
To define a variable for a cluster or pattern:  \<name> `=` cluster or pattern  
Set operations `+`, `-`, and `*` (intersection) can be applied to clusters or patterns  

Variable names are case sensitive and can included letters or numbers.  
Commands are not case sensitive.

## Mutation patterns and nucleotide mode
If the loaded mutation list file contains spike protein mutations, then mutation patterns should be spike protein mutations. For example, `E484K D614G`.  
If the loaded mutation list file contains nucleotide mutations, then mutation patterns can be either spike protein mutations (`E484K`), nucleotide mutations (`G23012A`), or a specified protein mutation (`NSP12:P323L`).

## Filtering commands
#### \<cluster>`from`\<country or state>    → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses from the specified country or US state.  
<br />
#### \<cluster>`containing`[\<n>] \<pattern>  → cluster    alias `with`, `w/`  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with the specified mutation pattern. By default only viruses with all the mutations of the specified pattern are returned. If an integer \<n> is specified in the search command, then viruses are returned only if they have at least \<n> of the mutations in the pattern.  
<br />
#### \<cluster>`not containing`\<pattern>   → cluster    alias `without`, `w/o` (full pattern)  

Searches the specified cluster (or all viruses if no cluster is given) for viruses without the specified mutation pattern. All viruses are returned unless they have the complete mutation pattern.  
<br />
#### \<cluster>`before`\<date>        → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with collection date before the specified date.  
<br />
#### \<cluster>`after`\<date>         → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with collection date after the specified date.  
<br />
#### \<cluster>`>` or `<` \<n>          → cluster    filter by # of mutations  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with greater than (or less than) the specified number of mutations.  
<br />
#### \<cluster>`named`\<state_id or EPI_ISL#>  → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with the specified text string in their virus name field. Or, if a number is specified, returns the virus with that accession number.  
<br />
#### \<cluster>`lineage`\<Pango lineage>   → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses belonging to the specified Pango lineage. A program switch determines whether viruses in sublineages are returned (by default sublineages are included).  
<br />

## Commands to find mutation patterns
`consensus` [`for`] \<cluster or country or state>   → pattern  
`patterns` [`in`] [\<n>] \<cluster>           → pattern  

## Listing commands
`list` [\<n>] \<cluster>  
[`list`] `countries` [`for`] \<cluster>  
[`list`] `states` [`for`] \<cluster>  
[`list`] `lineages` [`for`] \<cluster>  
[`list`] `frequencies` [`for`] \<cluster>        alias `freq`  
[`list`] `monthly` [`for`] \<cluster> [\<cluster2>]  
[`list`] `weekly` [`for`] \<cluster> [\<cluster2>]  
[`list`] `patterns`        lists built-in and user defined patterns  
[`list`] `clusters`        lists built-in and user defined clusters  

## Other commands
`sort` \<cluster>    (by date)  
`help`  
`license`  
`history`  
`load` \<vdb database file>  
`char` \<Pango lineage>        prints characteristics of lineage  
`quit`  

## Program switches
`debug`/`debug off`  
`listAccession`/`listAccession off`  
`listAverageMutations`/`listAverageMutations off`  
`includeSublineages`/`includeSublineages off`  
`simpleNuclPatterns`/`simpleNuclPatterns off`  

`minimumPatternsCount = `\<n>  
