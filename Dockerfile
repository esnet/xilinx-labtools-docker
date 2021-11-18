FROM ubuntu:focal
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
COPY sources.list /etc/apt/sources.list

# Install packages required for running the vivado installer
RUN \
  ln -fs /usr/share/zoneinfo/America/Los_Angeles /etc/localtime && \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    wget \
    libtinfo-dev \
    libxrender1 \
    libxtst6 \
    x11-apps \
    libxi6 \
    lib32gcc-7-dev \
    net-tools \
    graphviz \
    unzip \
    g++ \
    libtinfo5 \
    x11-utils \
    xvfb \
    unzip \
    lsb-release \
    locales \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  locale-gen en_US.UTF-8 && \
  update-locale LANG=en_US.UTF-8 && \
  rm -rf /var/lib/apt/lists/*

# Set up the base address for where our installer binaries are stored
ARG DISPENSE_BASE_URL="http://dispense.es.net/Linux/xilinx"

# Install the Xilinx Lab tools
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_LAB_INSTALLER="Xilinx_Vivado_Lab_Lin_2021.1_0610_2318.tar.gz"
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
    --agree 3rdPartyEULA,WebTalkTerms,XilinxEULA \
    --batch Install \
    --config /vivado-installer/install_config_lab2021.txt && \
  rm -rf /vivado-installer

CMD ["/bin/bash", "-l"]
