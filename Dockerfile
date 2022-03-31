### Get Linux image

FROM debian:buster-backports

RUN apt-get -yqq update \
    && apt-get -yqq install build-essential \
    && apt-get -yqq install curl \
    && apt-get -yqq install parallel \
    && apt-get -yqq install git \
    && apt-get -yqq install pigz \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-key '95C0FAF38DB3CCAD0C080A7BDC78B2DDEABC47B7' \
    && echo "deb http://cloud.r-project.org/bin/linux/debian buster-cran40/" >> /etc/apt/sources.list \
    && apt-get -yqq update \
    && apt-get -yqq install -t buster-cran40 r-base \
    && apt-get -yqq install default-jre \
    && apt-get -yqq install autoconf automake make gcc perl zlib1g-dev libbz2-dev liblzma-dev libcurl4-gnutls-dev libssl-dev libncurses5-dev \
    && apt-get clean \
    && apt-get purge \
    && rm -rf /var/lib/apt/lists/* /tmp/*

# Install samtools
RUN curl -OL https://github.com/samtools/samtools/releases/download/1.15/samtools-1.15.tar.bz2 \
    && tar -xf samtools-1.15.tar.bz2 \
    && cd samtools-1.15 \
    && ./configure \
    && make \
    && make install


# Install R packages
RUN /bin/sh -c 'Rscript -e "install.packages(c(\"tidyverse\", \"optparse\", \"BiocManager\") , repos = \"http://cran.r-project.org\")" \
                        -e "BiocManager::install(\"edgeR\")"'
ENV LD_LIBRARY_PATH=/usr/local/lib


# Install igvtools
RUN curl -O https://data.broadinstitute.org/igv/projects/downloads/2.12/IGV_2.12.3.zip \
    && unzip IGV_2.12.3.zip \
    && cp -r /IGV_2.12.3/* /usr/bin \
    && rm -rf /IGV_2.12.3/


# Install TimeLapse pipeline code
ARG GIT_NAME
ARG GIT_PWD
RUN git clone https://${GIT_NAME}:${GIT_PWD}@git.yale.edu/SimonLab/TimeLapse.git \
    && cd TimeLapse \
    && git checkout Develop \
    && rm -rf .git*
## TEMP
    # RUN mkdir TimeLapse
    # COPY TimeLapse /TimeLapse
    # RUN rm -rf TimeLapse/.git*
### /TEMP
COPY config-tl-docker.sh TimeLapse/config.sh
COPY run-tl-docker.sh TimeLapse/run.sh


# Install Hisat-3n
RUN git clone https://github.com/DaehwanKimLab/hisat2.git hisat-3n \
    && cd  hisat-3n\
    && git checkout hisat-3n \
    && make \
    && cp /hisat-3n/hisat-3n* /usr/bin/ \
    && cp /hisat-3n/hisat2 /usr/bin/ \
    && cp /hisat-3n/hisat2-* /usr/bin/ \
    && rm -rf /hisat-3n/


# Install Fastuniq
RUN curl -O https://phoenixnap.dl.sourceforge.net/project/fastuniq/FastUniq-1.1.tar.gz \
    && tar -xf FastUniq-1.1.tar.gz \
    && cd /FastUniq/source \
    && make \
    && cp fastuniq /usr/bin/ \
    && rm -rf /FastUniq

# Install bedGraphToBigWig
RUN curl -o /usr/bin/bedGraphToBigWig https://hgdownload.cse.ucsc.edu/admin/exe/linux.x86_64/bedGraphToBigWig \
    && chmod +x /usr/bin/bedGraphToBigWig
    
# Install rest of the dependencies
COPY --from=biocontainers/cutadapt:v1.18-1-deb_cv1 / /
#COPY --from=biocontainers/samtools:v1.9-4-deb_cv1 / /
COPY --from=biocontainers/htseq:v0.11.2-1-deb-py3_cv1 / /
COPY --from=biocontainers/pysam:v0.15.2ds-2-deb-py3_cv1 / /
COPY --from=biocontainers/bedtools:v2.27.1dfsg-4-deb_cv1 / /
COPY --from=biocontainers/bcftools:v1.9-1-deb_cv1 / /

WORKDIR /data

CMD ["/TimeLapse/run.sh"]




# docker run -it -e SAMPLES=LC210501_1in,LC210501_2A \
#                -e CONTROLS=LC210501_1in \
#                -e SPECIES=Hs\
#                -e CPUS=10 \
#                -e MEM=20G \
#                -e FORMAT=PE \
#                -e MUT_TRACKS=TC \
#                -e FASTA=genome/GRCh38_dm6_dm.fa \
#                -e GTF=genome/GRCh38_dm6_dm.gtf \
#                -e INDEX=genome/GRCh38_dm6_dm \
#                -v ${PWD}:/data \
#                tl-pipe


# Build image
# docker build --platform=linux/amd64 -t timelapse . --build-arg GIT_NAME=<NET_ID> --build-arg GIT_PWD=<NET_ID_PASSWORD>

# Inspect image
# docker run -it timelapse bash

# Remove all Docker images and containers
# docker system prune -a







