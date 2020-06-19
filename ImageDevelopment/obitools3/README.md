The `OBITools3`: A package for the management of analyses and data in DNA metabarcoding   
---------------------------------------------

**Website: <https://metabarcoding.org/obitools3>**

DNA metabarcoding offers new perspectives for biodiversity research [1]. This approach of ecosystem studies relies heavily on the use of Next-Generation Sequencing (NGS), and consequently requires the ability to to treat large volumes of data. The `OBITools` package  satisfies this requirement thanks to a set of programs specifically designed for analyzing NGS data in a DNA metabarcoding context [2] - <https://metabarcoding.org/obitools>. Their capacity to filter and edit sequences while taking into account taxonomic annotation helps to setup tailored-made analysis pipelines for a broad range of DNA metabarcoding applications, including biodiversity surveys or diet analyses.   



**The `OBITools3`.** This new version of the `OBITools` looks to significantly improve the storage efficiency and the data processing speed. To this end, the `OBITools3` rely on an ad hoc database system, inside which all the data that a DNA metabarcoding experiment must consider is stored: the sequences, the metadata (describing for instance the samples), the database containing the reference sequences used for the taxonomic annotation, as well as the taxonomic databases. Besides the gain in efficiency, this new structure allows an easier access to all the data associated with an experiment.   



**Column-oriented storage.** An analysis pipeline corresponds to a succession of commands, each computing one step of the analysis, and where the result of the command *n* is used by the command *n+1*. DNA metabarcoding data can easily be represented in the form of tables, and each command can be regarded as an operation transforming one or several 'input' tables into one or several 'output' tables, which can be used by the next command. Many of the basic operations in a pipeline copy without modification an important part of the input tables to the result tables, and use for their calculations only a small part of the input data. In the original `OBITools`, those tables are kept in the form of annotated sequence files in the FASTA or FASTQ format. This has two consequences: i) keeping the transitional results of the analysis pipeline means using disk space for an important volume of redundant data, ii) The coding and decoding of informations that are not actually used represent an important part of the treatment process. The new database system used by the `OBITools3` (called DMS for Data Management System) relies on column-oriented storage. The columns are immutable and can be assembled in views representing the data tables. This way, the data not modified by a command in an input table can easily be associated to the result table without duplicating any information ; and the data not used at all by a command can be associated with the result table without being read. This strategy results in a gain in disk space efficiency by limiting data redundancy, as well as a gain in execution time by limiting data reading, writing and conversion operations. Finally, as a mean to optimize data access, each column is stored in a binary file directly mapped in memory for reading and writing operations.   



**Storage optimization.** DNA metabarcoding data is intrinsically very redundant. For example, the same sequence corresponding to a species will be present several thousand times across all samples. In order to limit the disk space used and make comparison operations more efficient, data in the form of character strings is stored in columns using a complex indexing structure, efficient on millions of values, coupling hash functions, Bloom filters and AVL trees. Finally, DNA sequences are compressed by encoding each nucleotide on two or four bits depending on whether the sequences contain only the four nucleotides (A, C, G, T) or use the IUPAC codes.   



**Saving the data processing history.** The totality of the informations used by the `OBITools3` is stored in immutable data structures in the DMS. If a command has to modify a column used as input to produce its result, a new version of that column is created, leaving the initial version intact. This storage system enables to keep, at minimal cost, the totality of the transitional results produced by the pipeline. The storage of metadata describing all the operations that have produced a view (a result table) in the DMS makes possible the creation of an oriented hypergraph, where each node corresponds to a view and each arrow to an operation. By retracing the dependency relationships in this hypergraph, it is possible to rebuild *a posteriori* the entirety of the process that has produced a result table.   



**Tools.** The `OBITools3` offer the same tools as the original `OBITools`, plus `ecoPCR` (*in silico* PCR) [4] and `Sumatra` (sequence alignment, not multithreaded yet) [5]. 
Eventually, new versions of `ecoPrimers` (PCR primer design) [3], as well as `Sumaclust` (sequence alignment and clustering) [5] will be added, taking advantage of the database structure developed for the `OBITools3`.    



**Implementation and disponibility.** The lower layers managing the DMS as well as all the compute-intensive functions are coded in `C99` for efficiency reasons. A `Cython` (<http://www.cython.org>) object layer allows for a simple but efficient implementation of the `OBITools3` commands in `Python 3`. The `OBITools3` are now being released, check the wiki for more information.



**References.**

1. Taberlet P, Coissac E, Hajibabaei M, Rieseberg LH: Environmental DNA. Mol Ecol 2012:1789–1793.
2. Boyer F, Mercier C, Bonin A, Le Bras Y, Taberlet P, Coissac E: OBITools: a Unix-inspired software package for DNA metabarcoding. Mol Ecol Resour, 2016: 176-182.
3. Riaz T, Shehzad W, Viari A, Pompanon F, Taberlet P, Coissac E: ecoPrimers: inference of new DNA barcode markers from whole genome sequence analysis. Nucleic Acids Res 2011, 39:e145.
4. Ficetola GF, Coissac E, Zundel S, Riaz T, Shehzad W, Bessière J, Taberlet P, Pompanon F: An in silico approach for the evaluation of DNA barcodes. BMC Genomics 2010, 11:434.
5. Mercier C, Boyer F, Bonin A, Coissac E (2013) SUMATRA and SUMACLUST: fast and exact comparison and clustering of sequences. Available: <http://metabarcoding.org/sumatra> and <http://metabarcoding.org/sumaclust>
