# First, build the xrt tools separately so we can drop most of the build-time dependencies
FROM ubuntu:focal as xrt
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list.focal /etc/apt/sources.list

# Build xrt tools (all of this just to get xbflash2...)
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt install -y --no-install-recommends \
    ca-certificates \
    git
RUN git clone https://github.com/xilinx/xrt.git
RUN \
  cd xrt && \
  ./src/runtime_src/tools/scripts/xrtdeps.sh -docker && \
  cd build && \
  ./build.sh && \
  echo 'apt install ./Release/xrt_*-xbflash2.deb' && \
  cd / && \
  mkdir /xrt-debs && \
  cp -a /xrt/build/Release/*.deb /xrt-debs && \
  rm -rf /xrt && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list.focal /etc/apt/sources.list

# Set our container localtime to UTC
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Install the previously built xbflash2 package
COPY --from=xrt /xrt-debs/ /xrt-debs/
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    /xrt-debs/xrt_*-xbflash2.deb \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Install packages required for running the vivado installer
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    ca-certificates \
    g++ \
    graphviz \
    lib32gcc-7-dev \
    libtinfo-dev \
    libtinfo5 \
    libxi6 \
    libxrender1 \
    libxtst6 \
    locales \
    lsb-release \
    net-tools \
    pigz \
    unzip \
    wget \
    x11-apps \
    x11-utils \
    xvfb \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set up the base address for where installer binaries are stored within ESnet's private network
#
# NOTE: This URL is NOT REACHABLE outside of ESnet's private network.  Non-ESnet users must follow
#       the instructions in the README.md file and download their own copies of the installers
#       directly from the AMD/Xilinx website and drop them into the vivado-installer directory
#
ARG DISPENSE_BASE_URL="https://dispense.es.net/Linux/xilinx"

# Install the Xilinx Lab tools
# ENV var to help users to find the version of vivado that has been installed in this container
ENV VIVADO_VERSION=2023.1
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_LAB_INSTALLER="Xilinx_Vivado_Lab_Lin_${VIVADO_VERSION}_0507_1903.tar.gz"

COPY vivado-installer/ /vivado-installer/
RUN \
  ( \
    if [ -e /vivado-installer/$VIVADO_LAB_INSTALLER ] ; then \
      pigz -dc /vivado-installer/$VIVADO_LAB_INSTALLER | tar xa --strip-components=1 -C /vivado-installer ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_LAB_INSTALLER | pigz -dc | tar xa --strip-components=1 -C /vivado-installer ; \
    fi \
  ) && \
  if [ ! -e /vivado-installer/install_config_lab.${VIVADO_VERSION}.txt ] ; then \
    /vivado-installer/xsetup \
      -l /tools/Xilinx \
      -e 'Vivado Lab Edition (Standalone)' \
      -b ConfigGen && \
    echo "No installer configuration file was provided.  Generating a default one for you to modify." && \
    echo "-------------" && \
    cat /root/.Xilinx/install_config.txt && \
    echo "-------------" && \
    exit 1 ; \
  fi ; \
  /vivado-installer/xsetup \
    --agree 3rdPartyEULA,XilinxEULA \
    --batch Install \
    --config /vivado-installer/install_config_lab.${VIVADO_VERSION}.txt && \
  rm -rf /vivado-installer

# Install misc extra packages that are useful at runtime but not required for installing labtools
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    file \
    jq \
    pciutils \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Set up the container to pre-source the vivado environment
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["/bin/bash", "-l"]
