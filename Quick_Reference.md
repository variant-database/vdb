# List of commands to query the SARS-CoV-2 variant database

The commands below define a Variant Query Language that can be used to search the mutational landscape of SARS-CoV-2 genomes.

## Notation
cluster = group of viruses        < > = user input        n = an integer  
pattern = group of mutations        \[ ] = optional  
"world"  = all viruses in database        → result  
If no cluster is entered, all viruses will be used ("world")  

## Variables
To define a variable for a cluster or pattern:  \<name> `=` cluster or pattern  
To check whether two clusters or patterns are equal: \<item1> `==` \<item2>  
To count a cluster or pattern in a variable: `count` \<variable name>  
Set operations `+`, `-`, and `*` (intersection) can be applied to clusters or patterns  
The result, if any, of the previous command is available in the variable `last`.  
Results of most list commands can be assigned to a variable.  

## Filtering commands
\<cluster> `from` \<country or state>    → cluster  
\<cluster> `containing` [\<n>] \<pattern>  → cluster    alias `with`, `w/`  
\<cluster> `not containing` [\<n>] \<pattern> → cluster    alias `without`, `w/o` (full pattern)  
\<cluster> `before` \<date>        → cluster  
\<cluster> `after` \<date>         → cluster  
\<cluster> [`range`] \<date>-\<date2>    → cluster  
\<cluster> `>` or `<` or `#` \<n>        → cluster    filter by # of mutations  
\<cluster> `named` \<state_id or EPI_ISL#>  → cluster  
\<cluster> `lineage` \<Pango lineage>   → cluster  
\<cluster> `sample` \<number or decimal fraction> → cluster   random subset  

## Commands to find mutation patterns
`consensus` [`for`] \<cluster or country or state>   → pattern  
`patterns` [`in`] [\<n>] \<cluster>           → pattern  

## Listing commands
`list` [\<n>] \<cluster>  
[`list`] `countries` [`for`] \<cluster>  
[`list`] `states` [`for`] \<cluster>  
[`list`] `lineages` [`for`] \<cluster>  
[`list`] `trends` [`for`] \<cluster>  
[`list`] `frequencies` [`for`] \<cluster>        alias `freq`  
[`list`] `monthly` [`for`] \<cluster> [\<cluster2>]  
[`list`] `weekly` [`for`] \<cluster> [\<cluster2>]  
[`list`] `patterns`        lists built-in and user defined patterns  
[`list`] `clusters`        lists built-in and user defined clusters  
[`list`] `proteins`  
[`list`] `variants`        lists WHO-designated variants

## Other commands
`sort` \<cluster>    (by date)  
`help` [\<command>]    alias `?`  
`license`  
`history`  
`load` \<vdb database file>  
`trim`               removes extraneous N nucleotides from all viruses  
`char` \<Pango lineage>        prints characteristics of lineage  
`sublineages` \<Pango lineage>    prints characteristics of sublineages  
`diff` \<cluster or pattern> [-] \<cluster or pattern> differences of consensus/patterns  
`testvdb`               runs built-in tests of **vdb**  
`demo`                runs demonstration of **vdb**  
`save` \<cluster or pattern or history or list name> \<file name>  
`load` \<cluster name> \<file name>  
`group lineages` \<lineage names>  define a lineage group  alias `group lineage`, `lineage group`  
`lineage groups`           lists defined lineages groups  
`clear` \<cluster name> or \<lineage group>   clears the definition  
`reset`  
`settings`  
`mode`    
`count` \<cluster name or pattern name>   
`//` [\<comment>]     
`quit`  

## Lineage assignment
`prepare`                  prepare **vdb** to assign lineages based on consensus mutation sets  
`assign` \<cluster name1> [\<cluster name2>]   assigns Pango lineages to viruses in a cluster  
`compare` \<cluster name1> \<cluster name2>   compares the lineage assignments of viruses in two clusters  
`identical` \<cluster name>         searches for viruses in different lineages with identical mutation patterns  

## Program switches
`debug`/`debug off`  
`listAccession`/`listAccession off`  
`listAverageMutations`/`listAverageMutations off`  
`includeSublineages`/`includeSublineages off`/`excludeSublineages`  
`simpleNuclPatterns`/`simpleNuclPatterns off`  
`excludeNFromCounts`/`excludeNFromCounts off`  
`sixel`/`sixel off`  
`trendGraphs`/`trendGraphs off`  
`stackGraphs`/`stackGraphs off`  
`completions`/`completions off`  
`displayTextWithColor`/`displayTextWithColor off`  
`paging`/`paging off`  
`quiet`/`quiet off`  
`listSpecificity`/`listSpecificity off`  

`minimumPatternsCount = `\<n>  
`trendsLineageCount = `\<n>       alias `trends` \<n>  
`maxMutationsInFreqList = `\<n>  
`consensusPercentage = `\<n>  
`caseMatching = all/exact/uppercase`
