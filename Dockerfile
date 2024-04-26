# First stage: Create a base image
FROM qemux/qemu-docker:4.25 AS base

# Install any dependencies or configure the base image if needed

# Second stage: Create the final image
FROM scratch

# Copy files from the base image into the final image
COPY --from=base / /

# Define arguments
ARG DEBCONF_NOWARNINGS="yes"
ARG DEBIAN_FRONTEND="noninteractive"
ARG DEBCONF_NONINTERACTIVE_SEEN="true"

# Install packages
RUN apt-get update && \
    apt-get --no-install-recommends -y install \
        bc \
        curl \
        7zip \
        wsdd \
        samba \
        dos2unix \
        cabextract \
        genisoimage \
        libxml2-utils && \
    echo "deb http://deb.debian.org/debian/ sid main" >> /etc/apt/sources.list.d/sid.list && \
    echo -e "Package: *\nPin: release n=trixie\nPin-Priority: 900\nPackage: *\nPin: release n=sid\nPin-Priority: 400" | tee /etc/apt/preferences.d/preferences > /dev/null && \
    apt-get update && \
    apt-get -t sid --no-install-recommends -y install wimtools && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Copy additional files
COPY ./src /run/
COPY ./assets /run/assets

# Add wsdd and drivers
ADD https://raw.githubusercontent.com/christgau/wsdd/v0.8/src/wsdd.py /usr/sbin/wsdd
ADD https://github.com/qemus/virtiso/releases/download/v0.1.248/virtio-win-0.1.248.iso /run/drivers.iso

# Set permissions
RUN chmod +x /run/*.sh && chmod +x /usr/sbin/wsdd

# Expose ports and define volumes
EXPOSE 8006 3389
VOLUME /storage

# Define environment variables
ENV RAM_SIZE="4G"
ENV CPU_CORES="2"
ENV DISK_SIZE="64G"
ENV VERSION="win11"

# Set version argument
ARG VERSION_ARG="0.0"
RUN echo "$VERSION_ARG" > /run/version

# Set the entry point
ENTRYPOINT ["/usr/bin/tini", "-s", "--", "/run/entry.sh"]
