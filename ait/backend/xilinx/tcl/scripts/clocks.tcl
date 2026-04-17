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

namespace eval AIT {
    namespace eval clocks {
        # Connects srcClk to dstClk (pin or net) or to the default clock
        proc connect_clock {srcClk {dstClk ""}} {
            if {${dstClk} eq ""} {
                set dstClk [get_bd_pins /clock_generator/clk_app]
            }
            if {!([llength [get_bd_nets -quiet -of_objects ${srcClk}]])} {
                if {[get_property CLASS ${dstClk}] eq "bd_net"} {
                    connect_bd_net ${srcClk} -net ${dstClk}
                } elseif {[get_property CLASS ${dstClk}] eq "bd_pin"} {
                    connect_bd_net ${srcClk} ${dstClk}
                }
            }
            return ${dstClk}
        }

        proc create_clock {outFreq {clkName ""} {clkIPName "/clock_generator"}} {
            set clkIP [get_bd_cells ${clkIPName}]
            if {${clkName} eq ""} {
                set clkName "freq_${outFreq}_clk"
            } else {
                set clkName "${clkName}_clk"
            }

            # If it does not exist, create clock
            if {![llength [get_bd_pins -quiet ${clkIP}/${clkName}]]} {
                set numOutClocks [get_property CONFIG.NUM_OUT_CLKS ${clkIP}]
                incr numOutClocks
                if {${numOutClocks} > 7} {
                    AIT::utils::error_msg "Number of output clocks for ${clkIPName} over 100%"
                }
                set_property -dict [list \
                    CONFIG.NUM_OUT_CLKS ${numOutClocks} \
                    CONFIG.CLKOUT${numOutClocks}_USED {true} \
                    CONFIG.CLKOUT${numOutClocks}_REQUESTED_OUT_FREQ ${outFreq} \
                    CONFIG.CLK_OUT${numOutClocks}_PORT ${clkName}
                ] ${clkIP}
            }

            return [get_bd_pins ${clkIP}/${clkName}]
        }

        # Returns a clk bd_pin object of the clock associated to the input parameter intfPinName
        proc get_associated_clk_pin {intfPinName} {
            set intfPin [get_bd_intf_pins ${intfPinName}]
            set intfIP [get_bd_cells -of_objects ${intfPin}]
            set intfName [get_property NAME ${intfPin}]
            set intfClkPin [get_bd_pins -quiet -of_objects ${intfIP} -regexp -filter "(TYPE == clk) && (CONFIG.ASSOCIATED_BUSIF =~ .*${intfName}.*)"]
            if {![llength ${intfClkPin}]} {
                if {[get_property TYPE ${intfPin}] eq "hier"} {
                    set intfPinInnerNet [get_bd_intf_nets -boundary_type lower -of_objects ${intfPin}]
                    set innerNetIntfPin [get_bd_intf_pins -of_objects ${intfPinInnerNet} -filter "PATH != ${intfPin}"]
                    set intfClkPin [get_associated_clk_pin ${innerNetIntfPin}]
                } else {
                    AIT::utils::error_msg "Unknown interface type [get_property TYPE ${intfPin}]"
                }
            }
            return ${intfClkPin}
        }
    }
}
