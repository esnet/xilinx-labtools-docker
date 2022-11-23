#!/bin/bash

# Source the Xilinx Vivado settings into the environment
source /opt/Xilinx/Vivado_Lab/${VIVADO_VERSION}/settings64.sh

# Run the provided CMD
exec "$@"
