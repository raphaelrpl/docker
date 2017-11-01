FROM esensing-scidb

LABEL maintainer="e-sensing team <esensing-team@dpi.inpe.br>"

# ##############################################################################
# Exporting EOWS WebServer Port to be able to access through host machine
EXPOSE 7654

ARG MAKE_J=4

# ##############################################################################
# EOWS - Configuration variables
ENV EOWS_PATH=$DEV_DIR/eows
ENV EOWS_DEPENDENCIES_DIR=$EOWS_PATH/3rdparty
ENV EOWS_CODEBASE=$EOWS_PATH/codebase
ENV EOWS_BUILD_DIR=$EOWS_PATH/build-release
ENV EOWS_INSTALL_DIR=/opt/eows/0.5.0
ENV EOWS_CMAKE_DIR=/opt/cmake
ENV PATH="${EOWS_CMAKE_DIR}/bin:${PATH}"

# ##############################################################################
# Installing CMAKE 3.X
RUN mkdir -p $EOWS_DEPENDENCIES_DIR $EOWS_CODEBASE $EOWS_BUILD_DIR \
    && cd ${EOWS_DEPENDENCIES_DIR} \
    && apt-get update \
    && apt-get remove cmake* -y \
    && wget -O cmake-3.7.2.tar.gz https://cmake.org/files/v3.7/cmake-3.7.2-Linux-x86_64.tar.gz \
    && tar -zxf cmake-3.7.2.tar.gz \
    && mv cmake-3.7.2-Linux-x86_64 ${EOWS_CMAKE_DIR} \
    && rm -rf cmake* \
    && echo "export PATH=${EOWS_CMAKE_DIR}/bin:$PATH" | tee -a /root/.bashrc /home/scidb/.bashrc

# ##############################################################################
# Configure EOWS
RUN git clone https://github.com/e-sensing/eows.git $EOWS_CODEBASE \
    && cd $EOWS_DEPENDENCIES_DIR \
    && cp $EOWS_CODEBASE/bash/install-3rdparty-linux-ubuntu-14.04.sh . \
    && wget -O eows-3rdparty-0.5.0-linux-ubuntu-14.04.tar.gz http://www.dpi.inpe.br/foss/eows/eows-3rdparty-0.5.0-linux-ubuntu-14.04.tar.gz \
    # Compile Dependendies
    && ./install-3rdparty-linux-ubuntu-14.04.sh $EOWS_DEPENDENCIES_DIR \
    && cd ${EOWS_DEPENDENCIES_DIR} \
    && rm -rf ${EOWS_DEPENDENCIES_DIR}/eows-3rdparty-0.5.0-linux-ubuntu-14*

# Build and Install EOWS
RUN cd $EOWS_BUILD_DIR \
    # Generate artifacts
    && cmake -G "Unix Makefiles" -DCMAKE_BUILD_TYPE=Release \
                                 -DEOWS_SCIDB_MAJOR_VERSION="16" \
                                 -DCMAKE_INSTALL_PREFIX=$EOWS_INSTALL_DIR \
                                 -DCMAKE_PREFIX_PATH="$SCIDB_INSTALL_PATH;$SCIDB_INSTALL_PATH/3rdparty/boost;$EOWS_DEPENDENCIES_DIR" \
                                 -DEOWS_GDAL2_ENABLED=ON \
                                 -DEOWS_OGC_OWS_ENABLED=ON \
                                 -DEOWS_SERVICE_WCS_ENABLED=ON \
                                 -DEOWS_SERVICE_WMS_ENABLED=ON \
                                 -DEOWS_SERVICE_WTSCS_ENABLED=ON \
                                 -DEOWS_SERVICE_WTSS_ENABLED=ON \
                                 # Changing CMake RPath settings.
                                 -DCMAKE_INSTALL_RPATH=$EOWS_INSTALL_DIR/lib \
                                 -DCMAKE_SKIP_BUILD_RPATH=OFF \
                                 -DCMAKE_BUILD_WITH_INSTALL_RPATH=OFF \
                                 -DCMAKE_INSTALL_RPATH_USE_LINK_PATH=ON \
                                 $EOWS_CODEBASE/build/cmake \
    # Compile
    && make install -j${MAKE_J} \
    # Cleaning up
    && cd ${EOWS_DEPENDENCIES_DIR} \
    && rm -rf ${EOWS_CODEBASE} ${EOWS_BUILD_DIR}

COPY files/eows-entrypoint.sh /

ENTRYPOINT  /eows-entrypoint.sh