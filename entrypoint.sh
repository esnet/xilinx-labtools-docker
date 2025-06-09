#!/bin/bash

# Source the Xilinx Vivado settings into the environment
source /tools/Xilinx/${VIVADO_BASE_VERSION}/Vivado_Lab/settings64.sh

# Run the provided CMD
exec "$@"
