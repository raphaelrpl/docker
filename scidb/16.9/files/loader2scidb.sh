#!/bin/bash

#
# Script based in https://github.com/albhasan/gdal2scidb/blob/dev/tests/load_parallel.sh
#
# DESCRIPTION:
# Loads Binary SciDB chunks into SciDB instance.
#
# VARIABLES:
# SDB_INSTANCES_MACHINE - Number of SciDB instances in each machine
# SDB_INSTANCES         - Number of SciDB instances in the whole cluster
# SDB_1D_SCHEMA         - SciDB one instance array to store temporary raw data before apply redimension operation
# SDB_3D_SCHEMA         - SciDB three dimension array scheme
# SDB_FORMAT            - Target SciDB Format (just data types of three-dimension scheme)
# SDB_3D_ARRAY          - SciDB Array name
#
# USAGE:
# ./loader2scidb.sh CHUNKFILE_LIST
#
# WHERE:
# CHUNKFILE_LIST - Represents a list of binary SciDB chunks. You must pass as command argument.
#
# EXAMPLE:
# SciDB Instances: 4
# Chunks: 4
# Description: Array of Sinop (MT - BR)
#
# # Or ./loader2scidb.sh /chunk/*
# ./loader2scidb.sh /chunk/1 /chunk/2 /chunk/3 /chunk/4
#

# Number of SciDB instances in each machine
if [ -z "$SDB_INSTANCES_MACHINE" ]; then
  SDB_INSTANCES_MACHINE=4
fi
# Number of SciDB instances in the whole cluster
if [ -z "$SDB_INSTANCES" ]; then
  SDB_INSTANCES=4
fi

# Path to SciDB Instances
if [ -z "$SDB_INSTANCES_PATH" ]; then
  SDB_INSTANCES_PATH=/data/scidb/16.9/esensing
fi

if [ -z "$SDB_1D_SCHEMA" ]; then
  SDB_1D_SCHEMA="<col_id:int64, row_id:int64, time_id:int64, ndvi:int16,evi:int16, quality:uint16, red:int16, nir:int16, blue:int16, mir:int16,view_zenith:int16, sun_zenith:int16, relative_azimuth:int16,day_of_year:int16, reliability:int8> [i=0:*]"
fi

if [ -z "$SDB_FORMAT" ]; then
  SDB_FORMAT="'(int64,int64,int64,int16,int16,uint16,int16,int16,int16,int16,int16,int16,int16,int16,int8)'"
fi

if [ -z "$SDB_3D_ARRAY" ]; then
  SDB_3D_ARRAY=mod13q1
fi

if [ "$#" -lt 1 ] || [ "$#" -gt $SDB_INSTANCES ]; then
  echo "ERROR: You must provide between 1 and $SDB_INSTANCES binary files"
  exit 1
fi

if [ "$#" -eq $SDB_INSTANCES ]; then
  #-------------------------------------------------------------------------------
  echo "Loading files using all SciDB instances..."
  #-------------------------------------------------------------------------------
  echo "Copying files..."
  count=0

  file_name=$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)
  for f in "$@"; do
    min=$(( $count % $SDB_INSTANCES_MACHINE ))
    mip=`echo $(( $count / $SDB_INSTANCES_MACHINE )) | cut -f1 -d "."`
    cp "$f" $SDB_INSTANCES_PATH/$mip/$min/$file_name &
    # the last one does NOT run in the background
    if [ $count -eq $SDB_INSTANCES ]; then
        cp "$f" $SDB_INSTANCES_PATH/$mip/$min/$file_name
    fi
    count=`expr $count + 1`
  done

  # find $SDB_INSTANCES_PATH/$mip -name $file_name
  sleep 1

  echo "Running SciDB query..."
  iquery -naq "insert(redimension(input($SDB_1D_SCHEMA, '$file_name', -1, $SDB_FORMAT, 1000, shadowArray), $SDB_3D_ARRAY), $SDB_3D_ARRAY)"
  echo "Deleting files..."
  countdel=0
  for f in "$@"; do
    min=$(( $countdel % $SDB_INSTANCES_MACHINE ))
    mip=`echo $(( $countdel / $SDB_INSTANCES_MACHINE )) | cut -f1 -d "."`
    rm --verbose $SDB_INSTANCES_PATH/$mip/$min/$file_name
    countdel=`expr $countdel + 1`
  done
else
  #-------------------------------------------------------------------------------
  echo "Loading files using one SciDB instance..."
  #-------------------------------------------------------------------------------
  for f in "$@"; do
    echo "Copying file..."
    cp "$f" $SDB_INSTANCES_PATH/0/0/p
    echo "Running SciDB query..."
    iquery -naq "insert(redimension(input($SDB_1D_SCHEMA, '/home/scidb/data/0/0/p', -2, $SDB_FORMAT, 0, shadowArray), $SDB_3D_ARRAY), $SDB_3D_ARRAY)"
    echo "Deleting file..."
    rm $SDB_INSTANCES_PATH/0/0/p
  done
fi
