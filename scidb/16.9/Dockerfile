FROM ubuntu:14.04
LABEL maintainer="e-sensing team <esensing-team@dpi.inpe.br>"

VOLUME /data
VOLUME /var/lib/postgresql/data

ARG CLUSTER=esensing
ARG MAKE_J=4

# ##############################################################################
# Configuration variables
ENV HOST_IP=127.0.0.1
ENV NET_MASK=$HOST_IP/8
ENV DATA_DIR=/data
ENV SCIDB_USR=scidb
ENV SCIDB_PASS=scidb
ENV SCIDB_VER=16.9
ENV DEV_DIR=/home/$SCIDB_USR/Devel
ENV SCIDB_INSTALL_PATH=/opt/scidb/${SCIDB_VER}
ENV SCIDB_BUILD_TYPE=RelWithDebInfo
ENV SCIDB_SOURCE_PATH=${DEV_DIR}/scidb-${SCIDB_VER}
ENV SCIDB_BUILD_PATH=${SCIDB_SOURCE_PATH}/stage/build
ENV PATH=$SCIDB_INSTALL_PATH/bin:$PATH


# ##############################################################################
# Copying scripts
COPY files/wait_for_postgres.sh /usr/local/bin
RUN chmod +x /usr/local/bin/wait_for_postgres.sh

   
# ##############################################################################
# Creating scidb user
RUN groupadd $SCIDB_USR \
    && useradd $SCIDB_USR -s /bin/bash -m -g $SCIDB_USR \
    && echo $SCIDB_USR:$SCIDB_PASS | chpasswd  \
    && mkdir -p $DEV_DIR \
    && chown $SCIDB_USR:$SCIDB_USR $DEV_DIR \
    && chmod g-w /home/$SCIDB_USR

# ##############################################################################
# Instaling dependencies
RUN apt-get update \
    && apt-get install -y  wget \
						   apt-transport-https \
						   software-properties-common \
						   expect \
						   openssh-server \
						   openssh-client \
						   vim

WORKDIR $DEV_DIR

# ##############################################################################
# Downloading SciDB 16.9
RUN export SCIDB_URL="https://docs.google.com/uc?id=0BzNaZtoQsmy2OG1WcXhiai1rak0&export=download" \
	&& wget --no-verbose --output-document scidb-16.9.0.db1a98f.tgz\
        --load-cookies cookies.txt \
        "$SCIDB_URL `wget --no-verbose --output-document - \
            --save-cookies cookies.txt "$SCIDB_URL" | \
            grep --only-matching 'confirm=[^&]*'`" \
    && mkdir scidb-${SCIDB_VER} \
    && tar -xzf scidb-16.9.0.db1a98f.tgz -C scidb-${SCIDB_VER}

WORKDIR scidb-${SCIDB_VER}

# ##############################################################################
# Providing Passwordless SSH
RUN service ssh start \
    && ssh-keygen -f /root/.ssh/id_rsa -N '' \
    && mkdir /home/$SCIDB_USR/.ssh \
    && ssh-keygen -f /home/$SCIDB_USR/.ssh/id_rsa -N '' \
    && chmod go-rwx /home/$SCIDB_USR/.ssh \
    && cat /root/.ssh/id_rsa.pub >> /root/.ssh/authorized_keys \
    && cat /root/.ssh/id_rsa.pub >> /home/$SCIDB_USR/.ssh/authorized_keys \
    && cat /home/$SCIDB_USR/.ssh/id_rsa.pub >> /home/$SCIDB_USR/.ssh/authorized_keys \
    && chown -R $SCIDB_USR:$SCIDB_USR /home/$SCIDB_USR \
    && ./deployment/deploy.sh access root NA "" $HOST_IP \
    && ./deployment/deploy.sh access $SCIDB_USR NA "" $HOST_IP \
    && ssh $HOST_IP date

# ##############################################################################
## Installing PostgreSQL
RUN service ssh start \
    && ./deployment/deploy.sh prepare_postgresql postgres postgres $NET_MASK $HOST_IP \
    && usermod -G $SCIDB_USR -a postgres \
    && chmod g+rx $DEV_DIR

# ##############################################################################
# Configuring Environment Variables in bashrc files
RUN echo "export SCIDB_VER=16.9\n\
export SCIDB_INSTALL_PATH=${SCIDB_INSTALL_PATH}\n\
export SCIDB_BUILD_TYPE=RelWithDebInfo\n\
export SCIDB_SOURCE_PATH=/home/scidb/Devel/scidb-${SCIDB_VER} \n\
export SCIDB_BUILD_PATH=/home/scidb/Devel/scidb-${SCIDB_VER}/stage/build\n\
export PATH=$SCIDB_INSTALL_PATH/bin:$PATH" | tee -a /root/.bashrc /home/$SCIDB_USR/.bashrc

# ##############################################################################
# Installing Build Tools SciDB
RUN service ssh start \
    && ./deployment/deploy.sh prepare_toolchain $HOST_IP
	
# ##############################################################################
# Building SciDB
RUN service ssh start \
	  && ./run.py setup --force \
    && ./run.py make -j${MAKE_J}

# ##############################################################################   
# Instaling SciDB
	RUN service ssh start \
    && yes n | ./run.py install --light \
    # Moving SciDB extern to SCIDB_INSTALL_PATH to fix Murmurhash dependency
    && mv ${SCIDB_SOURCE_PATH}/extern ${SCIDB_INSTALL_PATH}
    
# ##############################################################################   
# Configuring SciDB
RUN service postgresql start \
    && wait_for_postgres.sh\
    && sudo -u postgres psql -c "ALTER USER "postgres" WITH PASSWORD 'postgres';" \
    && POSTGRES_HOME=$(echo ~postgres) \    
 	  && mkdir -p ${DATA_DIR}/scidb \
    && chown -R ${SCIDB_USR}:${SCIDB_USR} ${DATA_DIR} \
    && chown -R scidb:scidb $SCIDB_INSTALL_PATH

# ##############################################################################
# Installing Dev_tools
RUN git clone https://github.com/Paradigm4/dev_tools \
    && cd dev_tools \
    && make \
    && cp *.so $SCIDB_INSTALL_PATH/lib/scidb/plugins \
    && cd .. \
    && rm -rf dev_tools

# ##############################################################################
# Installing R
RUN echo "deb https://cran.uni-muenster.de/bin/linux/ubuntu/ trusty/" | tee -a /etc/apt/sources.list \
    && apt-key adv --keyserver keyserver.ubuntu.com --recv-keys E084DAB9 \
    && gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 \
    && gpg -a --export E084DAB9 | sudo apt-key add - \
    && add-apt-repository ppa:ubuntugis/ubuntugis-unstable \
    && apt-get update \
    && apt-get install -y libcurl4-openssl-dev \
                          libssl-dev openssl \
                          libxml2-dev \
                          libproj-dev \
                          libudunits2-dev \
                          libgdal20 gdal-bin libgdal-dev \
                          libgl1-mesa-dev freeglut3 freeglut3-dev \
                          r-base r-base-dev

RUN R -e "install.packages('devtools', repos='https://ftp.gwdg.de/pub/misc/cran');\
library(devtools);\
install.packages('tidyverse', repos='https://ftp.gwdg.de/pub/misc/cran');\
library(tidyverse);\
install.packages('plyr', repos='https://ftp.gwdg.de/pub/misc/cran');\
library(plyr);\
install.packages('rgdal', repos='https://ftp.gwdg.de/pub/misc/cran');\
library(rgdal);\
install.packages('sf', repos='https://ftp.gwdg.de/pub/misc/cran');\
library(sf);\
install.packages('rgl', repos='https://ftp.gwdg.de/pub/misc/cran');\
library(rgl);\
install.packages('TSdist', repos='https://ftp.gwdg.de/pub/misc/cran');\
devtools::install_github('e-sensing/sits');\
library(sits)"

# ##############################################################################
# Cleaning up
RUN rm ${DEV_DIR}/scidb-16.9.0.db1a98f.tgz $DEV_DIR/cookies.txt \
    && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY files/create_scidb_cluster.sh /usr/local/bin
COPY files/loader2scidb.sh /usr/local/bin
COPY files/loader2scidb_distributed.sh /usr/local/bin

RUN  chmod +x /usr/local/bin/create_scidb_cluster.sh