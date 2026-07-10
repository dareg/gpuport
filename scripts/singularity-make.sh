#!/bin/bash

export TMPDIR=$HOME/tmp
export SINGULARITY_TMPDIR=$HOME/tmp

cd $TMPDIR

base=ubuntu:26.04
image=$base-hpc

cat -> singularity.$image.def << EOF
Bootstrap: docker

From: $base

%files
  /usr/local/share/ca-certificates/meteo-fr.crt /usr/local/share/ca-certificates/meteo-fr.crt
  /usr/local/share/ca-certificates/proxy1.crt   /usr/local/share/ca-certificates/proxy1.crt
  singularity.$image.def /singularity.def


%post
  DEBIAN_FRONTEND=noninteractive TZ=Europe/Paris \
  ln -fs /usr/share/zoneinfo/Europe/Paris /etc/localtime && \
  echo "Europe/Paris" > /etc/timezone && \
  apt update && \
  apt full-upgrade -y && \
  apt install -y unminimize && \
  yes | unminimize && \
  apt install -y command-not-found liblocal-lib-perl cmake make gcc gfortran git tzdata wget libwww-perl locales vim-nox \
                 man man-db manpages manpages-dev libxml-libxml-perl g++ perl-doc build-essential libgcc-13-dev \
                 libperl-dev libjson-perl libyaml-perl libdbi-perl cpanminus sqlite3 libsqlite3-dev environment-modules libterm-readline-perl-perl \
                 fypp libdbd-sqlite3-perl libopenmpi-dev openmpi-bin apt-file pciutils gdb psmisc htop libxml2-dev libpmix-dev \
                 libcurl4-openssl-dev xterm screen libxml2-utils tree time gawk bison flex gh curl ca-certificates rsync libaec-dev \
                 python3 python3-pip python3-venv strace valgrind ltrace linux-perf jq proxychains4 python3-setuptools libfile-type-perl \
                 clang-22 flang-22 && \
  update-ca-certificates && \
  sed -i 's/^# *fr_FR.UTF-8 UTF-8/fr_FR.UTF-8 UTF-8/' /etc/locale.gen && \
  locale-gen && \
  mandb && \
  apt update && \
  apt install -y --allow-downgrades tar=1.35+dfsg-4 && \
  apt-file update && \
  echo 'source /usr/share/modules/init/bash' >> /etc/bash.bashrc && \
  rm -rf /home/ubuntu && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/*

%environment
  export GIT_SSL_NO_VERIFY=true
  export LANG=fr_FR.UTF-8
  export LANGUAGE=fr_FR:fr
  export LC_ALL=fr_FR.UTF-8

EOF

prefix=$(dirname $0)
prefix=$(dirname $prefix)

singularity build --fakeroot $prefix/.singularity.sif singularity.$image.def

\rm -f singularity.$image.def

