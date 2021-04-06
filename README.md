# vdb
A SARS-CoV-2 Mutation Pattern Query Tool

1. VDB PROGRAM DESIGN GOALS

Use **vdb** to query the spike mutational landscape.

The program **vdb** allows one to search an entire SARS-CoV-2 dataset for spike mutation patterns using a natural syntax. The two main types of objects are groups of viruses (“clusters”) and groups of mutations (“patterns”). Clusters can be obtained by searching for patterns, and patterns can be obtained by examining clusters. The program does NOT automatically scan for some pre-defined bad pattern. Instead, the goal of the program is to make it very easy to look around the spike mutational landscape and see what’s there. The **vdb** program can be thought of as a “viewer” (a device for looking), even though it's entirely text-based.

The default cluster to search is the collection of all sequenced SARS-CoV-2 viruses (“world”).
To search for all viruses from the United States, enter “from US” or just “us”.
A cluster or pattern can be assigned to a variable:

            a = us
            
Clusters can be filtered by date, number of mutations, country, and Pango lineage. For example, to find all viruses collected in the US containing both mutations E484K and N501Y, and then to see what mutations patterns this set has, use the following two commands:

            b = us w/ E484K N501Y
            patterns b

2. INSTALLATION

There are two programs:

**vdbCreate** - this converts multiple sequence alignments (MSA) of SARS-CoV-2 genomes into a file listing spike mutations

**vdb** - this is the query tool

These programs are written in Swift and are run in a terminal. Swift is available at https://swift.org/download/ or as part of Xcode. To simplify installation each program is distributed as a single, stand-alone source file. If **vdb** is run with a nucleotide mutation data, then the file "nuclref.wiv04" should be in the working directory.
To compile the programs, first check that the Swift compiler (`swiftc`) is part of your path. On an Ubuntu system, a command similar to the following (adjusting the path as necessary) is appropriate for a bash shell:

            export PATH=/data/username/swift-5.3.3-RELEASE-ubuntu16.04/usr/bin:$PATH

Then to compile the programs, run these commands (these take < 1 minute):

            swiftc -O vdbCreate.swift
            swiftc -O vdb.swift

3. DATA FILES

The sequence alignment of viral genomes can be downloaded from GISAID (this requires registration with GISAID and an account). On the “Downloads” window, select “MSA full0405 (64MB)” or the latest file in the "Alignment and proteins" section.
Also download the “metadata” file in the "Download packages" section or in the "Genomic epidemiology" section. Uncompress the files and place the FASTA file and the metadata file in the same directory that will be used to run vdb. One can also downloaded selected sequences from GISAID, add the WIV04 reference sequence, and align these with MAFFT. It is possible to load both the large dataset from the main MSA and a more local, manually aligned set. The FASTA sequence identifier lines must have the same format as used by GISAID:

\>hCoV-19/Wuhan/WIV04/2019|EPI_ISL_402124|2019-12-30|China

Manually added sequences without GISAID-assigned accession numbers should use a provisional number slightly greater than the highest accession number in the current dataset.

Other files included in the repository are:

nuclref.wiv04  This is the SARS-CoV-2 genomic sequence reference, which is used when vdb is run in nucleotide mode

ref_wiv04      This is the same reference in fasta format, to be used for manual alignments of GISAID sequences

4. RUNNING THE PROGRAMS

To run **vdbCreate** to create the mutations list (this takes 5-10 minutes):

            ./vdbCreate msa_0405.fasta

For the **vdb** program, you can either tell the program what file(s) to load on the command line, or if you do not give a file on the command line, the program will load the most recently modified file with the name vdb_mmddyy.txt:

            ./vdb vdb_040521.txt
            ./vdb

The **vdb** programs can also be used to examine nucleotide mutations. To produce the nucleotide mutation list file, use the -n or -N flag:

            ./vdbCreate -N msa_0302.fasta
The -n excludes ambiguous bases, while the -N flag includes these (the -N flag is necessary to have protein mutations match what is listed in GISAID).

Then to read the resulting file into **vdb** and thereby analyze mutations in nucleotide mode:

            ./vdb vdb_030221_nucl.txt 


