# Create AIT namespace
namespace eval AIT {
    ## AIT message procedures
    # Error
    proc error_msg {msg} {
        puts "\[AIT\] ERROR: $msg"
        exit 1
    }

    # Warning
    proc warning_msg {msg} {
        puts "\[AIT\] WARNING: $msg"
    }

    # Info
    proc info_msg {msg} {
        puts "\[AIT\] INFO: $msg"
    }

    # Log
    proc log_msg {msg} {
        puts "\[AIT\]: $msg"
    }

    ## Misc procedures
    # Returns the binary representation of $i
    # width determines the length of the returned string with 0-padding, must be always bigger or equal to the width of i
    proc dec2bin {i width} {
        set res {}
        while {$i > 0} {
            set res [expr $i%2]$res
            set i [expr $i/2]
        }
        if {$res eq {}} {set res 0}

        set res [string repeat 0 [expr $width - [string length $res]]]$res
        return $res
    }

    # Converts an ascii string to a hex string of 32-bit values separated by \n
    proc ascii2hex {str} {
        set len [string length $str]
        # Force the string length to be multiple of 4
        if {$len%4} {
            append str [string repeat "\0" [expr 4 - $len%4]]
        }
        set str_out ""
        for {set i 0} {$i < $len} {incr i 4} {
            foreach char [split [string reverse [string range $str $i [expr $i+3]]] ""] {
                append str_out [format %02X [scan $char %c]]
            }
            append str_out "\n"
        }
        return $str_out
    }

    # Compares a bd address segment dictionary with the segment size
    proc comp_bd_addr_seg {a b} {
        if {[dict get $a size] < [dict get $b size]} {
            return -1
        } elseif {[dict get $a size] == [dict get $b size]} {
            return 0
        } else {
            return 1
        }
    }
}
