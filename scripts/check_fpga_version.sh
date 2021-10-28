#!/bin/bash

BITFILE=$1

# Set up our vivado runtime env
source /opt/Xilinx/Vivado_Lab/2021.1/settings64.sh

# Collect all of the JTAG register values for the currently loaded FPGA device
/opt/Xilinx/Vivado_Lab/2021.1/bin/vivado_lab \
    -nolog \
    -nojournal \
    -tempDir /tmp/ \
    -mode batch \
    -notrace \
    -quiet \
    -source /opt/Xilinx/tcl/read_jtag_registers.tcl \
    > /tmp/u280.jtag.registers.json

# Grab the USERCODE register value (ie. which FPGA is *currently* loaded)
USERCODE=$(cat /tmp/u280.jtag.registers.json | jq -r '.["REGISTER.USERCODE.SLR0"]')
echo "Found JTAG USERCODE=${USERCODE}"

# Read the UserID field out of the header in the new target bit file
USERID=$(file -b $BITFILE | sed -re 's/^.*(;UserID=)((0[Xx])?[0-9A-Fa-f]+).*$/\2/g' | tr 'A-Z' 'a-z')
echo "Found Target UserID=${USERID}"

# Compare the current with the target FPGA versions
if [ "x$USERCODE" = "x$USERID" ] ; then
    # Running and target versions match
    exit 0
else
    # Running version does not match target version
    exit 1
fi
