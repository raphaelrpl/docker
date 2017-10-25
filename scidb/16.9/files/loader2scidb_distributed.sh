#!/bin/bash
# build a lists of binary chunk files

if [ -z "$SDB_3D_ARRAY" ]; then
  export SDB_3D_ARRAY=mod13q1
fi

if [ -z "$SDB_3D_SCHEMA" ]; then
  export SDB_3D_SCHEMA="<ndvi:int16, evi:int16, quality:uint16, red:int16,nir:int16, blue:int16, mir:int16, view_zenith:int16, sun_zenith:int16,relative_azimuth:int16, day_of_year:int16, reliability:int8>[col_id=60000:60800:0:40; row_id=48640:49200:0:40; time_id=0:511:0:512]"
fi

if [ -z "$FIRST" ]; then
  export FIRST=200                             # Maximum number of files to list
fi

if [ -z "$SDB_INSTANCES" ]; then
  export SDB_INSTANCES=4                     # SciDB instances in the whole cluster
fi

DATA_PATH=$(dirname "$1")
DATA_NAME_PATTERN=$(basename "$1")

# create a list of files to process and feed them to GNU PARALLEL to avoid 
find $DATA_PATH -type f -name $DATA_NAME_PATTERN | sort | head -n $FIRST > fileslist.txt

echo "Creating array $SDB_3D_ARRAY ... "
iquery -naq "CREATE ARRAY $SDB_3D_ARRAY $SDB_3D_SCHEMA"

parallel --eta --jobs 1 -n $SDB_INSTANCES --arg-file fileslist.txt loader2scidb.sh 
rm fileslist.txt
