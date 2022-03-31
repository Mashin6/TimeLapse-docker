#!/bin/bash
# This is a Docker replacement for run.sh script
#
# This is a wrapper script that allows running TimeLapse pipeline without need to change email information in runscript.sh
#


function PrintUsage {
    echo "Docker image of pipeline for analyzing TimeLapse data"

    echo " parameters:
            SAMPLES              - comma-separated list of all sample and control names
            CONTROLS             - comma-separated list of -s4U control name(s)
            PREFIX               - avoid typing repetitive part of sample names e.g. \"Sample_*\" (default: none)
            GENOME               - species [Hs, Mm, Dm]  (default: Mm)
            FORMAT               - reads format [PE, SE, NU]  (default: PE)
            READS                - reads strandness [FR, RF, F]  (default: RF)
            MUT_TRACKS           - Mutation type(s) to analyze [TC, GA, TC,GA] (default: TC)
            STL                  - experiment is STL (default: off)
            MUT_POS              - call mutations by absolute genomic location (default: TRUE)
            BIGWIG               - Make additional .bigWig track files (default: TRUE)
            CHR_TAG              - add chr prefix to chromosome names during alignment (default: FALSE)
            SPIKEIN_NAME         - common string identifying spikein names in .gtf file
            FASTA                - path to genome fasta file
            GTF                  - path to gtf genome annotation file
            INDEX                - path to aligner genome index (HISAT-3N)
            CPUS                 - number of cpus used by pipeline or Slurm jobs [int] (default: 10)
            MEM                  - memory used by Slurm jobs [intG](default: 20G)
    "

    echo 'docker run -it -e SAMPLES=LC210501_1in,LC210501_2A \
               -e CONTROLS=LC210501_1in \
               -e SPECIES=Hs\
               -e CPUS=10 \
               -e MEM=20G \
               -e FORMAT=PE \
               -e MUT_TRACKS=TC \
               -e BIGWIG=TRUE \
               -e FASTA=genome/GRCh38_dm6_dm.fa \
               -e GTF=genome/GRCh38_dm6_dm.gtf \
               -e INDEX=genome/GRCh38_dm6_dm \
               -v ${PWD}:/data \
               timelapse
    '

    echo "Sequencing .fastq(.gz) files must be in fastq directory. Every sample must be in its separate sub-directory inside fastq directory.
Sub-directory name must match the sample name.

     ./fastq ┬─ Sample1 ┬─ reads_R1.fastq
             │          ├─ reads_R2.fastq
             │          ┊
             ├─ Sample2 ┬─ reads_R1.fastq
             │          ├─ reads_R2.fastq
             ┊          ┊                 
    "
    exit
}


GIT_PATH=$( cd "$( dirname "$0" )" >/dev/null 2>&1 && pwd )

if [ ! -z "$SAMPLES" ]; then
    samples=$(echo "$SAMPLES" | sed 's/,/ /g')
fi

if [ ! -z "$CONTROLS" ]; then
    control_samples=$(echo "$CONTROLS" | sed 's/,/ /g')
fi

LINK_BASE=${INPUTDIR:-"/data/fastq"}
MASTER_DIR=${OUTPUTDIR:-"/data/processed_data"}
SPECIES=${SPECIES:-"Hs"}
FORMAT=${FORMAT:-"PE"}
READS=${READS:-"RF"}
mut_tracks=${MUT_TRACKS:-"TC"}
prefix=${PREFIX:-}
three_base="TRUE"
STL=${STL:-"FALSE"}
mut_pos=${MUT_POS:-"TRUE"}
chr_tag=${CHR_TAG:-"FALSE"}
spikein_name=${SPIKEIN_NAME:-}
bigwig=${BIGWIG:-"TRUE"}
SLURM="FALSE"
JOB_NAME="TimeLapse"
cpus=${CPUS:-10}
mem=${MEM:-20G}
email=
fasta="/data/"$FASTA
annotation="/data/"$GTF
genome_index="/data/"$INDEX

# Check if all required parameters were set
if [[ ! $FORMAT = "PE" ]] && [[ ! $FORMAT = "SE" ]] && [[ ! $FORMAT = "NU" ]]; then
    echo '!!! Format of reads must be PE, SE or NU'
    PrintUsage
fi

if [[ ! $READS = "FR" ]] && [[ ! $READS = "RF" ]] && [[ ! $READS = "F" ]]; then
    echo '!!! Format of reads must be PE, SE or NU'
    PrintUsage
fi

if [[ ! $mut_tracks = "TC" ]] && [[ ! $mut_tracks = "GA" ]] && [[ ! $mut_tracks = "TC,GA" ]]; then
    echo '!!! Mutation type must be TC, GA or TC,GA'
    PrintUsage
fi

if [[ -z $FASTA ]] || [[ -z $GTF ]] || [[ -z $INDEX ]]; then
    echo '!!! Genome annotation (.gtf), sequence (.fa) and index (hisat-3n) must be provided'
    PrintUsage
fi

if  [ -z "$samples" ] || \
[ -z "$control_samples" ] || \
[ -z "$LINK_BASE" ] || \
[ -z "$MASTER_DIR" ]; then
    echo '!!! You must provide samples and control names, input and output directory'
    PrintUsage
fi




# Create copy of config file and modify with provided parameters
configFile="${GIT_PATH}/config.sh"
currentDate=$(date +"%y%m%d-%H%M%S")

sed -r \
    "s/(^[[:space:]]*samples=).*/\1($samples)/ ; \
     s/(^[[:space:]]*control_samples=).*/\1($control_samples)/ ; \
     s|(^[[:space:]]*LINK_BASE=).*|\1\'$LINK_BASE\'| ; \
     s|(^[[:space:]]*MASTER_DIR=).*|\1\'$MASTER_DIR\'| ; \
     s/(^[[:space:]]*prefix=).*/\1$prefix/ ; \
     s/(^[[:space:]]*SPECIES=).*/\1$SPECIES/ ; \
     s/(^[[:space:]]*FORMAT=).*/\1$FORMAT/ ; \
     s/(^[[:space:]]*READS=).*/\1$READS/ ; \
     s/(^[[:space:]]*mut_tracks=).*/\1$mut_tracks/ ; \
     s/(^[[:space:]]*bigwig=).*/\1$bigwig/ ; \
     s/(^[[:space:]]*three_base=).*/\1$three_base/ ; \
     s/(^[[:space:]]*STL=).*/\1$STL/ ; \
     s/(^[[:space:]]*mut_pos=).*/\1$mut_pos/ ; \
     s/(^[[:space:]]*chr_tag=).*/\1$chr_tag/ ; \
     s/(^[[:space:]]*spikein_name=).*/\1$spikein_name/ ; \
     s/(^[[:space:]]*cpus=).*/\1$cpus/ ; \
     s/(^[[:space:]]*mem=).*/\1$mem/ ; \
     s/(^[[:space:]]*SLURM=).*/\1$SLURM/ ; \
     s/(^[[:space:]]*JOB_NAME=).*/\1$JOB_NAME/ ; \
     s/(^[[:space:]]*email=).*/\1$email/ ; \
     s|(^[[:space:]]*GIT_PATH=).*|\1\'$GIT_PATH\'| ; \
     s|(^[[:space:]]*genome_fasta=).*|\1\'$fasta'|g ; \
     s|(^[[:space:]]*annotation_gtf=).*|\1\'$annotation'|g ; \
     s|(^[[:space:]]*.+_INDEX=).*|\1\'$genome_index'|g" $configFile > ${GIT_PATH}/config_${currentDate}.sh

     # explanation: match: (any number of tabs/spaces + variable=) + rest of the line
     #              replace with: text matched with pattern inside () + replacement text


configFile="${GIT_PATH}/config_${currentDate}.sh"
set -- "$configFile"
source $1



# Start pipeline
$GIT_PATH/runscript.sh $1


