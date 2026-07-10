#!/bin/bash

nthread=16

set -e
set -x

function installOPENMPI ()
{
  t=$SOURCES/openmpi-5.0.7.tar.gz

  if [ ! -f $t ] 
  then
    wget -O $t https://download.open-mpi.org/release/open-mpi/v5.0/openmpi-5.0.7.tar.gz
  fi

  b=$(basename $t .tar.gz)

  if [ -d "$INSTALL/flang/$VV/openmpi-5.0.7" ]
  then
    return
  fi

  \rm -rf $b 

  tar xf $t

  cd $b

  ./configure --prefix=$INSTALL/flang/$VV/openmpi-5.0.7 --with-pmix

  make -j$nthread
  make install 

  cd ..
}

function installHDF5 ()
{
  t=$SOURCES/hdf5-1.14.6.tar.gz

  if [ ! -f $t ]
  then
    wget -O $t https://support.hdfgroup.org/releases/hdf5/v1_14/v1_14_6/downloads/hdf5-1.14.6.tar.gz
  fi

  b=$(basename $t .tar.gz)

  if [ -d "$INSTALL/flang/$VV/hdf5/1.14.3" ]
  then
    return
  fi

  \rm -rf $b "$b-build"

  tar xf $t

  #FFLAGS="-Wl,--allow-shlib-undefined" \
  cmake -S $b -B "$b-build" -DCMAKE_INSTALL_PREFIX=$INSTALL/flang/$VV/hdf5/1.14.3 -DHDF5_ENABLE_Z_LIB_SUPPORT=ON -DHDF5_BUILD_FORTRAN=ON \
  && cmake --build "$b-build" -j$nthread && cmake --install "$b-build"
}

function installNETCDF ()
{
  hdf5prefix=$INSTALL/flang/$VV/hdf5/1.14.3
  netcdf4prefix=$INSTALL/flang/$VV/netcdf4/4.9.2

  if [ -d $netcdf4prefix ]
  then
    return
  fi

  t=$SOURCES/netcdf-c-4.9.3.tar.gz

  if [ ! -f $t ]
  then
    wget -O $t https://github.com/Unidata/netcdf-c/archive/refs/tags/v4.9.3.tar.gz
  fi

  b=$(basename $t .tar.gz)
  netcdf_c=$b
  \rm -rf $b
  tar xf $t

  cd $b
  CFLAGS="-I$hdf5prefix/include -fPIC" \
  LDFLAGS="-L$hdf5prefix/lib -Wl,-rpath,$hdf5prefix/lib" \
  ./configure --prefix=$netcdf4prefix --disable-dap
  make -j$nthread
  make install 
  cd ..

  t=$SOURCES/netcdf-fortran-4.6.2.tar.gz
 
  if [ ! -f $t ]
  then
    wget -O $t https://github.com/Unidata/netcdf-fortran/archive/refs/tags/v4.6.2.tar.gz
  fi

  b=$(basename $t .tar.gz)
  \rm -rf $b
  tar xf $t

  cd $b
  CPPFLAGS="-I$netcdf4prefix/include" \
  FCFLAGS="-fPIC" \
  LDFLAGS="-L$netcdf4prefix/lib -Wl,-rpath,$netcdf4prefix/lib -L$hdf5prefix/lib -Wl,-rpath,$hdf5prefix/lib" \
  ./configure --prefix=$netcdf4prefix
  make -j$nthread
  make install 
  cd ..
}

prefix=$(dirname $0)
prefix=$(dirname $prefix)
prefix=$(realpath $prefix)

INSTALL=$prefix/install
SOURCES=$prefix/sources
TMP=$prefix/tmp

mkdir -p $INSTALL $SOURCES

URL=$1 


if [[ $URL =~ therock-afar-([0-9]+\.[0-9]+\.[0-9]+)- ]]
then
  version=${BASH_REMATCH[1]}
else
  exit 1
fi

VV=22

mkdir -p $TMP
cd $TMP

export PATH=$INSTALL/flang/$VV/bin:$PATH

export FC=flang-22
export CC=clang-22
export CXX=clang++-22

installOPENMPI

installHDF5

installNETCDF

