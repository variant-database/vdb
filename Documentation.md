# Commands to query the SARS-CoV-2 variant database

The commands below define a Variant Query Language that can be used to search the mutational landscape of SARS-CoV-2 genomes.  
Many commands have a both a verbose form (`list countries for cluster1`) and a short form (`countries cluster1`).

## Notation
A cluster is a group of viruses, usually obtained as the result of a search command.  
A pattern is a list of one or more mutations, user-specified or the result of a `consensus` or `patterns` command.  
In the command descriptions below, items to be specified by the user are indicated with angle brackets, < >.  
Optional items are indicated with square brackets, \[ ].  
If a command returns a cluster or pattern, this is indicated following an arrow: → result  
If no cluster is entered for a search command, all loaded viruses will be searched.  
The set of all viruses loaded into the program is specified by the pre-defined cluster named "world".  
Command keywords are not case sensitive.

## Installation
Installation instructions are given [here](https://github.com/variant-database/vdb#3-installation).

## Variables
To define a variable for a cluster or pattern:  \<name> `=` cluster or pattern  
Variable names are case sensitive and can included letters or numbers.  
To check whether two clusters or patterns are equal: \<item1> `==` \<item2>  
To count a cluster or pattern in a variable: `count` \<variable name>  
Results of most list commands can be saved to a variable.  
Subscripts can be applied to cluster variables to extract one or more viruses.  

#### `last`    

The result, if any, of the previous command is available in the variable `last`.  
<br />

## Set operations
Set operations `+`, `-`, and `*` (intersection) can be applied to clusters or patterns.   

## Mutation patterns and nucleotide mode
If the loaded mutation list file contains spike protein mutations, then mutation patterns should be spike protein mutations. For example, `E484K D614G`.  
If the loaded mutation list file contains nucleotide mutations, then mutation patterns can be either spike protein mutations (`E484K`), nucleotide mutations (`G23012A`), or a specified protein mutation (`NSP12:P323L`).  
Mutations can be separated by either a space or a comma.  

## Position and mutation information
If an integer by itself is entered into **vdb**, the residue/nucleotide at that reference location will be printed along with the number of occurrences and frequencies of mutations at that position. In nucleotide mode, if a single protein (nucleotide) mutation is entered, then the corresponding nucleotide (protein) mutation will be printed.   

## Combining commands
The command parser of **vdb** is still under development, so combinations of commands will work in some cases but not others. Complex queries can nevertheless be performed with **vdb**: variables can be used to save the results of single commands, and these can be used as input to further search commands.  

## Implicit commands  
In a couple situations, **vdb** interprets input as implying the `from` or `lineage` commands. When the first part of an expression is a country or state, this is treated as an implicit `from` command. When a part of an expression appears to be a Pango lineage name (containing periods), if this is not preceded by the `lineage` command, that command is considered implied.  

## Output  
All valid commands should print a response. For commands that involve several steps, output will be printed for each step. If no response is printed, this indicates that there is an error in the input. Some syntax errors are explicitly noted. When printed lists are longer than the terminal display, **vdb** will print the list one page at a time. To advance to the next page, press the space bar. To advance one line at a time, press return or down arrow. To stop printing the list, press `q`.  

## Filtering commands
#### \<cluster> `from` \<country or state>    → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses from the specified country or US state.  
<br />
#### \<cluster> `containing` [\<n>] \<pattern>  → cluster    alias `with`, `w/`  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with the specified mutation pattern. By default only viruses with all the mutations of the specified pattern are returned. If an integer \<n> is specified in the search command, then viruses are returned only if they have at least \<n> of the mutations in the pattern.  
<br />
#### \<cluster> `not containing` [\<n>] \<pattern>   → cluster    alias `without`, `w/o` (full pattern)  

Searches the specified cluster (or all viruses if no cluster is given) for viruses without the specified mutation pattern. All viruses are returned except those that contain the complete mutation pattern. If an integer \<n> is specified in the search command, then viruses are returned only if they have less than \<n> of the mutations in the pattern.  
<br />
#### \<cluster> `before` \<date>        → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with collection date before the specified date.  
<br />
#### \<cluster> `after` \<date>         → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with collection date after the specified date.  
<br />
#### \<cluster> [`range`] \<date>-\<date2>    → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with collection date in the specified range.  
<br />
#### \<cluster> `>` or `<` or `#`\<n>       → cluster    filter by # of mutations  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with greater than (or less than, or equal to) the specified number of mutations. In nucleotide mode, if the specified number is a floating point value between 0.0 and 1.0 inclusive, then this command filters based on sequence completeness.  
<br />
#### \<cluster> `named` \<state_id or EPI_ISL#>  → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses with the specified text string in their virus name field. Or, if a number is specified, returns the virus with that accession number.  
<br />
#### \<cluster> `lineage` \<Pango lineage>   → cluster  

Searches the specified cluster (or all viruses if no cluster is given) for viruses belonging to the specified Pango lineage. A program switch determines whether viruses in sublineages are returned (by default sublineages are included). Lineage names with periods are autodetected, so the keyword `lineage` can be omitted in combined commands.  
<br />
#### \<cluster> `sample` \<number or decimal fraction>   → cluster  

Returns a random subset of the specified cluster, with either the given number of strains or the given fraction of the original cluster.  
<br />

## Commands to find mutation patterns
#### `consensus` [`for`] \<cluster or country or state>   → pattern  

Returns the consensus mutation pattern for the specified cluster. Any mutation present in greater than 50% of the members of the cluster will be included in the consensus list.  
<br />
#### `patterns` [`in`] [\<n>] \<cluster>           → pattern  

Prints a list of the most frequent mutation patterns (indicating number of occurrences) in the specified cluster, and returns the most frequent pattern for assignment to a variable.  If Pango lineage metadata has been loaded, then for each pattern, the most frequent lineage of viruses with that pattern is listed along with the percentage belonging to that lineage.
<br />

## Listing commands
#### `list` [\<n>] \<cluster>  

Lists viruses belonging to the specified cluster along with the mutation pattern of each virus. By default at most 20 members of the cluster are listed. If an integer is specified, then at most that number of members of the cluster are listed. A program switch controls whether the accession number is printed. By default the accession number is not printed.  
<br />
#### [`list`] `countries` [`for`] \<cluster>  

Lists the countries for the viruses belonging to the specified cluster. The number of viruses for each country is printed after the country name.  
<br />
#### [`list`] `states` [`for`] \<cluster>  

Lists the states for the viruses belonging to the specified cluster.  
<br />
#### [`list`] `lineages` [`for`] \<cluster>  

Lists the Pango lineages of the viruses belonging to the specified cluster. The number of viruses for each lineage is printed after the lineage name. Sublineages are not included in this count.  
<br />
#### [`list`] `trends` [`for`] \<cluster>  

For the Pango lineages with the highest counts in specified cluster, this calculates how the fractions of these lineages have changed over time. This information is given as a table and optionally as a graph. `gnuplot` is required for graphs to be generated. The `gnuplot` command file is saved in the current directory as `vdbGraph.txt`. Sublineages are not included in these calculations unless specified by the `group lineages` command.  
<br />
#### [`list`] `frequencies` [`for`] \<cluster>        alias `freq`  

Lists the frequencies of individual mutations among the viruses belonging to the specified cluster.  
<br />
#### [`list`] `monthly` [`for`] \<cluster> [\<cluster2>]  

Lists by month the number of viruses belonging to the specified cluster with a collection date within that month. If a second cluster is specified, then the monthly numbers for that cluster are also listed along with the percentage of the first cluster count vs. the second cluster count. The first cluster should generally be a subset of the second cluster, if present.  
<br />
#### [`list`] `weekly` [`for`] \<cluster> [\<cluster2>]  

Lists by week the number of viruses belonging to the specified cluster with a collection date within that week. If a second cluster is specified, then the weekly numbers for that cluster are also listed along with the percentage of the first cluster count vs. the second cluster count. The first cluster should generally be a subset of the second cluster, if present.  
<br />
#### [`list`] `patterns`  

Lists the built-in and user-defined patterns.  
<br />
#### [`list`] `clusters`  

Lists the built-in and user-defined clusters.  
<br />
#### [`list`] `proteins`

Lists the SARS-CoV-2 proteins and their gene positions.  
<br />
#### [`list`] `variants` [\<cluster>]  

Lists the WHO-designated variants.  
<br />
#### [`list`] `sequence` \<pattern>  

Lists the reconstructed sequence for the specified pattern.  
<br />
#### [`list`] `entropy` [\<cluster>]  

Lists the sum of per site Shannon entropies by week for the specified cluster.  
<br />
#### \<cluster> `track` \<pattern>  

Lists by week the fraction of viruses having each mutation of a specified pattern. Also listed is the fraction of viruses by number of the specified mutations present. This can be used to follow the convergent evolution of mutations across lineages.  
<br />

#
## Other commands
#### `sort` \<cluster>  

Sorts the specified cluster by sample collection date.  
<br />
#### `help` [\<command>]    alias `?`    

Prints a list of **vdb** commands or a description of a specific command.  
<br />
#### `license`  

Prints the license information for **vdb**.  
<br />
#### `history`  

Lists the user-entered commands for the current **vdb** session.  
<br />
#### `load` \<vdb database file>  

Loads the specified **vdb** database file.  
<br />
#### `trim`    

In nucleotide mode this removes extraneous 'N' bases from the mutation list of all viruses in the database. This trimmed version of the database can be saved to a file by the command `save world <filename>`.  
<br />
#### `char` \<Pango lineage>        aliases `characteristics`, `parent`, `info`  

Prints characteristic (consensus) mutations of the specified lineage. Mutations are shown in bold if they are not present in the parent lineage consensus pattern. This command does not include sublineages in its analysis.  
<br />
#### `sublineages` [`direct`] \<Pango lineage>        alias `sub`  

Prints characteristic (consensus) mutations of the sublineages of the specified lineage. Mutations are shown in bold if they are not present in the parent lineage consensus pattern. Optionally only list direct sublineages.  
<br />
#### `diff` \<cluster or pattern> [-] \<cluster or pattern>  

Compares two clusters or patterns. For clusters the consensus mutation patterns are calculated and then compared. Mutations present in only one of the patterns are listed as well as shared mutations.  
<br />
#### `testvdb`     

Runs built-in tests of **vdb**.  
<br />
#### `demo`     

Runs a demonstration of **vdb**.  
<br />
#### `save` \<cluster, pattern, history, list, or tree name> \<file name>  

Saves a list of the viruses in the given cluster to the specified file. Patterns, history, or lists can also be saved. Clusters saved to a file name ending in `.fasta` are saved in FASTA format, otherwise **vdb** format is used. For clusters, two space-separated options can be given after the file name: `m` - create an accompanying metadata file for the given cluster, and `z` - saves the cluster in a compressed format.   
<br />
#### `load` \<cluster name> \<file name>  

Loads the viruses in a file into a cluster with the specified name. If the mutation type (nucleotide/protein) does not match the program mode, the virus set is transformed to match the program mode.  If the file name ends in `.fasta`, then **vdb** loads and automatically aligns nucleotide sequences in FASTA format.  
<br />
#### `group lineages` \<lineage name(s) or named cluster>    alias `group lineage`, `lineage group`  

Designate which lineages should be grouped and displayed in the `trends` tables and graphs. If a single lineage name is given, then all sublineages will be counted as part of that lineage. If multiple lineages are listed, those will be counted under the first lineage name. If a defined cluster is given, viruses in that cluster will be counted under that cluster's name, not as part of their own lineage.   
<br />
#### `lineage groups`     

Lists defined lineage groups. These are used to control the tables and graphs generated by the `trends` command.  
<br />
#### `clear` \<cluster name> or \<lineage group>    

Clears the definition of a variable assigned to a cluster or pattern. Clears the definition used by the `trends` command of a lineage group created by the `group lineages` command.   
<br />
#### `reset`     

Reset program switches to default settings.  
<br />
#### `settings`    

Prints the current state of program settings.  
<br />
#### `mode`    

Prints the current program mode, either protein or nucleotide.  
<br />
#### `count` \<cluster name or pattern name>   

Prints the number of viruses in a named cluster or the number of mutations in a named pattern.  
<br />
#### `//` [\<comment>]  

A comment line, which is ignored.  
<br />
#### `quit`        alias `exit`, control-C, control-D  

Ends the current **vdb** session.  
<br />

## Lineage assignment
#### `prepare`

Prepare **vdb** to assign lineages based on consensus mutation sets.  
<br />
#### `assign` \<cluster name1> [\<cluster name2>]

Assigns Pango lineages to the viruses in the first named cluster. The resulting assignments are placed in a new cluster using the second cluster name, or if no second name is specified, an underscore is added to the original cluster name.  
<br />
#### `compare` \<cluster name1> \<cluster name2>

Compares the lineage assignments of viruses in two clusters.  
<br />
#### `identical` \<cluster name>

Searches for viruses in different lineages in the specified cluster with identical mutation patterns.  
<br />

## Program switches
#### `debug`/`debug off`  

Controls whether debug information regarding tokenizing, parsing, and evaluating commands is printed. By default debug printing is off.  
<br />
#### `listAccession`/`listAccession off`  

Controls whether accession numbers are printed by the `list` command. By default printing of accession numbers is off.  
<br />
#### `listAverageMutations`/`listAverageMutations off`  

Controls whether the average number of mutations is listed for the `monthly` and `weekly` commands. By default this is off.  
<br />
#### `includeSublineages`/`includeSublineages off`/`excludeSublineages`  

Controls whether sublineages are included in the `lineage` search command. By default sublineages are included - the switch is on.  
<br />
#### `simpleNuclPatterns`/`simpleNuclPatterns off`  

Controls whether ambiguous base calls ("N") are ignored for the `patterns` command when in nucleotide mode. By default this is off.  
<br />
#### `excludeNFromCounts`/`excludeNFromCounts off`  

Controls whether to exclude 'N' bases from mutation counts. By default this is on.  
<br />
#### `sixel`/`sixel off`  

Controls whether `trends` graphs (if available via `gnuplot`) are displayed on the terminal using sixel graphics vs. saved to the current directory as the file `vdbGraph.png`. Most terminal emulators cannot display sixel graphics. Those that can include iTerm2 and `xterm` compiled with the `--enable-sixel-graphics` option. `gnuplot` also must be built with the `--with-bitmap-terminals` option. By default sixel is off.  
<br />
#### `trendGraphs`/`trendGraphs off`  

Controls whether the `trends` command produces graphical output. This option is dependent on `gnuplot` being installed. The path to `gnuplot` must be entered into `vdb.swift` before **vdb** is compiled. By default graphing is on.  
<br />
#### `stackGraphs`/`stackGraphs off`  

Controls whether graphs produced by the `trends` command are plotted as stacked graphs vs. line graphs. By default `stackGraphs` is on.  
<br />
#### `completions`/`completions off`  

Controls whether tab completions and hints are offered on the command line. By default `completions` is on.  
<br />
#### `displayTextWithColor`/`displayTextWithColor off`  

Controls whether text is printed on the terminal using colors via ANSI escape codes. If **vdb** output is being redirected to a file, plain text output may be preferred. By default `displayTextWithColor` is on.  
<br />
#### `paging`/`paging off`  

Controls whether text is printed on the terminal by page (like the unix command 'more'). If a list of commands is to be pasted into **vdb**, paging should be turned off. By default `paging` is on, except when run in batch mode.  
<br />
#### `quiet`/`quiet off`  

Controls whether output of list commands being assigned to a variable should be printed or not. By default `quiet` is off.  
<br />
#### `listSpecificity`/`listSpecificity off`  

Controls whether the `frequencies` command displays information about the specificity of a mutation to the given cluster. By default `listSpecificity` is off.  
<br />
#### `treeDeltaMode`/`treeDeltaMode off`  

Controls whether delta mutations from a mutation annotated tree are used when evaluating expressions containing a tree. By default `treeDeltaMode` is off.  
<br />

#### `minimumPatternsCount = `\<n>  

Sets the minimum number of mutations for the `patterns` command. The default value is 0.  
<br />
#### `trendsLineageCount = `\<n>        alias `trends` \<n>  

Sets the number of lineages to include in tables and graphs generated by the `trends` command. The default value is 5.  
<br />
#### `maxMutationsInFreqList = `\<n>  

Sets the maximum number of mutations to list for the `freq` command. The default value is 50.  
<br />
#### `consensusPercentage = `\<n>  

Sets the percentage cutoff for mutations to be included by the `consensus` command. The default value is 50.  
<br />
#### `caseMatching = all/exact/uppercase`  

Determines case matching behavior for virus name searches by the `named` command. `all` is a case-insensitive search (slower), `exact` is case-sensitive (faster), and `uppercase` searches for the uppercase form of the specified search. The default value is `all`.  
<br />
#### `arrayBase = `\<0 or 1>  

For cluster or list subscripts, this setting determines whether zero- or one-based numbering is used. The default value is `0`.  
<br />

## Bracket and tree assignment commands

#### \<cluster name>[\<Int>]                prints info on single isolate  
#### \<cluster name>[\<Int>][\<Int>..\<\<Int>]        prints sequence of isolate over given nucleotide/residue range  
#### \<cluster name> = \<cluster name2>[\<Int>] or [\<Int>-\<Int>] or [\<Int>..\<\<Int>] or [\<Int>...\<Int>]  assigns subset of existing cluster  
#### sequence \<cluster name>[\<Int>]        list reconstructed sequence for single isolate  
<br />

#### \<cluster name> = \<tree name>            makes cluster including all leaf node isolates  
#### \<cluster name> = \<tree name>.all        makes cluster including all leaf and interior nodes  
#### \<cluster name> = \<tree name>[\<node id>].all  makes cluster including all leaf and interior nodes from subtree w/ specified node id  
<br />

#### \<tree name>[\<node id>]                prints info on tree node  
#### \<tree name> = \<tree name2>[\<node id>].copy        makes a deep copy of subtree and assigns to \<tree name>  
#### \<tree name> = \<tree name2>[\<node id>]          assigns subtree with specified node to \<tree name>  
#### \<tree name> = \<tree name2>[\<lineage name>]        finds and assigns subtree that best represents the specified lineage  
#### \<tree name> = \<tree name2>[\<node id> \<node id2>]   finds and assigns the smallest subtree that contains the specified nodes  
#### a = \<tree name> \<mutation>               searches for tree nodes with given mutation (delta mode)  returns cluster  
<br />

#### \<list name>[\<item number>]                a list item from a list  

<br />
Version 3.5
