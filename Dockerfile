# -- --- ----- ------- ----------- -------------

# Set up the Xilinx Debian package archive and download some pre-built packages
FROM ubuntu:jammy as xilinx
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
RUN \
  sed -i -re 's|(http://)([^/]+.*)/|\1linux.mirrors.es.net/ubuntu|g' /etc/apt/sources.list

# Install prereq tools
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt install -y --no-install-recommends \
    build-essential \
    ca-certificates \
    gnupg2 \
    lsb-release \
    unzip \
    wget

# Import the Xilinx public key
RUN wget -qO - https://www.xilinx.com/support/download/2020-2/xilinx-master-signing-key.asc | apt-key add -
# Add the Xilinx debian archive
RUN echo "deb https://packages.xilinx.com/artifactory/debian-packages $(lsb_release -cs) main" | tee -a /etc/apt/sources.list.d/xlnx.list
RUN apt update

# Download the latest versions of the Satellite Controller Firmware (SC FW) packages and xbflash2 tool from the Xilinx archive
RUN \
  mkdir --mode ugo=rwx /xilinx-debs && \
  cd /xilinx-debs && \
  apt download \
    xilinx-sc-fw-u280 \
    xilinx-sc-fw-u55 \
    xrt-xbflash2
RUN ls -l /xilinx-debs

# Prepare an output directory to hold the outputs from this build stage
RUN mkdir -p /sc-fw

# Set up the base address for where installer binaries are stored within ESnet's private network
#
# NOTE: This URL is NOT REACHABLE outside of ESnet's private network.  Non-ESnet users must follow
#       the instructions in the README.md file and download their own copy of the loadsc zip file
#       directly from the AMD/Xilinx website and drop it into the sc-fw-downloads directory
#
ARG DISPENSE_BASE_URL="https://dispense.es.net/Linux/xilinx"

ARG LOADSC_ZIP="loadsc_v2.3.zip"
COPY sc-fw-downloads/ /sc-fw-downloads/
RUN \
  cd /sc-fw-downloads && \
  ( \
    if [ ! -e $LOADSC_ZIP ] ; then \
      echo "Fetching: $DISPENSE_BASE_URL/$LOADSC_ZIP" ; \
      wget -q -O $LOADSC_ZIP $DISPENSE_BASE_URL/$LOADSC_ZIP ; \
    fi ; \
    mkdir -p loadsc ; \
    unzip -d loadsc $LOADSC_ZIP ; \
  ) && \
  cd /sc-fw-downloads/loadsc && \
  gcc -o /sc-fw/loadsc *.c

# Extract the SC firmware files into a common location
RUN \
  for sc in /xilinx-debs/xilinx-sc-fw*.deb ; do \
    dpkg-deb --fsys-tarfile "$sc" | tar x -C /sc-fw --strip-components 6 --wildcards './opt/xilinx/firmware/sc-fw/*/sc-fw-*.txt' ; \
  done

# Copy in any locally populated extra SC firmware images supplied by the user
COPY sc-fw-extra/ /sc-fw/

# -- --- ----- ------- ----------- -------------

FROM ubuntu:jammy
ENV DEBIAN_FRONTEND=noninteractive

# Configure local ubuntu mirror as package source
RUN \
  sed -i -re 's|(http://)([^/]+.*)/|\1linux.mirrors.es.net/ubuntu|g' /etc/apt/sources.list

# Set our container localtime to UTC
RUN \
  ln -fs /usr/share/zoneinfo/UTC /etc/localtime

# Pull in the downloaded deb files from the xilinx layer
COPY --from=xilinx /xilinx-debs/ /xilinx-debs/

# Pull in the extracted SC firmware files from the xilinx layer
COPY --from=xilinx /sc-fw/ /sc-fw/

# Install the xbflash2 package
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    /xilinx-debs/xrt-xbflash2_*_amd64.deb \
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
    libtinfo5 \
    locales \
    lsb-release \
    net-tools \
    patch \
    pigz \
    unzip \
    wget \
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
ENV VIVADO_VERSION=2023.2
# Xilinx installer tar file originally from: https://www.xilinx.com/support/download.html
ARG VIVADO_LAB_INSTALLER="Vivado_Lab_Lin_${VIVADO_VERSION}_1013_2256.tar.gz"
# Installer config file
ARG VIVADO_INSTALLER_CONFIG="/vivado-installer/install_config_lab.${VIVADO_VERSION}.txt"

COPY vivado-installer/ /vivado-installer/
RUN \
  ( \
    if [ -e /vivado-installer/$VIVADO_LAB_INSTALLER ] ; then \
      pigz -dc /vivado-installer/$VIVADO_LAB_INSTALLER | tar xa --strip-components=1 -C /vivado-installer ; \
    else \
      wget -qO- $DISPENSE_BASE_URL/$VIVADO_LAB_INSTALLER | pigz -dc | tar xa --strip-components=1 -C /vivado-installer ; \
    fi \
  ) && \
  if [ ! -e ${VIVADO_INSTALLER_CONFIG} ] ; then \
    /vivado-installer/xsetup \
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
    --config ${VIVADO_INSTALLER_CONFIG} && \
  rm -rf /vivado-installer

# Apply post-install patches to fix issues found on each OS release
# Common patches
#   * Disable workaround for X11 XSupportsLocale bug.  This workaround triggers additional requirements on the host
#     to have an entire suite of X11 related libraries installed even though we only use vivado in batch/tcl mode.
#     See: https://support.xilinx.com/s/article/62553?language=en_US
COPY patches/ /patches
RUN \
  if [ -e "/patches/ubuntu-$(lsb_release --short --release)-vivado-${VIVADO_VERSION}-postinstall.patch" ] ; then \
    patch -p 1 < /patches/ubuntu-$(lsb_release --short --release)-vivado-${VIVADO_VERSION}-postinstall.patch ; \
  fi ; \
  if [ -e "/patches/vivado-${VIVADO_VERSION}-postinstall.patch" ] ; then \
    patch -p 1 < /patches/vivado-${VIVADO_VERSION}-postinstall.patch ; \
  fi

# Install misc extra packages that are useful at runtime but not required for installing labtools
RUN \
  apt-get update -y && \
  apt-get upgrade -y && \
  apt-get install -y --no-install-recommends \
    file \
    jq \
    less \
    pciutils \
    tree \
    && \
  apt-get autoclean && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

# Set up the container to pre-source the vivado environment
COPY ./entrypoint.sh /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]

CMD ["/bin/bash", "-l"]
