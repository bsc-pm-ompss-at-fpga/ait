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
            error_msg "Unkown dictionary"
        }

        if {[dict get ${a} ${key}] < [dict get ${b} ${key}]} {
            return -1
        } elseif {[dict get ${a} ${key}] == [dict get ${b} ${key}]} {
            return 0
        } else {
            return 1
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

    # Transforms a tcl dict into a json-valid string
    # It treats every value as a list and tries to automatically detect their type
    # A dict, for values containing an even number of elements
    # A list, for values containing an odd number of elements
    # A string, for values containing a single element
    # To modify this behaviour, a map can be passed to map dictionary keys to types
    # Ex.: dict_to_json ${dictValue} {thisValIsList list thisValIsString string}
    proc dict_to_json {dictValue {map ""} {indent 0} {first True}} {
        if {${first}} {
            set jsonStr "\{\n"
            incr indent
        } else {
            set jsonStr ""
        }
        if {[is_dict ${dictValue}]} {
            foreach {dictKey} [dict keys ${dictValue}] {
                set keyVal [dict get ${dictValue} ${dictKey}]
                if {[dict exists ${map} ${dictKey}]} {
                    set childType [dict get ${map} ${dictKey}]
                } elseif {[is_dict ${keyVal}]} {
                    set childType "dict"
                } elseif {[is_list ${keyVal}]} {
                    set childType "list"
                } else {
                    set childType "string"
                }

                if {${childType} eq "string"} {
                    append jsonStr [indent_string "\"${dictKey}\": [dict_to_json ${keyVal} ${map} 0 False]" ${indent}]
                } elseif {${childType} eq "dict"} {
                    append jsonStr "[indent_string "\"${dictKey}\": \{\n" ${indent}][string range [dict_to_json ${keyVal} ${map} [expr {${indent} + 1}] False] 0 end-2]\n[indent_string "\},\n" ${indent}]"
                } elseif {${childType} eq "list"} {
                    append jsonStr [indent_string "\"${dictKey}\": \[\n" ${indent}]
                    foreach {listItem} ${keyVal} {
                        if {[is_dict ${listItem}]} {
                            append jsonStr "[indent_string "\{\n" [expr {${indent} + 1}]][string range [dict_to_json ${listItem} ${map} [expr {${indent} + 2}] False] 0 end-2]\n[indent_string "\},\n" [expr {${indent} + 1}]]"
                        } else {
                            append jsonStr [string range [dict_to_json ${listItem} ${map} [expr {${indent} + 1}] False] 0 end-2],\n
                        }
                    }
                    set jsonStr "[string range ${jsonStr} 0 end-2]\n"
                    append jsonStr [indent_string "\],\n" ${indent}]
                }
            }
        } else {
            append jsonStr [indent_string "\"${dictValue}\",\n" ${indent}]
        }
        if {${first}} {
            set jsonStr "[string range ${jsonStr} 0 end-2]\n\}"
        }
        return ${jsonStr}
    }

    # Error message
    proc error_msg {msg} {
        puts "\[AIT\] ERROR: ${msg}"
        exit 1
    }

    # Returns the input string with num*stride whitespaces at the beginning
    proc indent_string {{str ""} {num 0} {stride 4}} {
        return [string repeat " " [expr {${num}*${stride}}]]${str}
    }

    # Info message
    proc info_msg {msg} {
        puts "\[AIT\] INFO: ${msg}"
    }

    # Returns true if the value is a dict
    # i.e. a list with an even number of elements
    proc is_dict {value} {
        return [expr {[string is list ${value}] && ([llength ${value}]&1) == 0}]
    }

    # Returns true if, in the context of a dict, the value is a list
    # i.e. a list with more than one element
    proc is_list {value} {
        return [expr {[string is list ${value}] && ([llength ${value}] > 1)}]
    }

    # Returns true if, in the context of a dict, the value is a string
    # i.e. a list with a single element
    proc is_string {value} {
        return [expr {[string is list ${value}] && ([llength ${value}] == 1)}]
    }

    # Log message
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

    # Warning message
    proc warning_msg {msg} {
        puts "\[AIT\] WARNING: ${msg}"
    }
}
