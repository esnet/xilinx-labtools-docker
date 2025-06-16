# Copyright Notice

ESnet SmartNIC Copyright (c) 2022, The Regents of the University of
California, through Lawrence Berkeley National Laboratory (subject to
receipt of any required approvals from the U.S. Dept. of Energy),
12574861 Canada Inc., Malleable Networks Inc., and Apical Networks, Inc.
All rights reserved.

If you have questions about your rights to use or distribute this software,
please contact Berkeley Lab's Intellectual Property Office at
IPO@lbl.gov.

NOTICE.  This Software was developed under funding from the U.S. Department
of Energy and the U.S. Government consequently retains certain rights.  As
such, the U.S. Government has been granted for itself and others acting on
its behalf a paid-up, nonexclusive, irrevocable, worldwide license in the
Software to reproduce, distribute copies to the public, prepare derivative
works, and perform publicly and display publicly, and to permit others to do so.


# Support

The ESnet SmartNIC platform is made available in the hope that it will
be useful to the networking community. Users should note that it is
made available on an "as-is" basis, and should not expect any
technical support or other assistance with building or using this
software. For more information, please refer to the LICENSE.md file in
each of the source code repositories.

The developers of the ESnet SmartNIC platform can be reached by email
at smartnic@es.net.


Download the Xilinx Labtools Installer
--------------------------------------

* Open a web browser to this page: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2025-1.html
* Under the `Vivado Lab Solutions - 2025.1` section
  * Download `Vivado 2025.1: Lab Edition - Linux`
  * Save the file as exactly: `Vivado_Lab_Lin_2025.1_0530_0145.tar`
* Move the file into the `vivado-installer` directory in this repo

Download the Alveo Smartnic Satellite Controller Update Tool
------------------------------------------------------------
* Open a web browser to this page: https://adaptivesupport.amd.com/s/article/73654
* At the bottom of the page under the `Files` section
  * Download `loadsc_v2.3.zip`
  * Save the file as exactly `loadsc_v2.3.zip`
* Move the file into the `sc-fw-downloads` directory in this repo

Download the latest Satellite Controller Firmware Releases (optional)
---------------------------------------------------------------------
* Open a web browser to this page: https://adaptivesupport.amd.com/s/article/Alveo-Custom-Flow-Latest-CMS-IP-and-SC-FW
* At the bottom of the page under the `Files` section
  * Download `SC_U280_4_3_31.zip`
    * Save the file as exactly `SC_U280_4_3_31.zip`
  * Download `SC_U55C_7_1_24.zip`
    * Save the file as exactly `SC_U55C_7_1_24.zip`
  * Move the downloaded files into the `sc-fw-downloads` directory in this repo

Verify that you have the downloaded files all in the right places
-----------------------------------------------------------------

This is a map of where the downloaded files should be placed
```
$ tree
.
├── Dockerfile
├── entrypoint.sh
├── LICENSE.md
├── patches
│   └── vivado-2025.1-postinstall.patch
├── README.md
├── sc-fw-downloads
│   ├── loadsc_v2.3.zip   <------------------------------------- put the loadsc zip file here
│   ├── SC_U280_4_3_31.zip   <---------------------------------- put the SC Firmware zip files here
│   └── SC_U55_7_1_24.zip    <---------------------------------- put the SC Firmware zip files here
├── sc-fw-extra
└── vivado-installer
    ├── install_config_lab.2025.1.txt
    └── Vivado_Lab_Lin_2025.1_0530_0145.tar             <------- put the installer here
```

Building the xilinx-labtools container
--------------------------------------

```
docker build --pull -t xilinx-labtools-docker:${USER}-dev .
docker image ls
```

You should see an image called `xilinx-labtools-docker` with tag `${USER}-dev`.
