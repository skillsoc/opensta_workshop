

#foreach fil [glob /media/skillsoc/hdd/software/OpenSTA/tcl/*.tcl] {
#source $fil
#}


proc get_object_name {args} {
	set of_index [lsearch -exact $args "-of"]
    if { $of_index < 0 } {
        error "Usage: get_object_name -of \[cell_name\]"
    }
    set pointers [lindex $args [expr $of_index + 1]]
    report_object_names $pointers
    
}


proc list_attribute {object args} {
    if { [lsearch -exact $args "-help"] > 0} {
	puts "this command is for listing the available attributes for the object. \n
	usage: list_attribute \[get_cells u_dff1\] cell \n
		list_attribute is the command
		you will have to provide the object 
		you will have to provide the object type \"cell, pin, net,
port, clock, lib, lib_cell, lib_pin, or timing_arc \"
	"
    }

    if {$args == "clock"} {
	set properties "full_name is_generated name period propagated sources"
    } elseif {$args == "cell"} {
	set properties "ref_name full_name name"
    } elseif {$args == "edge"} {
	    set properties "delay_max_fall delay_min_fall delay_max_rise delay_min_rise full_name from_pin sense to_pin"
    } elseif {$args == "pin"} {
	    set properties "activity slew_max_fall slew_max_rise slew_min_fall slew_min_rise clocks clock_domains direction full_name is_register_clock lib_pin_name name slack_max slack_max_fall slack_max_rise slack_min slack_min_fall slack_min_rise"
    } elseif {$args == "net"} {
	    set properties "full_name name"
    } elseif {$args == "port"} {
	    set properties "activity slew_max_fall slew_max_rise slew_min_fall slew_min_rise direction full_name liberty_port name slack_max slack_max_fall slack_max_rise slack_min slack_min_fall slack_min_rise"
    } elseif {$args == "lib"} {
	    set properties "filename name full_name"
    } elseif {$args == "lib_cell"} {
	    set properties "area base_name dont_use filename full_name is_buffer is_inverter library name"
    } elseif {$args == "lib_pin"} {
	    set properties "capacitance direction drive_resistance drive_resistance_max_fall drive_resistance_max_rise drive_resistance_min_fall drive_resistance_min_rise full_name intrinsic_delay intrinsic_delay_max_fall intrinsic_delay_max_rise intrinsic_delay_min_fall intrinsic_delay_min_rise is_register_clock lib_cell name"
    } else {
	    puts "Error: the object_type is not valid"
		set properties ""
    }
#puts "$properties"
    foreach prop [split $properties " "] {
	puts "$prop : [get_property $object $prop]"
    }
    return $properties
}

rename report_checks report_timing
rename report_dcalc report_delay_calculation
rename set_load set_annotated_load
rename set_assigned_transition set_annotated_transition
