#!/bin/bash
# This is a Docker replacement for config.sh
#
# Configuration file for TimeLapse Experiment
# version: v0.3.4

#######################################################
# Experiment Information
#######################################################
# Output directory
    MASTER_DIR=''

# Input directory containing subdirectories with .fastq files for each sample [subdirectories' names must match sample names]
    LINK_BASE=''

# Sample + Control (-4sU) names
    samples=("JS190101" "JS190102" "JS190103" "JS190104")
    #samples=$(<samples.txt)
    prefix=  # Include to avoid typing repetitive part of sample names e.g. Sample_JS190101, Sample_JS190102, etc. => prefix='Sample_'

# Control -4sU names for SNP filtering
    control_samples=("JS190101" "JS190102")

# Organism
    SPECIES='Dm' # (Mm, Dm, Hs) [default: Mm]

# Sequencing reads strandness relative to RNA transcript [depends on library prep and sequencing output]
    READS='RF' # (FR, RF, F)
                    # [FR - STL-seq]
                    # [RF - Clonetech v2]

# Format of reads
    FORMAT="PE" # (PE, SE, NU)
                    # [SE - single end reads]
                    # [NU - including non-unique] (not tested)

# STL experiment data analysis
    STL="FALSE"

# Use HISAT-3N 3-base aligner
    three_base="TRUE"

# TRUE if you want information about mutation by position in addition to mutation by read.
    mut_pos="TRUE"

# Type of browser tracks to generate
    mut_tracks="TC" # ("TC", "GA", "TC,GA")

# Program used for creating browser tracks
    track_prog="bedtools" # (STAR, bedtools)

# Add a 'chr' to each chromosome number during alignment. [Useful when aliner index is number-based, but GTF annotation is chr-based]
    chr_tag="TRUE"

# If using spikeins, enter character string that is common identifier of their gene_names in .gtf file (e.g. _dm)
    # Modify spikein .gtf file with:  sed -r 's/(gene_name ")([^"]*)/\1\2_dm/g'  , then use cat to merge it with sample annotation .gtf
    spikein_name=

# Make additional .bigWig track files
    bigwig="TRUE"

# Minimum base quality to call mutation
    minqual=40

# Which columns to keep in final cB.csv.gz file
    keepcols="sample,sj,io,ei,ai,GF,XF,rname"

# Fragment size in number of reads per fragment file (set to smaller number if smaller memory or more cpus)
    fragment_size=3500000


#######################################################
# System Information
#######################################################
# System setup
    cpus=20 # Number of CPUs used by whole pipeline or by each job task if using SLURM scheduler
    mem=119G # Ammount of memory used by whole pipeline or by each job task
    email="" # Email for status reports (SLURM only)
    JOB_NAME="TimeLapse" # Name of job on cluster and base for output .txt file (SLURM only)
    SLURM="FALSE" # Use SLURM scheduler. If not, pipeline will analyze samples sequentially.

# Path to TimeLapse pipeline scripts home directory
    GIT_PATH='/TimeLapse'

# System paths [Include system path to executables. e.g. /home/user/bin/bowtie2; If your executable path is part of $PATH, leave only executable name e.g. bowtie2]
    BOWTIE2=''
    HISAT2=''
    SAMTOOLS='samtools'
    PIGZ='pigz'
    CUTADAPT='cutadapt'
    GNUPARALLEL='parallel'
    R='R'
    STAR=''
    BEDTOOLS='bedtools'
    BCFTOOLS='bcftools'
    FASTUNIQ='fastuniq'
    IGVTOOLS='igvtools'
    HISAT_3N='hisat-3n'
    BISMARK=''
    BDG2BIGWIG='bedGraphToBigWig'      # Available at: http://hgdownload.soe.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig
    PYTHON='python3'
    TSSCALL=''

# Modules versions [If your computer uses Lmod module system fill in module name. Otherwise leave empty.]
    BOWTIE2_MOD=
    HISAT2_MOD=
    SAMTOOLS_MOD=
    PIGZ_MOD=
    CUTADAPT_MOD=
    HTSEQ_MOD=
    PYSAM_MOD=
    GNUPARALLEL_MOD=
    R_MOD=
    STAR_MOD=
    BEDTOOLS_MOD=
    BCFTOOLS_MOD=
    FASTUNIQ_MOD=
    IGVTOOLS_MOD=
    HISAT_3N_MOD=
    BISMARK_MOD=
    BDG2BIGWIG_MOD=
    PYTHON_MOD=
    TSSCALL_MOD=

# Genome location
    if [[ "$SPECIES" == "Hs" ]]; then
        genome_fasta=
        annotation_gtf=
        HISAT_INDEX=
        BOWTIE_INDEX=
        HISAT_3N_INDEX=
        BISMARK_INDEX=

    elif [[ "$SPECIES" == "Dm" ]]; then
        genome_fasta=
        annotation_gtf=
        HISAT_INDEX=
        BOWTIE_INDEX=
        HISAT_3N_INDEX=
        BISMARK_INDEX=
    else
        genome_fasta=
        annotation_gtf=
        HISAT_INDEX=
        BOWTIE_INDEX=
        HISAT_3N_INDEX=
        BISMARK_INDEX=
    fi


#######################################################
# Troubleshooting Mode (Set FALSE to skip pipeline step)
#######################################################
    step_scripts="TRUE" # Set up folders and copy scripts
    step_copyfq="TRUE" # Copy fq files into directory
    step_fastuniq="TRUE" # Run FastUniq
    step_cutadapt="TRUE" # Make trimmed fastq files
    step_align="TRUE" # Align reads
    step_readfilter="TRUE" # Filter reads
    step_feature_count="TRUE" # Count using HTSeq
    step_fragment="TRUE" # Fragment sam into many files
    step_norm="TRUE" # Make normalization file
    step_vcf="TRUE" # Call SNPs with VCF tools
    step_muts="TRUE" # Call mutations
    step_tracks="TRUE" # Make tracks
    step_master="TRUE" # Make master count file
    step_spliceRates="FALSE" # Calculate splicing rates *Requires installation of Rcube package

    cleanup="TRUE" # Remove intermediate files
    R_debug="FALSE" # More verbose R output for easier debugging


#######################################################
# Scripts Versions (Should only need to be changed with new versions)
#######################################################
    SETUP_SCRIPT="$GIT_PATH"/setup.sh

    if [[ "$FORMAT" == 'SE' ]]; then
      PREPROCESS_SCRIPT="$GIT_PATH"/preprocess_SE.sh
    else
      PREPROCESS_SCRIPT="$GIT_PATH"/preprocess.sh
    fi

    if [[ "$STL" == 'TRUE' ]]; then
        if [[ "$three_base" == 'TRUE' ]]; then
          ALIGNMENT_SCRIPT="$GIT_PATH"/bowtie2_Bis.sh
        else
          ALIGNMENT_SCRIPT="$GIT_PATH"/bowtie2.sh
        fi
    else
        if [[ "$three_base" == 'TRUE' ]]; then
          ALIGNMENT_SCRIPT="$GIT_PATH"/hisat_3n.sh
        else
          ALIGNMENT_SCRIPT="$GIT_PATH"/hisat2.sh
        fi
    fi

    SORT_FILTER_SCRIPT="$GIT_PATH"/sort_filter.sh
    FEATURE_COUNT_SCRIPT="$GIT_PATH"/htseq.sh
    TLhtseq_count="$GIT_PATH"/count_triple.py
    FRAGMENT_SCRIPT="$GIT_PATH"/fragment.sh
    RUN_SNP_NORM="$GIT_PATH"/run_snp_norm.sh
    NORMALIZE_R="$GIT_PATH"/norm.R
    FRAGMENT_AWK="$GIT_PATH"/fragment_sam.awk

    TLpreprocess="$GIT_PATH"/sample_preprocess.sh
    TLmuts="$GIT_PATH"/sample_muts.sh

    TLmut_call="$GIT_PATH"/mut_call.py
    TLcount2tracks="$GIT_PATH"/count_to_tracks.py
    TLtracks="$GIT_PATH"/tracks.sh
    TLmakeIGVsession="$GIT_PATH"/make_igv_session.sh
    TLmaster="$GIT_PATH"/master.sh
    TSScall="$GIT_PATH"/make_cB_TSS.sh
    TLfunctionsR="$GIT_PATH"/Functions.R

    TLsplice_ratesR="$GIT_PATH"/splice_rates.R


###  End of config file  ###
