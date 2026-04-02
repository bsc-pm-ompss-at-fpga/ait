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

namespace eval templates {
    variable scriptDir [file dirname [file normalize [info script]]]

    proc base_design {designName} {
        source_template "baseDesign" ${designName}
    }

    proc custom_interconnect {instanceName srcBitWidth srcClkName dstBitWidth dstClkName {rwMode "read_write"}} {
        source_template "custom_interconnect" ${instanceName} ${srcBitWidth} ${srcClkName} ${dstBitWidth} ${dstClkName} ${rwMode}
    }

    proc ethernet_subsystem {} {
        source_template "ethernet_subsystem"
        AIT::board::instantiate_ethernet_subsystem
    }

    proc OMPIF {} {
        ethernet_subsystem

        source_template "ompif"

        set ompifClkSrcPin [get_bd_pins [dict get ${AIT::project::board} "ompif" "clk"]]
        set ompifRstSrcPin [get_bd_pins [dict get ${AIT::project::board} "ompif" "rst"]]

        connect_bd_intf_net [get_bd_intf_pins ${OMPIF::hier}/ethTx] [get_bd_intf_pins ${ethSubsys::container}/S_AXIS]
        connect_bd_intf_net [get_bd_intf_pins ${ethSubsys::container}/msg_rx] [get_bd_intf_pins ${OMPIF::hier}/ethRx]

        AIT::clocks::connect_clock [get_bd_pins ${OMPIF::hier}/app_clk]
        AIT::clocks::connect_clock [get_bd_pins ${OMPIF::hier}/ompif_clk] ${ompifClkSrcPin}
        AIT::resets::connect_reset [get_bd_pins ${OMPIF::hier}/app_aresetn]
        AIT::resets::connect_reset [get_bd_pins ${OMPIF::hier}/ompif_aresetn] ${ompifRstSrcPin}

        connect_bd_net [get_bd_pins ${OMPIF::hier}/cluster_rank_size] [get_bd_pins ${ethSubsys::jtagGpioIP}/gpio2_io_o]

        if {[dict get ${AIT::project::board} "name"] eq "alveo_u55c"
            || [dict get ${AIT::project::board} "name"] eq "alveo_u280_hbm"} {

            set 200SLR0ClkPin [AIT::clocks::create_clock 200 "freq_200_slr0" "clk_gen_slr0"]
            set 400SLR0ClkPin [AIT::clocks::create_clock 400 "freq_400_slr0" "clk_gen_slr0"]

            custom_interconnect "axi_inter_msg_send" 512 ${200SLR0ClkPin} 256 ${400SLR0ClkPin} "read_only"
            custom_interconnect "axi_inter_msg_recv_bufwr" 512 ${200SLR0ClkPin} 256 ${400SLR0ClkPin} "write_only"
            custom_interconnect "axi_inter_msg_recv_memcpy" 512 ${200SLR0ClkPin} 256 ${400SLR0ClkPin}

            connect_bd_intf_net [get_bd_intf_pins ${OMPIF::hier}/moMEM] [get_bd_intf_pins ${axi_inter_msg_send::hier}/S_AXI]
            connect_bd_intf_net [get_bd_intf_pins ${OMPIF::hier}/bufwr] [get_bd_intf_pins ${axi_inter_msg_recv_bufwr::hier}/S_AXI]
            connect_bd_intf_net [get_bd_intf_pins ${OMPIF::hier}/memcpy] [get_bd_intf_pins ${axi_inter_msg_recv_memcpy::hier}/S_AXI]

            AIT::AXI::connect_to_mem_intf ${axi_inter_msg_send::masterIntfPin} "" ${400SLR0ClkPin}
            AIT::AXI::connect_to_mem_intf ${axi_inter_msg_recv_memcpy::masterIntfPin} "" ${400SLR0ClkPin}
            AIT::AXI::connect_to_mem_intf ${axi_inter_msg_recv_bufwr::masterIntfPin} "" ${400SLR0ClkPin}
        } else {
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${OMPIF::hier}/bufwr] "" ${ompifClkSrcPin}
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${OMPIF::hier}/memcpy] "" ${ompifClkSrcPin}
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${OMPIF::hier}/moMEM] "" ${ompifClkSrcPin}
        }

        AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${OMPIF::hier}/cntrl_sender] "" ${ompifClkSrcPin} ${ompifRstSrcPin}
        AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${OMPIF::hier}/cntrl_receiver] "" ${ompifClkSrcPin} ${ompifRstSrcPin}

        save_bd_design -quiet
    }

    # Creates basic accelerator hierarchy and instantiates accelerator IP
    proc ompss_acc {accName instanceNum} {
        set accHier [create_bd_cell -type hier ${accName}_${instanceNum}]
        create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ${accHier}/inStream
        create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ${accHier}/outStream
        create_bd_pin -type clk -dir I ${accHier}/aclk
        create_bd_pin -type rst -dir I ${accHier}/managed_aresetn

        set accIP [create_bd_cell -type ip -vlnv bsc:ompss:${accName}_wrapper ${accHier}/${accName}_ompss]
        AIT::clocks::connect_clock [get_bd_pins ${accHier}/aclk] [get_bd_pins ${accIP}/ap_clk]
        AIT::resets::connect_reset [get_bd_pins ${accHier}/managed_aresetn] [get_bd_pins ${accIP}/ap_rst_n]

        return [list ${accHier} ${accIP}]
    }

    proc Picos_OmpSs_Manager {} {
        source_template "Picos_OmpSs_Manager"

        AIT::clocks::connect_clock [get_bd_pins ${hwruntime::hier}/clk]
        AIT::resets::connect_reset [get_bd_pins ${hwruntime::hier}/rstn] [get_bd_pins /system_reset/clk_app_rstn]
        AIT::resets::connect_reset [get_bd_pins ${hwruntime::hier}/managed_rstn] [get_bd_pins system_reset/clk_app_managed_rstn]

        if {([dict get ${AIT::project::board} "arch" "device"] eq "zynq")
            || ([dict get ${AIT::project::board} "arch" "device"] eq "zynqmp")} {

            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${hwruntime::hier}/S_AXI_GP] 1
        } else {
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${hwruntime::hier}/S_AXI_GP]
        }

        save_bd_design -quiet
    }

    proc source_template {templateName {args ""}} {
        variable scriptDir
        AIT::utils::info_msg "Sourcing ${templateName} template..."
        set argv ${args}
        set retObj [source ${scriptDir}/../templates/${templateName}.tcl]
        AIT::utils::info_msg "Successfully sourced ${templateName} template"
        save_bd_design -quiet
        return ${retObj}
    }
}
