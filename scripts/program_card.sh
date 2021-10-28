#!/bin/bash

function usage() {
    echo ""
    echo "Usage: $(basename $0) <bitfile_path> [FORCE]"
    echo "  bitfile_path: full path to the .bit file to be loaded into the fpga"
    echo "  FORCE: optionally force a reload even if the USERCODE/UserID fields match"
    echo ""
}

# Make sure the caller has provided a bitfile path
if [ "$#" -lt 1 ] ; then
    echo "ERROR: Missing <bitfile_path> parameter which is required."
    usage
    exit 1
fi

# Make sure the bitfile exists and is readable
if [ ! -e $1 ] ; then
    echo "ERROR: Bitfile does not exist: $1"
    exit 1
fi
if [ ! -r $1 ] ; then
    echo "ERROR: Bitfile at $1 is not readable"
    exit 1
fi

# Make sure the provided file looks like a xilinx bitfile
file -b $1 | grep 'Xilinx BIT data' 2>&1 > /dev/null
if [ $? -ne 0 ] ; then
    echo "ERROR: Provided file does not appear to be Xilinx BIT data"
    exit 1
fi

# Looks like we have a sane bitfile to work with
echo "Using target bitfile: $1"
echo "    $(file -b $1)"
BITFILE_PATH=$1
shift

# Check for the optional FORCE parameter
FORCE=0
if [ "$#" -ge 1 ] ; then
    if [ "x$1" = "xFORCE" ] ; then
	echo "NOTE: Using the FORCE.  FPGA will be reloaded even if USERCODE/UserID registers match."
	FORCE=1
	shift
    fi
fi

# Make note of any extra, ignored command line parameters
if [ "$#" -gt 0 ] ; then
    echo "WARNING: Ignoring extra command line parameters $@"
fi

# First, check if we are already running the correct FPGA version
/usr/local/bin/check_fpga_version.sh $BITFILE_PATH
FPGA_VERSION_OK=$?

if [[ $FORCE -eq 0 && $FPGA_VERSION_OK -eq 0 ]] ; then
    echo "Running and Target FPGA versions match"
else
    if [ $FPGA_VERSION_OK -eq 0 ] ; then
	echo "Running versions match but an FPGA reprogramming was FORCE'd anyway"
    else
	echo "Running version does not match Target version, reprogramming"
    fi

    # Disconnect any devices from the kernel
    for i in $(lspci -d 10ee: -Dmm | cut -d' ' -f 1) ; do
	echo 1 > /sys/bus/pci/devices/$i/remove
    done

    # Program the bitfile into the FPGA
    source /opt/Xilinx/Vivado_Lab/2021.1/settings64.sh
    /opt/Xilinx/Vivado_Lab/2021.1/bin/vivado_lab \
	-nolog \
	-nojournal \
	-tempDir /tmp/ \
	-mode batch \
	-notrace \
        -quiet \
	-source /opt/Xilinx/tcl/program_card.tcl \
	-tclargs $BITFILE_PATH
    if [ $? -ne 0 ] ; then
	echo "Failed to load FPGA, bailing out"
	exit 1
    fi

    # Re-check if we have all expected devices on the bus now
    /usr/local/bin/check_fpga_version.sh $BITFILE_PATH
    FPGA_VERSION_OK=$?
    if [ $FPGA_VERSION_OK -eq 0 ] ; then
	echo "Running and Target FPGA versions match"
    else
	echo -n "Running version STILL does not match Target version.  "
	if [ $FORCE -eq 1 ] ; then
	    echo "Continuing anyway due to FORCE option."
	else
	    echo "Bailing out!"
	    exit 1
	fi
    fi
fi

# Always rescan the PCIe bus
echo 1 > /sys/bus/pci/rescan
