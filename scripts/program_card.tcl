
if { $argc != 1 } {
        puts "The script requires a path of the bitfile."
        puts "For example, vivado -mode batch -source program_card.tcl -tclargs /tmp/fpga.bit"
        puts "Please try again."
} else {
        puts "About to flash the following bitfile: [lindex $argv 0]"
        open_hw_manager -verbose
        connect_hw_server -url ht-hwserver:3121 -cs_url ht-csserver:3042
        current_hw_target
        open_hw_target
        current_hw_device
        set_property PROGRAM.FILE [lindex $argv 0] [current_hw_device]
        program_hw_device [current_hw_device]
}


