# TimeLapse Docker

This is a dockerized version of TimeLapse pipeline. Work is still in progress.


## Build
To build the image from scratch, install docker and clone the repository. Then run:

``` bash
cd TimeLapse-docker
docker build --platform=linux/amd64 -t timelapse . --build-arg GIT_NAME={NET_ID} --build-arg GIT_PWD={NET_ID_PASSWORD}
```
Where `{NET_ID}` and `{NET_ID_PASSWORD}` are your credetials to log in into TimeLapse Git repository.


## Run
To run the image, first endure that all .fastq files are in their separate directories named after the respecitve sample and they are all placed in `./fastq` directory. In addition, required are: 1) genome sequence in .fasta file format, 2) genome annotation as .gtf file, 3) hisat-3n genome index files.

Image can be then run as `docker run -it <parameters> -v ${PWD}:/data timelapse`


Or from prebuit image from Docker Hub `docker run -it <parameters> -v ${PWD}:/data machyna/timelapse`


## List of Parameters
```
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
```


e.g.
``` bash
docker run -it -e SAMPLES=LC210501_1in,LC210501_2A \
               -e CONTROLS=LC210501_1in \
               -e SPECIES=Hs\
               -e CPUS=10 \
               -e MEM=20G \
               -e FORMAT=PE \
               -e MUT_TRACKS=TC \
               -e FASTA=genome/GRCh38_dm6_dm.fa \
               -e GTF=genome/GRCh38_dm6_dm.gtf \
               -e INDEX=genome/GRCh38_dm6_dm \
               -v ${PWD}:/data \
               timelapse
```
