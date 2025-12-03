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

proc create_OMPIF_hier {} {
    set oldBdInstance [current_bd_instance .]
    set hierObj [create_bd_cell -type hier OMPIF]
    current_bd_instance ${hierObj}

    set ompifClkPin [create_bd_pin -dir I -type clk ompif_clk]
    set ompifRstPin [create_bd_pin -dir I -type rst ompif_aresetn]
    set appClkPin [create_bd_pin -dir I -type clk app_clk]
    set appRstPin [create_bd_pin -dir I -type rst app_aresetn]
    set clusterRankSizePin [create_bd_pin -dir I -type data -from 15 -to 0 cluster_rank_size]
    set ompifRankPin [create_bd_pin -dir O -type data -from 7 -to 0 ompif_rank]
    set ompifSizePin [create_bd_pin -dir O -type data -from 7 -to 0 ompif_size]
    set ethRxIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 ethRx]
    set ethTxIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 ethTx]

    set outStreamSenderIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 outStream_sender]
    set outStreamReceiverIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 outStream_receiver]
    set inStreamSenderIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 inStream_sender]
    set inStreamReceiverIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 inStream_receiver]
    set senderCntrlIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 cntrl_sender]
    set receiverCntrlIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 cntrl_receiver]
    set moMEMIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 moMEM]
    set bufwrIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 bufwr]
    set memcpyIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 memcpy]

    set messageSenderHier [create_message_sender_hier]
    set messageReceiverHier [create_message_receiver_hier]

    set clusterSizeSliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice cluster_size_slice]
    set_property -dict [list \
        CONFIG.DIN_FROM {7} \
        CONFIG.DIN_TO {0} \
        CONFIG.DIN_WIDTH {16} \
        CONFIG.DOUT_WIDTH {8} \
    ] ${clusterSizeSliceIP}

    set clusterRankSliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:xlslice cluster_rank_slice]
    set_property -dict [list \
        CONFIG.DIN_FROM {15} \
        CONFIG.DIN_TO {8} \
        CONFIG.DIN_WIDTH {16} \
        CONFIG.DOUT_WIDTH {8} \
    ] ${clusterRankSliceIP}

    set ethTxSwitchIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch eth_tx_switch]
    set_property -dict [list \
        CONFIG.HAS_TLAST.VALUE_SRC {USER} \
        CONFIG.HAS_TLAST {1} \
        CONFIG.ARB_ON_MAX_XFERS {0} \
        CONFIG.ARB_ON_TLAST {1} \
        CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
    ] ${ethTxSwitchIP}

    set packetDecoderIP [create_bd_cell -type ip -vlnv bsc:ompif:packet_decoder_wrapper packet_decoder]
    set_property -dict [list \
        CONFIG.DATA_WIDTH {512} \
        CONFIG.MAX_CLUSTER_SIZE {96} \
    ] ${packetDecoderIP}

    set packetDecoderSwitchIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_switch packet_decoder_switch]
    set_property -dict [list \
        CONFIG.NUM_SI {1} \
        CONFIG.NUM_MI {2} \
        CONFIG.DECODER_REG {1} \
    ] ${packetDecoderSwitchIP}

    set packetDecoderRegsliceIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_register_slice packet_decoder_regslice]

    connect_bd_net ${clusterRankSizePin} [get_bd_pins ${clusterSizeSliceIP}/Din] [get_bd_pins ${clusterRankSliceIP}/Din]
    connect_bd_net [get_bd_pins ${clusterSizeSliceIP}/Dout] [get_bd_pins ${messageReceiverHier}/cluster_size] [get_bd_pins ${messageSenderHier}/cluster_size] ${ompifSizePin}
    connect_bd_net [get_bd_pins ${clusterRankSliceIP}/Dout] [get_bd_pins ${messageSenderHier}/cluster_rank] ${ompifRankPin}

    connect_bd_intf_net ${ethRxIntfPin} [get_bd_intf_pins ${packetDecoderIP}/si]
    connect_bd_intf_net ${inStreamSenderIntfPin} [get_bd_intf_pins ${messageSenderHier}/siCmd]
    connect_bd_intf_net ${inStreamReceiverIntfPin} [get_bd_intf_pins ${messageReceiverHier}/siCmd]
    connect_bd_intf_net ${receiverCntrlIntfPin} [get_bd_intf_pins ${messageReceiverHier}/cntrl]
    connect_bd_intf_net ${senderCntrlIntfPin} [get_bd_intf_pins ${messageSenderHier}/cntrl]
    connect_bd_intf_net [get_bd_intf_pins ${packetDecoderIP}/soRole] [get_bd_intf_pins ${packetDecoderSwitchIP}/S00_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${packetDecoderIP}/soEnc] [get_bd_intf_pins ${ethTxSwitchIP}/S00_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${messageSenderHier}/soMsg] [get_bd_intf_pins ${ethTxSwitchIP}/S01_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${packetDecoderSwitchIP}/M00_AXIS] [get_bd_intf_pins ${packetDecoderRegsliceIP}/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${packetDecoderSwitchIP}/M01_AXIS] [get_bd_intf_pins ${messageSenderHier}/siAck]
    connect_bd_intf_net [get_bd_intf_pins ${packetDecoderRegsliceIP}/M_AXIS] [get_bd_intf_pins ${messageReceiverHier}/msg_in]
    connect_bd_intf_net [get_bd_intf_pins ${ethTxSwitchIP}/M00_AXIS] ${ethTxIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageSenderHier}/moMEM] ${moMEMIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageSenderHier}/soCmd] ${outStreamSenderIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageReceiverHier}/soCmd] ${outStreamReceiverIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageReceiverHier}/bufwr] ${bufwrIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageReceiverHier}/memcpy] ${memcpyIntfPin}

    connect_bd_net ${ompifClkPin} [get_bd_pins ${packetDecoderIP}/clk] [get_bd_pins ${packetDecoderSwitchIP}/aclk] [get_bd_pins ${packetDecoderRegsliceIP}/aclk] [get_bd_pins ${ethTxSwitchIP}/aclk] [get_bd_pins ${messageReceiverHier}/ompif_clk] [get_bd_pins ${messageSenderHier}/ompif_clk]
    connect_bd_net ${appClkPin} [get_bd_pins ${messageReceiverHier}/app_clk] [get_bd_pins ${messageSenderHier}/app_clk]
    connect_bd_net ${ompifRstPin} [get_bd_pins ${packetDecoderIP}/rstn] [get_bd_pins ${messageReceiverHier}/ompif_aresetn] [get_bd_pins ${messageSenderHier}/ompif_aresetn] [get_bd_pins ${packetDecoderSwitchIP}/aresetn] [get_bd_pins ${packetDecoderRegsliceIP}/aresetn] [get_bd_pins ${ethTxSwitchIP}/aresetn]
    connect_bd_net ${appRstPin} [get_bd_pins ${messageReceiverHier}/app_aresetn] [get_bd_pins ${messageSenderHier}/app_aresetn]

    current_bd_instance ${oldBdInstance}

    return ${hierObj}
}

proc create_message_sender_hier {} {
    set oldBdInstance [current_bd_instance .]
    set hierObj [create_bd_cell -type hier message_sender]

    current_bd_instance ${hierObj}

    set clusterSizePin [create_bd_pin -dir I -type data -from 7 -to 0 cluster_size]
    set clusterRankPin [create_bd_pin -dir I -type data -from 7 -to 0 cluster_rank]
    set ompifClkPin [create_bd_pin -dir I -type clk ompif_clk]
    set ompifRstPin [create_bd_pin -dir I -type rst ompif_aresetn]
    set appClkPin [create_bd_pin -dir I -type clk app_clk]
    set appRstPin [create_bd_pin -dir I -type rst app_aresetn]
    set soMsgIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 soMsg]
    set soCmdIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 soCmd]
    set siCmdIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 siCmd]
    set moMEMIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 moMEM]
    set siAckIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 siAck]
    set cntrlIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 cntrl]

    set messageSenderIP [create_bd_cell -type ip -vlnv bsc:ompif:message_sender ompif_message_sender]
    set_property -dict [list \
        CONFIG.MAX_DEVICES {96} \
        CONFIG.MAX_TIMEOUT {1000000} \
        CONFIG.MAX_TIMEOUT_RAND_RANGE {1000000} \
        CONFIG.DEF_TIMEOUT {100000} CONFIG.DEBUG {1} \
        CONFIG.CONTROL_INTF {1} \
        CONFIG.TOTAL_LAT_WIDTH {40} \
        CONFIG.AXI_ADDR_WIDTH [AIT::board::get_addr_width] \
        CONFIG.AXI_DATA_WIDTH {512} \
        CONFIG.MSG_DATA_SIZE {8960} \
    ] ${messageSenderIP}

    set axisClkConvInIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clk_conv_in]
    set axisClkConvOutIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clk_conv_out]

    connect_bd_net ${clusterSizePin} [get_bd_pins ${messageSenderIP}/cluster_size]
    connect_bd_net ${clusterRankPin} [get_bd_pins ${messageSenderIP}/cluster_rank]

    connect_bd_intf_net [get_bd_intf_pins ${axisClkConvInIP}/M_AXIS] [get_bd_intf_pins ${messageSenderIP}/siCmd]
    connect_bd_intf_net [get_bd_intf_pins ${messageSenderIP}/soCmd] [get_bd_intf_pins ${axisClkConvOutIP}/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${messageSenderIP}/soMsg] ${soMsgIntfPin}
    connect_bd_intf_net ${siAckIntfPin} [get_bd_intf_pins ${messageSenderIP}/siAck]

    connect_bd_net ${ompifClkPin} [get_bd_pins ${messageSenderIP}/clk] [get_bd_pins ${axisClkConvInIP}/m_axis_aclk] [get_bd_pins ${axisClkConvOutIP}/s_axis_aclk]
    connect_bd_net ${appClkPin} [get_bd_pins ${axisClkConvInIP}/s_axis_aclk] [get_bd_pins ${axisClkConvOutIP}/m_axis_aclk]
    connect_bd_net ${ompifRstPin} [get_bd_pins ${messageSenderIP}/rstn] [get_bd_pins ${axisClkConvInIP}/m_axis_aresetn] [get_bd_pins ${axisClkConvOutIP}/s_axis_aresetn]
    connect_bd_net ${appRstPin} [get_bd_pins ${axisClkConvInIP}/s_axis_aresetn] [get_bd_pins ${axisClkConvOutIP}/m_axis_aresetn]

    connect_bd_intf_net [get_bd_intf_pins ${axisClkConvOutIP}/M_AXIS] ${soCmdIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageSenderIP}/moMEM] ${moMEMIntfPin}
    connect_bd_intf_net ${siCmdIntfPin} [get_bd_intf_pins ${axisClkConvInIP}/S_AXIS]
    connect_bd_intf_net ${cntrlIntfPin} [get_bd_intf_pins ${messageSenderIP}/cntrl]

    current_bd_instance ${oldBdInstance}

    return ${hierObj}
}

proc create_message_receiver_hier {} {
    set oldBdInstance [current_bd_instance .]
    set hierObj [create_bd_cell -type hier message_receiver]

    set addrWidth [AIT::board::get_addr_width]

    current_bd_instance ${hierObj}

    set clusterSizePin [create_bd_pin -dir I -type data -from 7 -to 0 cluster_size]
    set ompifClkPin [create_bd_pin -dir I -type clk ompif_clk]
    set ompifRstPin [create_bd_pin -dir I -type rst ompif_aresetn]
    set appClkPin [create_bd_pin -dir I -type clk app_clk]
    set appRstPin [create_bd_pin -dir I -type rst app_aresetn]
    set siCmdIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 siCmd]
    set soCmdIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:axis_rtl:1.0 soCmd]
    set cntrlIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:aximm_rtl:1.0 cntrl]
    set bufwrIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 bufwr]
    set memcpyIntfPin [create_bd_intf_pin -mode Master -vlnv xilinx.com:interface:aximm_rtl:1.0 memcpy]
    set msgInIntfPin [create_bd_intf_pin -mode Slave -vlnv xilinx.com:interface:axis_rtl:1.0 msg_in]

    set messageReceiverIP [create_bd_cell -type ip -vlnv bsc:ompif:message_receiver ompif_message_receiver]
    set_property -dict [list \
    CONFIG.MAX_DEVICES {96} \
    CONFIG.AXI_ADDR_WIDTH ${addrWidth} \
    CONFIG.AXI_DATA_WIDTH {512} \
    CONFIG.MSG_DATA_SIZE {8960} \
    CONFIG.MBUFFER_ADDR_WIDTH {30} \
    CONFIG.MBUFFER_ADDR_PREFIX [expr {2**(${addrWidth} - 30) - 1}] \
    CONFIG.MAX_OUTSTANDING_WRITES {8} \
    ] ${messageReceiverIP}

    set axisClkConvInIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clk_conv_in]
    set axisClkConvOutIP [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_clock_converter axis_clk_conv_out]

    connect_bd_net ${clusterSizePin} [get_bd_pins ${messageReceiverIP}/cluster_size]
    connect_bd_net ${ompifClkPin} [get_bd_pins ${messageReceiverIP}/clk] [get_bd_pins ${axisClkConvInIP}/m_axis_aclk] [get_bd_pins ${axisClkConvOutIP}/s_axis_aclk]
    connect_bd_net ${ompifRstPin} [get_bd_pins ${messageReceiverIP}/rstn] [get_bd_pins ${axisClkConvInIP}/m_axis_aresetn] [get_bd_pins ${axisClkConvOutIP}/s_axis_aresetn]
    connect_bd_net ${appClkPin} [get_bd_pins ${axisClkConvInIP}/s_axis_aclk] [get_bd_pins ${axisClkConvOutIP}/m_axis_aclk]
    connect_bd_net ${appRstPin} [get_bd_pins ${axisClkConvInIP}/s_axis_aresetn] [get_bd_pins ${axisClkConvOutIP}/m_axis_aresetn]

    connect_bd_intf_net [get_bd_intf_pins ${axisClkConvInIP}/M_AXIS] [get_bd_intf_pins ${messageReceiverIP}/siCmd]
    connect_bd_intf_net [get_bd_intf_pins ${messageReceiverIP}/soCmd] [get_bd_intf_pins ${axisClkConvOutIP}/S_AXIS]
    connect_bd_intf_net [get_bd_intf_pins ${messageReceiverIP}/bufwr] ${bufwrIntfPin}
    connect_bd_intf_net ${msgInIntfPin} [get_bd_intf_pins ${messageReceiverIP}/msg_in]
    connect_bd_intf_net [get_bd_intf_pins ${axisClkConvOutIP}/M_AXIS] ${soCmdIntfPin}
    connect_bd_intf_net [get_bd_intf_pins ${messageReceiverIP}/memcpy] ${memcpyIntfPin}
    connect_bd_intf_net ${siCmdIntfPin} [get_bd_intf_pins ${axisClkConvInIP}/S_AXIS]
    connect_bd_intf_net ${cntrlIntfPin} [get_bd_intf_pins ${messageReceiverIP}/cntrl]

    current_bd_instance ${oldBdInstance}

    return ${hierObj}
}

return [create_OMPIF_hier]
