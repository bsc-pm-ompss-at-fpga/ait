#------------------------------------------------------------------------#
#    (C) Copyright 2017-2023 Barcelona Supercomputing Center             #
#                            Centro Nacional de Supercomputacion         #
#                                                                        #
#    This file is part of OmpSs@FPGA toolchain.                          #
#                                                                        #
#    This code is free software; you can redistribute it and/or modify   #
#    it under the terms of the GNU Lesser General Public License as      #
#    published by the Free Software Foundation; either version 3 of      #
#    the License, or (at your option) any later version.                 #
#                                                                        #
#    OmpSs@FPGA toolchain is distributed in the hope that it will be     #
#    useful, but WITHOUT ANY WARRANTY; without even the implied          #
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    #
#    See the GNU Lesser General Public License for more details.         #
#                                                                        #
#    You should have received a copy of the GNU Lesser General Public    #
#    License along with this code. If not, see <www.gnu.org/licenses/>.  #
#------------------------------------------------------------------------#

# Create AIT namespace
namespace eval AIT {
    namespace eval utils {
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
                set res [expr {$i%2}]$res
                set i [expr {$i/2}]
            }
            if {$res eq {}} {set res 0}

            set res [string repeat 0 [expr {$width - [string length $res]}]]$res
            return $res
        }

        # Converts an ascii string to a hex string of 32-bit values separated by \n
        proc ascii2hex {str} {
            set len [string length $str]
            # Force the string length to be multiple of 4
            if {$len%4} {
                append str [string repeat "\0" [expr {4 - $len%4}]]
            }
            set str_out ""
            for {set i 0} {$i < $len} {incr i 4} {
                foreach char [split [string reverse [string range $str $i [expr {$i + 3}]]] ""] {
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

        # Converts decimal numbers to a fixed-length hex string
        # This implementation assumes bits is divisible by 64
        proc long_int_to_hex {bits num} {
            set result ""
            set div [expr {$bits/64}]
            for {set i 0} {$i < $div} {incr i} {
                append result [format %016llX [expr {($num >> abs(($div - $i - 1))*64) & 0xFFFFFFFFFFFFFFFF}]]
            }
            return $result
        }

        # Returns a clk bd_pin object from where the input parameter clk_pin is generated
        proc get_source_clk_from_clk_pin {clk_pin} {
            set clk_domain [get_property CONFIG.CLK_DOMAIN $clk_pin]
            set source_clk [get_bd_pins -hierarchical -filter "(TYPE == clk) && (CONFIG.CLK_DOMAIN == $clk_domain) && (DIR == O)"]

            return $source_clk
        }

        # Returns a clk bd_pin object of the clock associated to the input parameter intf_pin
        proc get_clk_pin_from_intf_pin {intf_pin} {
            set ip [get_bd_cells -of_objects $intf_pin]
            set intf_name [get_property NAME $intf_pin]
            set clk_pin [get_bd_pins -of_objects $ip -filter "(TYPE == clk) && (CONFIG.ASSOCIATED_BUSIF =~ *$intf_name*)"]

            return $clk_pin
        }

        # Returns a bd_net of a reset net synchronous to the input parameter clk_pin
        # Iterates over the clock pins sharing the same net as clk_pin and looks for associated resets, then returns the first instance
        proc get_rst_net_from_clk_pin {clk_pin} {
            set clk_net [get_bd_nets -of_objects $clk_pin]
            foreach pin [get_bd_pins -of_objects $clk_net] {
                set clk_rst [get_property CONFIG.ASSOCIATED_RESET $pin]
                if [llength $clk_rst] {
                    set ip_path [string range [get_property PATH $pin] 0 [string last / [get_property PATH $pin]]]
                    set rst_net [get_bd_nets -of_objects [get_bd_pins $ip_path/$clk_rst]]
                    if [llength $rst_net] {
                        return $rst_net
                    }
                }
            }
            error_msg "No valid reset net found for clock pin ($clk_pin)"
        }
    }
}
