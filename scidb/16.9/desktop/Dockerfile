FROM esensing-scidb:16.9

LABEL maintainer="e-sensing team <esensing-team@dpi.inpe.br>"

VOLUME /data
VOLUME /var/lib/postgresql/data

# ##############################################################################
# Custom Arguments

# Cluster Name for Create SciDB Module
ARG CLUSTER=esensing

# ##############################################################################
# Exporting SCIDB 
EXPOSE 1239

# ##############################################################################
# Creating docker-entry.sh
RUN echo '#!/bin/bash\n\
service ssh start \n\
service postgresql start \n\
wait_for_postgres.sh\n' | tee -a /docker-entrypoint.sh \
    && echo "if [ ! -f ${DATA_DIR}/scidb.config.lock ]; then\n\
      touch ${DATA_DIR}/scidb.config.lock\n\
      echo 'First startup' \n\
      echo 'Configurating SciDB cluster [$CLUSTER]' \n\
      # Creating Data folder and changing owner to scidb\n\
      mkdir -p $DATA_DIR/scidb\n\
      chown -R scidb:scidb $DATA_DIR/scidb\n\
      create_scidb_cluster.sh $CLUSTER\n\
      scidb.py startall $CLUSTER\n\
      # Configuring SciDB Plugins\n\
      iquery -aq \"load_library('dev_tools')\"\n\
      echo \"Installing Stream...\"\n\
      iquery -aq \"install_github('paradigm4/stream', 'd3f5393e5a9a8eba6f8ff777105ef031f48e3d3d');\"\n\
      iquery -aq \"load_library('stream');\"\n\
    else\n\
      scidb.py startall $CLUSTER\n\
    fi" | tee -a /docker-entrypoint.sh \
    && echo "trap \"scidb.py stopall $CLUSTER; service postgresql stop\" EXIT HUP INT QUIT TERM \n\
bash" | tee -a /docker-entrypoint.sh \
    && chmod +x /docker-entrypoint.sh

ENTRYPOINT /docker-entrypoint.sh
