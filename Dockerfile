FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list /etc/apt/sources.list

# Install packages required for running the vivado installer
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime && \
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

# Set up the base address for where our installer binaries are stored
ARG DISPENSE_BASE_URL="https://dispense.es.net/Linux/xilinx"

# Install the Xilinx Lab tools
# ENV var to help users to find the version of vivado that has been installed in this container
ENV VIVADO_VERSION=2022.1
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_LAB_INSTALLER="Xilinx_Vivado_Lab_Lin_${VIVADO_VERSION}_0420_0327.tar.gz"
COPY vivado-installer/ /vivado-installer/
RUN \
  ( \
    if [ -e /vivado-installer/$VIVADO_LAB_INSTALLER ] ; then \
      tar zxf /vivado-installer/$VIVADO_LAB_INSTALLER --strip-components=1 -C /vivado-installer ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_LAB_INSTALLER | tar zx --strip-components=1 -C /vivado-installer ; \
    fi \
  ) && \
  /vivado-installer/xsetup \
    --agree 3rdPartyEULA,XilinxEULA \
    --batch Install \
    --config /vivado-installer/install_config_lab2021.txt && \
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

CMD ["/bin/bash", "-l"]
