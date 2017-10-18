# Docker SciDB 16.9

This folder contains files for building E-Sensing SciDB 16.09 image. The image contains following resources:

- `SciDB`
- `SciDB devtools` - You must load it using `load_library('dev_tools')`
- `R`
- `sits`

**Note** that it builds a common SciDB image and does not contain `entrypoint` statement. You must implement own container initialization. Take a look into `desktop` for an example.

## Build the Docker image

To build the Docker image, execute the follow commands 
```bash
git clone https://github.com/e-sensing/docker 
cd docker/scidb/16.9/eows
docker build --tag esensing-scidb:16.9 .
```

## Load data to SciDB

We have added a `loader2scidb.sh` script in PATH. This script loads the *SciDB Chunks* into database using *SciDB Binary Format*.
**Note** that SciDB must be running. 

### Variables

- **SDB_INSTANCES** - Number of SciDB instances in the whole cluster;
- **SDB_1D_SCHEMA** - SciDB one-dimensional array to store temporary raw data before apply redimension operation
- **SDB_3D_SCHEMA** - SciDB three-dimensional array scheme
- **SDB_FORMAT** - Target SciDB Format
- **SDB_3D_ARRAY** - SciDB Array name

### Usage

Example using *mod13q1* parameters.

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

# Or loader2scidb.sh chunk*
loader2scidb.sh chunk1 chunk2 chunk3 chunk4
```