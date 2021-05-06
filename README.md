# SAGC RNA-Seq Nextflow Pipeline

<img src="https://github.com/sagc-bioinformatics/nf-rnaseq-sagc/blob/main/docs/figures/sagc-logo.png" width="600" height="300">

This is the main repository for the South Australian Genomics Consortiums' RNA
sequencing quantification pipeline implemented in `Nextflow`.

The pipeline involves the following processes:

* [BCL2fastq](https://sapac.support.illumina.com/sequencing/sequencing_software/bcl2fastq-conversion-software.html): Convert Illumina BCL files to FastQ
* [STAR](https://github.com/alexdobin/STAR): Align RNA-sequences to a reference genome using STAR aligner
* Deduplication: Remove PCR duplicates from aligned BAMs
  * [Umi-tools](https://github.com/CGATOxford/UMI-tools): If sequence data contains UMIs
  * [Sambamba](https://github.com/biod/sambamba): For non-UMI data
* [FeatureCounts](http://subread.sourceforge.net/): Quantify reads to genomic positions (genes, exons, promoters etc...)

## Set up
### Installing Nextflow

As this is a [`Nextflow`](https://www.nextflow.io/) pipeline, `Nextflow` needs to be installed on your system.
Instructions for how to do this are found [here](https://www.nextflow.io/docs/latest/getstarted.html). The basic
steps are as follows:

Check `Java` version. It needs to be __Java 8 or later (up to Java 15)__

```{shell}
$ java --version

java 13.0.1 2019-10-15
Java(TM) SE Runtime Environment (build 13.0.1+9)
Java HotSpot(TM) 64-Bit Server VM (build 13.0.1+9, mixed mode, sharing)
```

Install the `Nextflow` executable. This can be installed wherever you like, just ensure that the binary gets moved
to somewhere in your `$PATH`

```{shell}
$ wget -qO- https://get.nextflow.io | bash
$ mv nextflow /usr/bin                      # For example
```

### Installing the RNA-seq pipeline

All software in the pipeline is configured using [`conda`](https://docs.conda.io/en/latest/), meaning you simply need
to clone the repository to your system.

```{shell}
$ cd <path>/software
$ git clone --recurse-submodules https://github.com/sagc-bioinformatics/nf-rnaseq-sagc.git
```

## Usage

The pipeline is invoked using the following command


```{shell}
$ nextflow run <path>/nf-rnaseq-sagc/main.nf <arguments>
```

To obtain a help message, simply run the following

```{shell}
$ nextflow run <path>/nf-rnaseq-sagc/main.nf --help
```

The help page is shown at the bottom of this `README`.

Below is a simple script that represents invoking the pipeline for a single-end dataset
using SAGC generated data.

```{shell}
#!/usr/bin/env bash

PIPE="<path>/nf-rnaseq-sagc"

nextflow run ${PIPE}/main.nf \
    -profile conda,slurm \
    --library_type single \
    --path_bcl '<path/to/bcl/dir>' \
    --index single \
    --genome HG38 \
    --outdir output-single-end \
    --email user.name@sahmri.com \
    --partition sahmri_prod_hpc \
    --node_list edp-prd-lin-hpc05,edp-prd-lin-hpc06 \
    -resume
```

This script is then able to be run in the background on the HPC (e.g. using `screen`) and will handle:

* Installing the pipeline-software using `Conda` (list of software used: [`conda.yml`](https://github.com/sagc-bioinformatics/nf-rnaseq-sagc/blob/main/lib/conda.yml))
* `SLURM` job submission

## Custom Data

This pipeline has been written with sequence data coming off the SAGC Illumina machines in mind, but can accept
custom user data which is in FastQ format. For custom data sets, a simple CSV file needs to be passed that contains
the directory paths to the files and the basename of the files. An example CSV is below

```{text}
path,name
/path/to/dir,sampleA
/path/to/dir,sampleB
/different/path,sampleC
/different/path/again,sampleD
```

where samples A and B would have the corresponding FastQ files:

```{text}
sampleA_R1.fastq.gz
SampleA_R2.fastq.gz

SampleB_R1.fastq.gz
SampleB_R2.fastq.gz
```

The pipeline will build a regular expression using the columns in the CSV, along with the other
arguments specific to user-data to load the FastQ files for analysis. See below for arguments
relating to non-SAGC sequence files.

### Example Custom FastQ Data Script

Below is an example script for custom fastq data

```{shell}
#!/usr/bin/env bash

PIPE="<path>/nf-rnaseq-sagc"

nextflow run ${PIPE}/main.nf \
    -profile conda,slurm \
    --library_type paired \
    --library_ext '*_R{1,2}.fastq.gz \
    --samplesheet '<path/to/samplesheet.csv> \
    --index dual \
    --genome HG38 \
    --outdir output-paired-end \
    --email user.name@sahmri.com \
    --partition sahmri_prod_hpc \
    --node_list edp-prd-lin-hpc05,edp-prd-lin-hpc06 \
    -resume
```

Where `samplesheet.csv` is structured like the example above.

## Arguments (help page)

```{text}
==============================================================
          SAGC RNA-SEQ NEXTFLOW PIPELINE 0.0.1
==============================================================


A pipeline for RNA-seq quantification via alignment methods.
    * STAR: Splice aware alignment
    * Umi-tools/Sambamba: BAM deduplication
    * Subread FeatureCounts: Quantification

Nextflow Arguments:
    -profile <str>                          Which Nextflow profile to use: SHOULD always be 'conda,slurm'

Arguments: These are mandatory for SAGC datasets
    --library_type <str>                    String indicating 'paired' or 'single' end data (valid: 'paired', 'single')
    --index <str>                           Type of indexing (valid: 'single', 'dual', 'umi')
    --path_bcl <str>                        Directory path to BCL file for sequencing run of interest
    --genome <str>                          Which genome release to use. (Valid: HG38, GRCH37)
    --outdir <str>                          Directory path to output directory. Will be created if it doesn't exist already
    --email <str>                           Your SAHMRI email
    --partition <str>                       SAHMRI HPC partition to use (valid: 'sahmri_prod_hpc', 'sahmri_cancer_hpc')
    --node_list <str>                       SAHMRI HPC nodes to use (valid: sahmri_prod_hpc=edp-prd-lin-hpc0{1,6}, sahmri_cancer_hpc=edp-prd-lin-hpc0{7,8})

Optional Arguments (user provided FastQ data):
    --library_ext <str>                     Regular expression string to match sequence files (E.g. '/path/to/files/*_R{1,2}.fastq.gz')
    --samplesheet <str>                     Path to custom sample sheet in Illumina format (if data is from BCL) or two column CSV; path and file base-name
    --umi_ext <str>                         Regular expression string to match UMI files (E.g. '/path/to/files/*_I1.fastq.gz')

Optional Software Arguments (general):
    --fastp_optional_args <str>             Quoted string of optional arguments to pass to FastP
    --umitools_optional_args <str>          Quoted string of optional arguments to pass to Umi-tools
    --star_optional_args <str>              Quoted string of optional arguments to pass to STAR aligner
    --featurecounts_optional_args <str>     Quoted string of optional arguments to pass to FeatureCounts

The 'Optional Arguments' should only be provided if the sequence data hasn't been generated by the SAGC.
If the data is custom (i.e. not being created from the BCL files), the '--library_ext' argument is used
to pattern match all FastQ files at the specified location. Which files to match are obtained from the
second column in the custom sample sheet. If the custom data has UMIs, then they can be captured too by
providing the '--umi_ext' argument.

Example custom sample sheet (csv):

    path,basename
    /path/to/reads,sampleA
    /path/to/reads,sampleB
    /path/to/reads,sampleC
```