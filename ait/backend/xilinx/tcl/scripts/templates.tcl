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
    namespace eval templates {
        variable scriptDir [file dirname [file normalize [info script]]]

        proc base_design {designName} {
            AIT::templates::source_template "baseDesign" [dict get ${AIT::vars::aitConfig} "name"]
        }

        proc ethernet_subsystem {} {
            set oldBdDesign [current_bd_design .]
            set ethSubsysDesign [AIT::templates::source_template "ethernet_subsystem"]
            set ::AIT::vars::ethSubsys ${ethSubsysDesign}

            current_bd_design ${ethSubsysDesign}
            AIT::board::configure_ethernet_subsystem
            validate_bd_design -quiet
            save_bd_design -quiet
            current_bd_design ${oldBdDesign}
            AIT::board::instantiate_ethernet_subsystem

            save_bd_design -quiet
            return ${ethSubsysDesign}
        }

        proc OMPIF {} {
            set ethSubsysDesign [AIT::templates::ethernet_subsystem]
            set ompifHier [AIT::templates::source_template "ompif"]

            set ompifClkSrcPin [get_bd_pins [dict get ${AIT::vars::board} "ompif" "clk"]]
            set ompifRstSrcPin [get_bd_pins [dict get ${AIT::vars::board} "ompif" "rst"]]

            connect_bd_intf_net [get_bd_intf_pins ${ompifHier}/ethTx] [get_bd_intf_pins ${ethSubsysDesign}/S_AXIS]
            connect_bd_intf_net [get_bd_intf_pins ${ethSubsysDesign}/msg_rx] [get_bd_intf_pins ${ompifHier}/ethRx]

            AIT::design::connect_clock [get_bd_pins ${ompifHier}/app_clk]
            AIT::design::connect_clock [get_bd_pins ${ompifHier}/ompif_clk] ${ompifClkSrcPin}
            AIT::design::connect_reset [get_bd_pins ${ompifHier}/app_aresetn]
            AIT::design::connect_reset [get_bd_pins ${ompifHier}/ompif_aresetn] ${ompifRstSrcPin}

            connect_bd_net [get_bd_pins ${ompifHier}/cluster_rank_size] [get_bd_pins jtag_gpio/gpio2_io_o]

            if {[dict get ${AIT::vars::board} "name"] eq "alveo_u55c"
                || [dict get ${AIT::vars::board} "name"] eq "alveo_u280_hbm"} {
                connect_bd_intf_net [get_bd_intf_pins ${ompifHier}/bufwr] [get_bd_intf_pins axi_inter_msg_recv_bufwr/S_AXI]
                connect_bd_intf_net [get_bd_intf_pins ${ompifHier}/moMEM] [get_bd_intf_pins axi_inter_msg_send/S_AXI]
                connect_bd_intf_net [get_bd_intf_pins ${ompifHier}/memcpy] [get_bd_intf_pins axi_inter_msg_recv_memcpy/S_AXI]
            } else {
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${ompifHier}/bufwr] "" ${ompifClkSrcPin}
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${ompifHier}/memcpy] "" ${ompifClkSrcPin}
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${ompifHier}/moMEM] "" ${ompifClkSrcPin}
            }
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${ompifHier}/cntrl_sender] "" ${ompifClkSrcPin} ${ompifRstSrcPin}
            AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${ompifHier}/cntrl_receiver] "" ${ompifClkSrcPin} ${ompifRstSrcPin}

            set ::AIT::vars::OMPIF ${ompifHier}

            save_bd_design -quiet
            return ${ompifHier}
        }

        # Creates basic accelerator hierarchy and instantiates accelerator IP
        proc ompss_acc {accName instanceNum} {
            set accHier [create_bd_cell -type hier ${accName}_${instanceNum}]
            create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ${accHier}/inStream
            create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ${accHier}/outStream
            create_bd_pin -type clk -dir I ${accHier}/aclk
            create_bd_pin -type rst -dir I ${accHier}/managed_aresetn

            set accIP [create_bd_cell -type ip -vlnv bsc:ompss:${accName}_wrapper ${accHier}/${accName}_ompss]
            AIT::design::connect_clock [get_bd_pins ${accHier}/aclk] [get_bd_pins ${accIP}/ap_clk]
            AIT::design::connect_reset [get_bd_pins ${accHier}/managed_aresetn] [get_bd_pins ${accIP}/ap_rst_n]

            return [list ${accHier} ${accIP}]
        }

        proc Picos_OmpSs_Manager {} {
            set PicosOmpSsManagerHier [AIT::templates::source_template "Picos_OmpSs_Manager"]
            if {[dict get ${AIT::vars::aitConfig} "hwruntime_interconnect"] eq "centralized"} {
                AIT::templates::source_template "hwr_central_interconnect"
            } else {
                AIT::templates::source_template "hwr_dist_interconnect"
            }

            AIT::design::connect_clock [get_bd_pins ${PicosOmpSsManagerHier}/clk]
            AIT::design::connect_reset [get_bd_pins ${PicosOmpSsManagerHier}/rstn] [get_bd_pins /system_reset/clk_app_rstn]
            AIT::design::connect_reset [get_bd_pins ${PicosOmpSsManagerHier}/managed_rstn] [get_bd_pins system_reset/clk_app_managed_rstn]

            if {([dict get ${AIT::vars::board} "arch" "device"] eq "zynq")
                || ([dict get ${AIT::vars::board} "arch" "device"] eq "zynqmp")} {

                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${PicosOmpSsManagerHier}/S_AXI_GP] 1
            } else {
                AIT::AXI::connect_to_mem_intf [get_bd_intf_pins ${PicosOmpSsManagerHier}/S_AXI_GP]
            }

            set ::AIT::vars::HWR ${PicosOmpSsManagerHier}

            save_bd_design -quiet
            return ${PicosOmpSsManagerHier}
        }

        proc source_template {templateName {args ""}} {
            AIT::utils::info_msg "Sourcing ${templateName} template..."
            set argv ${args}
            set retObj [source ${AIT::templates::scriptDir}/../templates/${templateName}.tcl]
            AIT::utils::info_msg "Successfully sourced ${templateName} template"
            save_bd_design -quiet
            return ${retObj}
        }
    }
}
