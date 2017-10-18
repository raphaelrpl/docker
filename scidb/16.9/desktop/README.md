# Docker SciDB Desktop 16.9

Builds a SciDB 16.9 image for Desktop environment.

## Build the Docker image

To build the Docker image, execute the follow commands 
```bash
cd /path/to/clone/scidb/16.9/eows/desktop
docker build --tag esensing-scidb-desktop:16.9 .
```

### Example - Load data into SciDB

In this example, we will load images from Sinop - State of Mato Grosso (Brazil) mounted in `/mnt/data/chunks/sinop`. These data are already represented into *SciDB Binary Format* which chunksize is `40`. We have four instances of SciDB running.

```bash
# Number of instances in SciDB
SDB_INSTANCES=4
# Target SciDB Array name
SDB_3D_ARRAY=mod13q1
# mod13q1 scheme in SciDB (3D)
SDB_3D_SCHEMA="<ndvi:int16, evi:int16, quality:uint16, red:int16,nir:int16, blue:int16, mir:int16, view_zenith:int16, sun_zenith:int16,relative_azimuth:int16, day_of_year:int16, reliability:int8>[col_id=60000:60760:0:40; row_id=48640:49080:0:40; time_id=0:511:0:512]"
# mod13q1 scheme in SciDB (1D)
SDB_1D_SCHEMA="<col_id:int64, row_id:int64, time_id:int64, ndvi:int16,evi:int16, quality:uint16, red:int16, nir:int16, blue:int16, mir:int16,view_zenith:int16, sun_zenith:int16, relative_azimuth:int16,day_of_year:int16, reliability:int8> [i=0:*]"
# Represents just data types of 3d array scheme.
SDB_FORMAT="'(int64,int64,int64,int16,int16,uint16,int16,int16,int16,int16,int16,int16,int16,int16,int8)'"

cd /mnt/data/chunks/sinop
# Or just "loader2scidb.sh mod13q1_h12_10_*"
loader2scidb.sh mod13q1_h12_10_2440_640 \
                mod13q1_h12_10_2440_680 \
                mod13q1_h12_10_2440_720 \
                mod13q1_h12_10_2440_760
```