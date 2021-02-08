# SAGC RNA-Seq Nextflow Pipeline

This is the main repository for the South Australian Genomics Consortiums' RNA
sequencing pipeline implemented in `Nextflow`. In this repository you will find
all source code and documentation relating to the pipeline.

If you have any bugs/issues/feature requests, please start an issue with a detailed
explanation/overview of what needs fixing/implementing and we will review it.

If you wish to contribute to the project, clone the repository, create a development
branch (with an informative name), develop your feature and then create a pull request
for your branch.

## Pipeline Overview

The RNA-seq pipeline is designed to run a standard quantification analysis of RNA-seq
data. The pipeline is as follows:

1. BCL2FASTQ sub-workflow
    * Only run if parameterised to do so
2. Add UMI sequences
    * Only run if paramterised to do so
3. FastQC
4. STAR alignment
5. Deduplication of BAM file
    * Sambamba/umi_tools depending on data type
6. FeatureCounts

## To Do

### Pipeline functionality

* Update genome params file with other genomes
  * GRCh37
  * Mouse
  * ...

### Processes

* Bcl2Fastq
  * Write single-end process
  * Write non-UMI process
* Sabre
  * Implement process for multiplexed bulk single-end RNA
* Kallisto
  * Implement as alternative to FeatureCounts

### Repository

* Write remaining documentation
