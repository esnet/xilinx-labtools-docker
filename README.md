
Download the Xilinx Labtools Installer
--------------------------------------

* Open a web browser to this page: https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/vivado-design-tools/2022-1.html
* Download `Vivado 2022.1: Lab Edition - Linux`
* Save the file as exactly: `Xilinx_Vivado_Lab_Lin_2022.1_0420_0327.tar.gz`
* Move the file into the `vivado-installer` directory in this repo

```
$ tree
.
├── docker-compose.yml
├── Dockerfile
├── sources.list
└── vivado-installer
    ├── install_config_lab2021.txt
    └── Xilinx_Vivado_Lab_Lin_2022.1_0420_0327.tar.gz   <------- put the installer here
```

Building the labtools container
-------------------------------

```
docker compose build
docker image ls
```

You should see an image called `xilinx-labtools-docker` with tag `v2022.1-latest`.
