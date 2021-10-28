open_hw_manager -quiet
connect_hw_server -url ht-hwserver:3121 -cs_url ht-csserver:3042 -quiet
open_hw_target -quiet
#puts [get_property REGISTER.USERCODE.SLR0 [current_hw_device]]

proc property_list_to_json {alist} {
    set len [llength $alist]
    puts "{"
    for {set i 0} {$i < $len} {incr i} {
	set k [lindex $alist $i]
	set v [get_property $k [current_hw_device]]
	puts -nonewline "  \"$k\": \"$v\""
	if {$i < ($len - 1)} {
	    puts ","
	} else {
	    puts ""
	}
    }
    puts "}"
}

property_list_to_json [list_property [current_hw_device] REGISTER.*]
