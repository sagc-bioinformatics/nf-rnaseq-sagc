#!/usr/bin/env python3

# Script to remove the `Sample_Name` column from Illumina samplesheets.
# This forces 'bcl2fastq' to use the 'Sample_ID' column instead.

import sys

def cleanSamplesheet(path_samplesheet):
    f = open(path_samplesheet, 'r')
    fl = f.readlines()

    # Index of 'Sample_ID' row
    idx = [ i for i, s in enumerate(fl) if 'Sample_ID' in s][0]

    # Column index of 'Sample_ID'
    idx_SID = fl[idx].split(',').index('Sample_Name')

    # Get top section of SampleSheet (up to CSV column names)
    f_top = fl[:idx + 1]
    
    # Iterate over CSV sample information - make 'Sample_Name' column empty
    lst_samples = []
    for l in fl[idx + 1:]:
        l = l.split(',')
        l[idx_SID] = ''
        lst_samples.append(','.join(l))

    with open('nf-SampleSheet.csv', 'w') as out:
        for r in (f_top + lst_samples):
            out.write(str(r))

def main():
    cleanSamplesheet(sys.argv[1])

if __name__ == "__main__":
    main()
