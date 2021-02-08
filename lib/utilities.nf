def printVersion(String version) {
    println(
        """
        ==============================================================
                  SAGC RNA-SEQ NEXTFLOW PIPELINE ${version}           
        ==============================================================
        """.stripIndent()
    )
}

def printHelpMessage() {
    println(
        """
        You are running the SAGC RNA-seq Nextflow pipeline. 

        Arguments to come...
        """.stripIndent()
    )
}

def callHelp(Map args, String version) {

    if(args.help == true) {
        printVersion(version)
        printHelpMessage()
        System.exit(0)
    }

}

// Exit if any of the required arguments are 'false'
def requiredArgs(Map args) {
    def requiredArguments = [ 'library_type', 'library_ext', 'genome',
                              'samplesheet', 'outdir', 'email', 'profile']

    subset = args.subMap(requiredArguments)
    
    subset.each { key, value ->
        if(!value){
            if(key == 'samplesheet') {
                if(!args.path_bcl) {
                    println("ERROR: Missing argument --$key")
                    printHelpMessage()
                    System.exit(1)
                };
            } else if(key == 'library_ext') {
                if(!args.path_bcl) {
                    println("ERROR: Missing argument --$key")
                    printHelpMessage()
                    System.exit(1)
                }
            } else {
                println("ERROR: Missing argument --$key")
                printHelpMessage()
                System.exit(1)
            }
        }
    }
    return subset
}

def checkUnderscoreInSampleName(csvPath) {
    File csv = new File(csvPath)
    def lst = csv.readLines()

    start = lst.indexOf('[Data]') + 2
    lst[ start..-1 ].each{ line ->
        if(line.tokenize(',')[1].contains('_')) {
            println("ERROR: Illumina sample sheet contains underscores (_) in sample names (second column). Please replace with hyphens (-).")
            System.exit(1)
        }
    }
}

def checkAndSetArgs(Map args) {

    // Temporary Map object
    def temp = [:]
    def hpc_partition = [ 'sahmri_prod_hpc', 'sahmri_cancer_hpc' ]
    def hpc_nodelist_prod = ['edp-prd-lin-hpc01', 'edp-prd-lin-hpc02',
                             'edp-prd-lin-hpc03','edp-prd-lin-hpc04',
                             'edp-prd-lin-hpc05', 'edp-prd-lin-hpc06']
    def hpc_nodelist_cancer = ['edp-prd-lin-hpc07', 'edp-prd-lin-hpc08']

    // Arguments not to be printed
    drop = [ 'genomes', 'help' ] // Makes for clean output

    // Check required arguments are supplied
    requiredArgs(args)

    // No samplesheet path - can only proceed if path_bcl is not 'false'
    if(!args.samplesheet) {

        // No path_bcl value - error
        if(!args.path_bcl) {
            println("Error: Values must be passed to either --samplesheet, --path_bcl or to both.")
            System.exit(1)

        // path_bcl provided - use samplesheet in path_bcl directory
        } else {
            File ss = new File(args.path_bcl + '/SampleSheet.csv')

            try {
                assert ss.exists()
            } catch (AssertionError e) {
                println("ERROR: File ${args.path_bcl}/SampleSheet.csv does not exist\nError message: " + e.getMessage())
                System.exit(1)
            }

            // Set samplesheet + csv type arguments
            checkUnderscoreInSampleName(args.path_bcl + '/SampleSheet.csv')
            temp.samplesheet = args.path_bcl + '/SampleSheet.csv'
            temp.csvtype = 'illumina'
        }

    // Value is provided to --samplesheet
    } else {
        
        // File object
        File ss = new File(args.samplesheet)

        // Samplesheet file exists?
        try {
            assert ss.exists()
        } catch (AssertionError e) {
            println("ERROR: File ${args.samplesheet} does not exist\nError message: " + e.getMessage())
            System.exit(1)
        }

        // path_bcl provided - custom Illumina CSV is in use
        if(args.path_bcl) {

            checkUnderscoreInSampleName(args.samplesheet)
            temp.csvtype = 'illumina'
            temp.samplesheet = args.samplesheet
            temp.path_bcl = args.path_bcl

        // custom sequencing run
        } else {
            temp.csvtype = 'user_data'
            temp.samplesheet = args.samplesheet
        }
    }

    // Genome check
    if(!args.genomes.containsKey(args.genome)) {
        println("ERROR: Provided genome " + args.genome + " is not a supported genome version")
        System.exit(1)
    }

    // Umi check
    if((!args.with_umi && args.umi_ext) || (args.with_umi && !args.umi_ext) ) {
        println("ERROR: If your data has umi sequences, please provide both --with_umi and --umi_ext")
        System.exit(1)
    } else {
        temp.with_umi = args.with_umi
        temp.umi_ext = args.umi_ext
    }

    // Check that requested partition and nodes are valid
    if(args.profile) {
        if( args.profile.tokenize(',').contains('slurm') ) {

            // Valid partition selection
            if(!hpc_partition.contains(args.partition)) {
                println("ERROR: Partition ${args.partition} is not valid. Please use either of the following - " + hpc_partition.join(' OR '))
                System.exit(1)
            }

            // Valid node selection
            if( args.partition == 'sahmri_prod_hpc' ) {
                if(!hpc_nodelist_prod.containsAll(args.node_list.tokenize(','))) {
                    println("ERROR: Invalid node selection for partition ${args.partition}\n\tValid: " + hpc_nodelist_prod.join(' , '))
                    System.exit(1)
                }
            }

            if( args.partition == 'sahmri_cancer_hpc' ) {
                if((!hpc_nodelist_cancer.containsAll(args.node_list.tokenize(','))) ) {
                    println("ERROR: Invalid node selection for partition ${args.partition}\n\tValid: " + hpc_nodelist_cancer.join(','))
                    System.exit(1)
                }
            }
        }
    }
    

    // Assign genome files to parameters
    temp.genome_fasta = file(args.genomes[args.genome].fasta)
    temp.genome_gtf = file(args.genomes[args.genome].gtf)
    temp.index = file(args.genomes[args.genome].starIdx)

    // Cleanup and overwrite args
    args = args.findAll({!['genomes', 'help'].contains(it.key)})
    args.putAll(temp)

    return args
}

def printArguments(Map args) {

    required = [ 'library_type', 'library_ext', 'genome', 'outdir',
                 'email', 'samplesheet', 'csvtype', 'path_bcl' ]
    subset_required = args.subMap(required)
    
    genomeRelated = [ 'genome', 'genome_fasta', 'genome_gtf', 'index' ]
    subset_genomeRelated = args.subMap(genomeRelated)
    
    optionalArgs = [ 'umiadd_optional_args', 'featurecounts_optional_args', 
                     'fastp_optional_args', 'umitools_optional_args', 
                     'star_optional_args', 'fastqc_optional_args' ]
    subset_optionalArgs = args.subMap(optionalArgs)
    
    resources = args.findAll { k,v -> !(k in required + genomeRelated + optionalArgs) }.keySet()
    subset_resources = args.subMap(resources)

    lst = [ subset_required, subset_optionalArgs, subset_genomeRelated, subset_resources ]

    println(
        """
        ##################################################
        ################### Arguments ####################
        """.stripIndent())

    lst.each { l -> 
        l.each {key, value ->

            if(value instanceof java.util.ArrayList) {
                println("$key:")
                value.each { v -> 
                    println("  $v")
                }
            } else {
                println("$key: $value")
            }
        }
        println('')
    }
}

def getSampleFromCSV( csvPath,  libExt,  withUmi,  umiExt, retObj) {
    
    File csv = new File(csvPath)
    def csv_lines = csv.readLines()
    csv_lines.remove(0) // Remove header row

    def reads_list = []
    def umi_list = []
    csv_lines.each { line ->
        line_list = line.tokenize(',')

        reads = line_list[0] + '/' + line_list[1] + '*' + libExt
        reads_list.add(reads)

        if(withUmi) {
            i1 = line_list[0] + '/' + line_list[1] + '*'  + umiExt
            umi_list.add(i1)
        }
    }

    // List to return based on argument
    if(retObj == 'umis') {
        return umi_list
    } else {
        return reads_list
    }
}
