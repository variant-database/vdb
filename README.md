[![MIT license](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
![Platforms](https://img.shields.io/badge/platforms-macOS%20%7C%20Linux%20%7C%20Windows-lightgrey)
# vdb
A SARS-CoV-2 Mutation Pattern Query Tool

## 1. Purpose

The **vdb** program is designed to query the SARS-CoV-2 mutational landscape. It runs as a command shell in a terminal, and it allows customized searches for mutation patterns over the entire SARS-CoV-2 genome dataset or subsets thereof. These patttern searches can be for spike protein mutations or nucleotide mutations over the whole genome.

The **vdb** tool uses a natural syntax, permitting quick searches over various subsets of the data. The two main types of objects in **vdb** are groups of viruses (“clusters”) and groups of mutations (“patterns”). Clusters can be obtained by searching for patterns, and patterns can be obtained by examining clusters. The program does NOT automatically scan for some pre-defined pattern. Instead, the goal of the program is to make it very easy to look around the spike mutational landscape and see what’s there. The **vdb** program can be thought of as a “viewer” (a device for looking), even though it's entirely text-based.

The default cluster to search is the collection of all sequenced SARS-CoV-2 viruses (“world”). Alternatively, a country or a US state can be specified.
To search for all viruses from the United States, enter `from US` or just `us` as part of the search command. A cluster or pattern can be assigned to a variable using an equal sign, `=`.
            
Clusters can be filtered by date, number of mutations, country, and Pango lineage. For example, to find all viruses collected in the US containing both mutations E484K and D614G, and then to see what mutations patterns this set has, use the following two commands:

            VDB> a = us w/ E484K D614G

            VDB> patterns a

## 2. Documentation, reference, and web server

A full description of commands is given [here](Documentation.md).  
A quick reference listing all commands is [here](Quick_Reference.md). This information can also be listed by entering `help` or `?` in **vdb**.  

**vdb** is described in the bioRxiv manuscript [Detection and characterization of the SARS-CoV-2 lineage B.1.526 in New York](https://www.biorxiv.org/content/10.1101/2021.02.14.431043v3).  

A live version of **vdb** running with GISAID sequences is at [vdb.live](http://vdb.live).

Questions about **vdb** can be sent to vdb_support@icloud.com.

## 3. Installation

There are two programs:

**vdbCreate** - this converts multiple sequence alignments (MSA) of SARS-CoV-2 genomes into a file listing spike mutations

**vdb** - this is the query tool

These programs are written in Swift and are run in a terminal. Swift is available at https://swift.org/download/ or as part of Xcode. The programs can be compiled with Swift version 5.3 and higher. To simplify installation each program is distributed as a single, stand-alone source file. If **vdb** is run with nucleotide mutation data, then the file "nuclref.wiv04" should be in the working directory.
To compile the programs, first check that the Swift compiler (`swiftc`) is part of your path. On an Ubuntu system, a command similar to the following (adjusting the path as necessary) is appropriate for a bash shell:

            export PATH=/data/username/swift-5.3.3-RELEASE-ubuntu16.04/usr/bin:$PATH

Next, download the **vdb** repository ("Download ZIP" under the "Code" button on the top level **vdb** page). Unzip the file. Then to compile the programs, run these commands (these take < 1 minute):

            swiftc -O vdbCreate.swift
            swiftc -O vdb.swift
            
**Instructions for Windows:** Installation of the Swift compiler on Windows is described at https://www.swift.org/getting-started/. If the python version listed in those instructions is not available, try omitting the version number. Once the Swift compiler is installed, under the Start Menu item for Visual Studio 2019, run "x64 Native Tools Command Prompt for VS 2019" (don't use the regular command prompt). Then change to the directory with the **vdb** source files and enter the following commands:

              swiftc -O -sdk %SDKROOT% -I %SDKROOT%/usr/lib/swift -L SDKROOT%/usr/lib/swift/windows -emit-executable -o vdbCreate.exe vdbCreate.swift
              swiftc -O -sdk %SDKROOT% -I %SDKROOT%/usr/lib/swift -L SDKROOT%/usr/lib/swift/windows -emit-executable -o vdb.exe vdb.swift

Any questions about the installation process can be sent to vdb_support@icloud.com.

## 4. Data files

The sequence alignment of viral genomes can be downloaded from [GISAID](https://www.gisaid.org). This requires registration with GISAID, agreeing to GISAID terms of use, and an account. Note that among these terms of use are the following requirements: (1) to not share or re-distribute the data to any third party, (2) to make best efforts to collaborate with the originating laboratories who provided the data to GISAID, and (3) to acknowledge the originating and submitting laboratories in any publication with results obtained by analyzing this data.  

On the GISAID EpiCov “Downloads” window, select “MSA full0111 (808MB)” or the latest version in the "Alignment and proteins" section.
Also download the “metadata” file in the "Download packages" section or in the "Genomic epidemiology" section. Uncompress/untar the files and place the FASTA file and the metadata file in the same directory that will be used to run **vdb**. The msa_XXXX.tar.xz file will give a msa_XXXX.fasta file over 200 GB in size. If such a file would be too large, **vdbCreate** can be used without creating this file - see the following section for how to run vdbCreate in this way. One can also download selected sequences from GISAID, add the WIV04 reference sequence, and align these with MAFFT. It is possible to load both the large dataset from the main MSA and a local, manually aligned set. The FASTA sequence identifier lines must have the same format as used by GISAID:

\>hCoV-19/Wuhan/WIV04/2019|EPI_ISL_402124|2019-12-30|China

Manually added sequences without GISAID-assigned accession numbers should use a provisional number slightly greater than the highest accession number in the current dataset.

Other files included in this repository are:

nuclref.wiv04    This is the SARS-CoV-2 genomic sequence reference, which is used when **vdb** is run in nucleotide mode

ref_wiv04      This is the same reference in fasta format, to be used for manual alignments of GISAID sequences

## 5. Running the programs

To run **vdbCreate** to create the mutations list (this takes 5-10 minutes for six million sequences):

            ./vdbCreate msa_0111.fasta

Version 2.3 of **vdbCreate** has the option (`-s`) to use standard input (i.e., a pipe) instead of a file on disk. Thus, the large msa_XXXX.fasta file does not need to be saved to disk. Instead, one can pipe the output of the tar command directly to **vdbCreate** as follows:

            tar -xOf msa_0111.tar.xz msa_0111/msa_0111.fasta|./vdbCreate -s

This will produce an output file named "vdb_msa.txt" or "vdb_msa_nucl.txt" (if the `-N` option is used). This file should be renamed - changing "msa" to the relevant date based on input file. In this example the name should be "vdb_011122.txt" or "vdb_011122_nucl.txt". Alternatively, that output file name could be included in the command: `tar -xOf msa_0111.tar.xz msa_0111/msa_0111.fasta|./vdbCreate -s vdb_011122.txt`.

For the **vdb** program, you can either tell the program what file(s) to load on the command line, or if you do not give a file on the command line, the program will load the most recently modified file with the name vdb_mmddyy.txt:

            ./vdb vdb_011122.txt
            ./vdb

The **vdb** programs can also be used to examine nucleotide mutations. To produce the nucleotide mutation list file, use the -n or -N flag:

            ./vdbCreate -N msa_0111.fasta

The -n excludes ambiguous bases, while the -N flag includes these. The -N flag is necessary to have protein mutations match what is listed in GISAID. The file produced by -N is much larger. This can be useful if one wants to check if a certain region was not resolved in a particular strain, but it is also slower because of the much larger file. Probably the best option is to generate the mutation list file with the -N flag, and then trim this file using **vdb**, which keeps a very small subset of the Ns. This prevents mutation calls at codons such as NNC, which could happen if these Ns are dropped. The `trim` command takes about 30 seconds on a million sequences, and this only needs to be done once since the results can be saved. A possible workflow is  

            ./vdbCreate -N msa_0111.fasta  
            ./vdb vdb_011122_nucl.txt  
            VDB> trim  
            VDB> save world vdb_011122_trimmed_nucl.txt  
            VDB> quit  

Loading the untrimmed vdb nucleotide file can take a large amount of memory. To avoid this, it is possible to run **vdb** in a trim-only mode to produce the trimmed file directly, using only modest memory resources. To do this, run **vdb** with the `-t` command line option:

           ./vdb -t vdb_011122_nucl.txt vdb_011122_trimmed_nucl.txt

To read the resulting file into **vdb** and thereby analyze mutations in nucleotide mode:

            ./vdb vdb_011122_trimmed_nucl.txt
 
or if the trimmed file has not been generated:
 
            ./vdb vdb_011122_nucl.txt 

## 6. Usage notes

One should be aware that the SARS-CoV-2 genome dataset has some artefacts in the sequences and some errors in the metadata. Obvious examples include viruses with incorrect or partial collection date information. Anomalies in the sequences are less obvious, but there is a way to guard against this problem. Unusual sequences are less likely to be an artefact if they have been deposited by multiple laboratories. A virus name often gives an indication of the organization which deposited the sequence.
