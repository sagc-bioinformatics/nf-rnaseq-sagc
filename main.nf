#!/usr/bin/env nextflow 

/*
################################################################################
Nextflow Definitions
################################################################################
*/

nextflow.enable.dsl=2
version = '0.0.1'

/*
################################################################################
Accessory functions to include
################################################################################
*/

include {callHelp; checkAndSetArgs; printArguments} from './lib/utilities.nf'

/*
################################################################################
Checking and printing input arguments
################################################################################
*/

callHelp(params, version)                 // Print help & version
checked_arg_map = checkAndSetArgs(params) // Check args for conflics
printArguments(checked_arg_map)           // Print pretty args to terminal

/*
################################################################################
Implicit workflow: Run the RNA-seq sub-workflow
################################################################################
*/

workflow {

  // Workflows
  include { BCL2FASTQ } from './workflows/bcl2fastq' params(checked_arg_map)
  include { RNASEQ } from './workflows/rnaseq' params(checked_arg_map)
  //   include { DEMULTIPLEX } from './workflows/demultiplex' params(checked_arg_map)

  // SAGC sequencing run
  if (checked_arg_map.path_bcl) {

    BCL2FASTQ()
    BCL2FASTQ.out.bcl2fq_reads.set { reads }
    BCL2FASTQ.out.bcl2fq_stats.set { stats }

    // // Bulk RNAseq - UMI in R1 and reads in R2
    // if(checked_arg_map.multiplex) {
    //   BCL2FASTQ()
    //   DEMULTIPLEX(BCL2FASTQ.out.bcl2fq)
    //   DEMULTIPLEX.out.sabre.set { reads }
    
    // // Normal sequencing run - paired or single with/without umi
    // } else {
    //    BCL2FASTQ()
    //    BCL2FASTQ.out.bcl2fq_reads.set { reads }
    //    BCL2FASTQ.out.bcl2fq_stats.set { stats }
    // }
  
  // Custom dataset
  } else {
    Channel.empty().set { reads } // Only needed if BCL2FASTQ not being used
  }

  // RNA-seq sub-workflow
  RNASEQ(reads)

}

