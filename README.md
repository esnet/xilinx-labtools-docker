
Download the Xilinx Labtools Installer
--------------------------------------

* Open a web browser to this page: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2021-2.html
* Download `Vivado 2021.2: Lab Edition - Linux`
* Save the file as exactly: `Xilinx_Vivado_Lab_Lin_2021.2_1021_0703.tar.gz`
* Move the file into the `vivado-installer` directory in this repo

```
$ tree
.
├── docker-compose.yml
├── Dockerfile
├── sources.list
└── vivado-installer
    ├── install_config_lab2021.txt
    └── Xilinx_Vivado_Lab_Lin_2021.2_1021_0703.tar.gz   <------- put the installer here
```

Download the patches to fix the Apache Log4j Vulnerability in Xilinx Products
-----------------------------------------------------------------------------

* Open a web browser to this page: https://support.xilinx.com/s/article/76957?language=en_US
* Download `Patch-Log4j-2.5.zip`
* Save the file as exactly: `Patch-Log4j-2.5.zip`
* Move the file into the `vivado-installer` directory in this repo

```
$ tree
.
├── docker-compose.yml
├── Dockerfile
├── sources.list
└── vivado-installer
    ├── install_config_lab2021.txt
    ├── Patch-Log4j-2.5.zip  <---------------------------------- put the patch file here
    └── Xilinx_Vivado_Lab_Lin_2021.2_1021_0703.tar.gz
```

Building the labtools container
-------------------------------

```
docker compose build
docker image ls
```

You should see an image called `xilinx-labtools-docker` with tag `v2021.2-latest`.
