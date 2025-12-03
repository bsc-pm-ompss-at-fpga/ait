#------------------------------------------------------------------------#
#    (C) Copyright 2017-2025 Barcelona Supercomputing Center             #
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
        # Converts an ascii string to a hex string of 32-bit values separated by \n
        proc ascii_to_hex {str} {
            set len [string length ${str}]
            # Force the string length to be multiple of 4
            if {${len}%4} {
                append str [string repeat "\0" [expr {4 - ${len}%4}]]
            }
            set strOut ""
            for {set i 0} {${i} < ${len}} {incr i 4} {
                foreach char [split [string reverse [string range ${str} ${i} [expr {${i} + 3}]]] ""] {
                    append strOut [format %02X [scan ${char} %c]]
                }
                append strOut "\n"
            }
            return ${strOut}
        }

        # Compares two dictionaries with the given key value
        proc comp_dict {a b} {
            if {[dict exists ${a} "size"]} {
                set key "size"
            } elseif {[dict exists ${a} "occupation"]} {
                set key "occupation"
            } else {
                AIT::utils::error_msg "Unkown dictionary"
            }

            if {[dict get ${a} ${key}] < [dict get ${b} ${key}]} {
                return -1
            } elseif {[dict get ${a} ${key}] == [dict get ${b} ${key}]} {
                return 0
            } else {
                return 1
            }
        }

        # data is plain old tcl values
        # spec is defined as follows:
        # {string} - data is simply a string, "quote" it if it's not a number
        # {list} - data is a tcl list of strings, convert to JSON arrays
        # {list list} - data is a tcl list of lists
        # {list dict} - data is a tcl list of dicts
        # {dict} - data is a tcl dict of strings
        # {dict xx list} - data is a tcl dict where the value of key xx is a tcl list
        # {dict * list} - data is a tcl dict of lists
        # etc..
        # Credits to https://stackoverflow.com/a/25815465
        proc compile_json {spec data} {
            while {[llength ${spec}]} {
                set type [lindex ${spec} 0]
                set spec [lrange ${spec} 1 end]
                switch -- ${type} {
                    dict {
                        lappend spec * string
                        set json {}
                        foreach {key val} ${data} {
                            foreach {keymatch valtype} ${spec} {
                                if {[string match ${keymatch} ${key}]} {
                                    lappend json [subst {"${key}":[
                                        compile_json ${valtype} ${val}]}]
                                    break
                                }
                            }
                        }
                        return "{[join ${json} ,]}"
                    }
                    list {
                        if {![llength ${spec}]} {
                            set spec string
                        } else {
                            set spec [lindex ${spec} 0]
                        }
                        set json {}
                        foreach {val} ${data} {
                            lappend json [compile_json ${spec} ${val}]
                        }
                        return "\[[join ${json} ,]\]"
                    }
                    string {
                        # This will return hexadecimal numbers as numbers, which
                        # is not valid json. Return all numbers as strings.
                        #if {[string is double -strict ${data}]} {
                        #    return ${data}
                        #} else {
                            return "\"${data}\""
                        #}
                    }
                    default {error "Invalid type"}
                }
            }
        }

        # Returns the binary representation of value
        # width determines the length of the returned string with 0-padding, must be always bigger or equal to the width of value
        proc dec_to_bin {value width} {
            set res {}
            while {${value} > 0} {
                set res [expr {${value}%2}]${res}
                set value [expr {${value}/2}]
            }
            if {${res} eq {}} {set res 0}

            set res [string repeat 0 [expr {${width} - [string length ${res}]}]]${res}
            return ${res}
        }

        # Error message
        proc error_msg {msg} {
            puts "\[AIT\] ERROR: ${msg}"
            exit 1
        }

        # Info message
        proc info_msg {msg} {
            puts "\[AIT\] INFO: ${msg}"
        }

        # Log
        proc log_msg {msg} {
            puts "\[AIT\]: ${msg}"
        }

        # Converts decimal numbers to a fixed-length hex string
        # This implementation assumes bits is divisible by 64
        proc long_int_to_hex {bits num} {
            set result ""
            set div [expr {${bits}/64}]
            for {set i 0} {${i} < ${div}} {incr i} {
                append result [format %016llX [expr {(${num} >> abs((${div} - ${i} - 1))*64) & 0xFFFFFFFFFFFFFFFF}]]
            }
            return ${result}
        }

        # Warning
        proc warning_msg {msg} {
            puts "\[AIT\] WARNING: ${msg}"
        }
    }
}
