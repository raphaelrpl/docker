#!/bin/bash

#
# DESCRIPTION:
# Loads Binary SciDB chunks into SciDB instance. **NOTE** that it removes array if there is.
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

if [ "$#" -lt $SDB_INSTANCES ] || [ "$#" -gt $SDB_INSTANCES ] ; then
  echo "ERROR: You must provide $SDB_INSTANCES binary files"
  exit 1
fi

if [ -z "$SDB_1D_SCHEMA" ]; then
  SDB_1D_SCHEMA="<col_id:int64, row_id:int64, time_id:int64, ndvi:int16,evi:int16, quality:uint16, red:int16, nir:int16, blue:int16, mir:int16,view_zenith:int16, sun_zenith:int16, relative_azimuth:int16,day_of_year:int16, reliability:int8> [i=0:*]"
fi

if [ -z "$SDB_3D_SCHEMA" ]; then
  SDB_3D_SCHEMA="<ndvi:int16, evi:int16, quality:uint16, red:int16,nir:int16, blue:int16, mir:int16, view_zenith:int16, sun_zenith:int16,relative_azimuth:int16, day_of_year:int16, reliability:int8>[col_id=60000:60760:0:40; row_id=48640:49080:0:40; time_id=0:511:0:512]"
fi

if [ -z "$SDB_FORMAT" ]; then
  SDB_FORMAT="'(int64,int64,int64,int16,int16,uint16,int16,int16,int16,int16,int16,int16,int16,int16,int8)'"
fi

if [ -z "$SDB_3D_ARRAY" ]; then
  SDB_3D_ARRAY=mod13q1
fi

# TODO: Add directive for cleanup
# echo "Cleaning up before ... "
# iquery -naq "remove(shadowArray)" 2> /dev/null
# iquery -naq "remove($SDB_3D_ARRAY)" 2> /dev/null/

echo "Creating array $SDB_3D_ARRAY ... "
iquery -naq "CREATE ARRAY $SDB_3D_ARRAY $SDB_3D_SCHEMA"

echo "Running SciDB query..."
for f in "$@"; do
  echo -ne "Inserting $f ... "
  iquery -naq "insert(redimension(input($SDB_1D_SCHEMA, '$f', -1, $SDB_FORMAT, 1000, shadowArray), $SDB_3D_ARRAY, false), $SDB_3D_ARRAY)"
done