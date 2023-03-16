## Board-specific generic procedures
## Can be overwritten through the file procs.tcl on the board folder

namespace eval AIT {
    namespace eval board {
        variable axi_interfaces

        # Instantiates and connects required common IPs
        proc init_bd {} {
            # If interconnect priorities are enabled, set PCIe master as max priority
            if {${::AIT::interconPriority}} {
                set data_width 32
                if {${::AIT::arch_device} eq "alveo"} {
                    set data_width 512
                } elseif {${::AIT::arch_device} eq "zynqmp"} {
                    set data_width 128
                } elseif {${::AIT::arch_device} eq "zynq"} {
                    set data_width 64
                }

                set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH.VALUE_SRC PROPAGATED CONFIG.XBAR_DATA_WIDTH $data_width] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
                set_property -dict [list CONFIG.S00_ARB_PRIORITY 15] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
            }

            # If enabled, simplify interconnection to memory
            if {${::AIT::simplify_interconnection}} {
                move_bd_cells [get_bd_cells /] [get_bd_cells bridge_to_host/DDR_S_AXI_Inter]
                delete_bd_objs [get_bd_cells S_AXI_Inter]
                set_property name S_AXI_Inter [get_bd_cells DDR_S_AXI_Inter]
            }

            get_bd_axi_interfaces

            # Create instance: bitInfo, and set properties
            set bitInfo [ create_bd_cell -type ip -vlnv xilinx.com:ip:blk_mem_gen bitInfo ]
            set_property -dict [ list \
                CONFIG.Byte_Size {8} \
                CONFIG.EN_SAFETY_CKT {false} \
                CONFIG.Enable_32bit_Address {true} \
                CONFIG.Fill_Remaining_Memory_Locations {false} \
                CONFIG.Load_Init_File {false} \
                CONFIG.Memory_Type {Single_Port_RAM} \
                CONFIG.Register_PortA_Output_of_Memory_Primitives {false} \
                CONFIG.Remaining_Memory_Locations {0} \
                CONFIG.Use_Byte_Write_Enable {true} \
                CONFIG.Use_RSTA_Pin {false} \
                CONFIG.Write_Depth_A {1024} \
                CONFIG.Write_Width_B {32} \
                CONFIG.Read_Width_A {32} \
                CONFIG.Read_Width_B {32} \
                CONFIG.use_bram_block {Stand_Alone} \
             ] $bitInfo

            # Create instance: bitInfo_BRAM_Ctrl, and set properties
            set bitInfo_BRAM_Ctrl [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_bram_ctrl bitInfo_BRAM_Ctrl ]
            set_property -dict [ list \
                CONFIG.PROTOCOL {AXI4} \
                CONFIG.SINGLE_PORT_BRAM {1} \
             ] $bitInfo_BRAM_Ctrl

            # Create instance: managed_reset, and set properties
            set managed_reset [ create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio managed_reset ]
            set_property -dict [ list \
                CONFIG.C_ALL_OUTPUTS {1} \
                CONFIG.C_DOUT_DEFAULT {0x00000001} \
                CONFIG.C_GPIO_WIDTH {1} \
             ] $managed_reset

            # Create instance: reset_AND, and set properties
            set reset_AND [ create_bd_cell -type ip -vlnv xilinx.com:ip:util_vector_logic reset_AND ]
            set_property -dict [ list \
                CONFIG.C_SIZE {1} \
                CONFIG.C_OPERATION {and} \
             ] $reset_AND

            connect_bd_net [get_bd_pins managed_reset/gpio_io_o] [get_bd_pins reset_AND/Op1]
            connect_reset [get_bd_pins reset_AND/Op2] "peripheral"

            if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
                connect_to_axi_interface [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] M 1
                connect_to_axi_interface [get_bd_intf_pins managed_reset/S_AXI] M 1
            } else {
                connect_to_axi_interface [get_bd_intf_pins bitInfo_BRAM_Ctrl/S_AXI] M
                connect_to_axi_interface [get_bd_intf_pins managed_reset/S_AXI] M
            }
            connect_bd_intf_net [get_bd_intf_pins bitInfo/BRAM_PORTA] [get_bd_intf_pins bitInfo_BRAM_Ctrl/BRAM_PORTA]
            connect_clock [get_bd_pins bitInfo_BRAM_Ctrl/s_axi_aclk]
            connect_reset [get_bd_pins bitInfo_BRAM_Ctrl/s_axi_aresetn] "peripheral"
            connect_clock [get_bd_pins managed_reset/s_axi_aclk]
            connect_reset [get_bd_pins managed_reset/s_axi_aresetn] "peripheral"
        }

        # Initializes axi_interfaces variable with the available AXI interfaces along with their occupation
        proc get_bd_axi_interfaces {} {
            variable axi_interfaces
            set axi_interfaces {}

            set interconnect_list [get_bd_cells -regexp (M|S)_AXI(_([0-9])*)?_Inter]
            foreach interconnect $interconnect_list {
                set mode [string trim [regsub -all {_AXI_.+$} $interconnect ""] "/"]
                set counter [expr [get_property CONFIG.NUM_${mode}I $interconnect] - 1]
                set capacity 16
                if {$counter < $capacity} {
                    lappend axi_interfaces "$mode [string trim $interconnect "/"] $counter $capacity"
                }
            }

            set axi_interfaces [lsort -integer -index 2 -increasing $axi_interfaces]
        }

        # Returns the total number of free AXI data interfaces
        proc get_available_data_ports {} {
            variable axi_interfaces
            set available_ports 0

            foreach interface $axi_interfaces {
                foreach {mode name counter capacity} $interface {
                    if {$mode eq "S"} {
                        incr available_ports [expr $capacity - $counter]
                    }
                }
            }

            return $available_ports
        }

        # Maps board memory to address map
        proc configure_address_map {} {
            AIT::info_msg "Using generic configure_address_map procedure"

            set mem_type [dict get ${::AIT::address_map} "mem_type"]
            set base_addr [dict get ${::AIT::address_map} "mem_base_addr"]

            # Assign memory address space
            if {(${::AIT::arch_device} eq "zynq") || (${::AIT::arch_device} eq "zynqmp")} {
                set mem_size [dict get ${::AIT::address_map} "mem_size"]
                assign_bd_address [get_bd_addr_segs -regexp ".*HP._DDR_LOW.*"]
                set_property -quiet offset $base_addr [get_bd_addr_segs -regexp ".*SEG_.*HP._DDR_LOW.*"]
                set_property -quiet range $mem_size [get_bd_addr_segs -regexp ".*SEG_.*HP._DDR_LOW.*"]
            } elseif {${::AIT::arch_device} eq "alveo"} {
                set bank_size [dict get ${::AIT::address_map} "mem_bank_size"]
                set num_banks [dict get ${::AIT::address_map} "mem_num_banks"]
                if {$mem_type eq "ddr"} {
                    for {set i 0} {$i < $num_banks} {incr i} {
                        if {[llength [get_bd_addr_segs -regexp ".*DDR_${i}.*_DDR4_ADDRESS_BLOCK"]]} {
                            assign_bd_address [get_bd_addr_segs -regexp ".*DDR_${i}.*_DDR4_ADDRESS_BLOCK"] -offset [expr $base_addr + $bank_size*$i] -range $bank_size
                        }
                    }
                } elseif {$mem_type eq "hbm"} {
                    for {set i 0} {$i < $num_banks} {incr i} {
                        if {[llength [get_bd_addr_segs -regexp ".*SAXI_[format %02u $i].*HBM_MEM.*"]]} {
                            for {set j 0} {$j < $num_banks} {incr j} {
                                assign_bd_address [get_bd_addr_segs -regexp ".*SAXI_[format %02u $i].*HBM_MEM[format %02u $j]"] -offset [expr $base_addr + $bank_size*$j] -range $bank_size
                            }
                        }
                    }
                }
            }
        }

        # Creates and connects a tree of interconnects that allows an arbitrary number of AXI-stream slaves to connect to up to 16 AXI-stream masters
        proc create_inStream_Inter_tree { stream_name nmasters nslaves clk inter_rstn peri_rstn } {
            set ninter [expr int(ceil($nslaves/16.))]
            set prev_ninter $nslaves
            set inter_level 0
            set inter_stride 1

            # First level uses interconnects with more than one master if required
            for {set i 0} {$i < $ninter} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_$i

                # Last interconnect may need less slaves
                if {($i == $ninter-1) && ($prev_ninter%16)} {
                    set num_si [expr $prev_ninter%16]
                } else {
                    set num_si 16
                }

                # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
                if {$num_si > 1} {
                    set inter_conf [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
                } else {
                    set inter_conf {}
                }

                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                lappend inter_conf CONFIG.NUM_MI $nmasters CONFIG.NUM_SI $num_si
                set_property -dict $inter_conf $inter

                connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                for {set j 0} {$j < $num_si} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN]
                }
                for {set j 0} {$j < $nmasters} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN]
                }
            }

            set prev_ninter $ninter
            set ninter [expr int(ceil($ninter/16.))]
            incr inter_level

            while {$ninter < $prev_ninter} {
                for {set m 0} {$m < $nmasters} {incr m} {
                    for {set i 0} {$i < $ninter} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_m${m}_$i

                        # Last interconnect may need less slaves
                        if {($i == $ninter-1) && ($prev_ninter%16)} {
                            set num_si [expr $prev_ninter%16]
                        } else {
                            set num_si 16
                        }

                        if {$num_si > 1} {
                            set inter_conf [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
                        } else {
                            set inter_conf {}
                        }

                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                        lappend inter_conf \
                            CONFIG.M00_AXIS_BASETDEST {0x00000000} \
                            CONFIG.M00_AXIS_HIGHTDEST {0xFFFFFFFF} \
                            CONFIG.NUM_MI {1} \
                            CONFIG.NUM_SI $num_si
                        set_property -dict $inter_conf $inter

                        connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                        connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                        for {set j 0} {$j < $num_si} {incr j} {
                            set inf_num [format %02u $j]
                            connect_bd_net $clk [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
                            connect_bd_net $peri_rstn [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN]
                        }
                        connect_bd_net $clk [get_bd_pins $inter_name/M00_AXIS_ACLK]
                        connect_bd_net $peri_rstn [get_bd_pins $inter_name/M00_AXIS_ARESETN]

                        for {set j 0} {$j < $num_si} {incr j} {
                            set master_inter_num [expr $i*16 + $j]
                            set master_inter_level [expr $inter_level-1]
                            if {$inter_level == 1} {
                                set master_inf [format %02u $m]
                                set master_inter ${stream_name}_lvl${master_inter_level}_$master_inter_num
                            } else {
                                set master_inf 00
                                set master_inter ${stream_name}_lvl${master_inter_level}_m${m}_$master_inter_num
                            }
                            set slave [format %02u [expr $j%16]]
                            connect_bd_intf_net [get_bd_intf_pins $master_inter/M${master_inf}_AXIS] [get_bd_intf_pins $inter_name/S${slave}_AXIS]
                        }
                    }
                }
                set prev_ninter $ninter
                set ninter [expr int(ceil($ninter/16.))]
                incr inter_level
            }
            return [expr $inter_level-1]
        }

        # Creates and connects a tree of interconnects that allows up to 16 AXI-stream masters to connect with an arbitrary number of AXI-stream slaves
        proc create_outStream_Inter_tree { stream_name nslaves nmasters clk inter_rstn peri_rstn } {
            set ninter [expr int(ceil($nmasters/16.))]
            set prev_ninter $nmasters
            set inter_level 0
            set stride 1

            # In case there is only one slave do not set arbitration parameters to avoid Vivado warnings
            if {$nslaves > 1} {
                set arb_config [list CONFIG.ARB_ON_MAX_XFERS {0} CONFIG.ARB_ON_TLAST {1}]
            } else {
                set arb_config {}
            }

            # First level uses interconnects with more than one slave if required
            for {set i 0} {$i < $ninter} {incr i} {
                set inter_name ${stream_name}_lvl${inter_level}_$i

                # Last interconnect may need less masters
                if {($i == $ninter-1) && ($prev_ninter%16)} {
                    set num_mi [expr $prev_ninter%16]
                } else {
                    set num_mi 16
                }

                set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                set inter_conf $arb_config
                lappend inter_conf CONFIG.NUM_MI $num_mi CONFIG.NUM_SI $nslaves

                for {set j 0} {$j < $num_mi} {incr j} {
                    set master_num [format %02u $j]
                    set base_dest [format "32\'d%d" [expr $i*$stride*16 + $j*$stride]]
                    set high_dest [format "32\'d%d" [expr $i*$stride*16 + ($j+1)*$stride - 1]]
                    lappend inter_conf CONFIG.M${master_num}_AXIS_BASETDEST $base_dest CONFIG.M${master_num}_AXIS_HIGHTDEST $high_dest
                }

                set_property -dict $inter_conf $inter

                connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                for {set j 0} { $j < $num_mi} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN]
                }
                for {set j 0} {$j < $nslaves} {incr j} {
                    set inf_num [format %02u $j]
                    connect_bd_net $clk [get_bd_pins $inter_name/S${inf_num}_AXIS_ACLK]
                    connect_bd_net $peri_rstn [get_bd_pins $inter_name/S${inf_num}_AXIS_ARESETN]
                }
            }

            set prev_ninter $ninter
            set ninter [expr int(ceil($ninter/16.))]
            set stride [expr $stride*16]
            incr inter_level

            while {$ninter < $prev_ninter} {
                for {set s 0} {$s < $nslaves} {incr s} {
                    for {set i 0} {$i < $ninter} {incr i} {

                        set inter_name ${stream_name}_lvl${inter_level}_s${s}_$i

                        # Last interconnect may need less masters
                        if {($i == $ninter-1) && ($prev_ninter%16)} {
                            set num_mi [expr $prev_ninter%16]
                        } else {
                            set num_mi 16
                        }

                        set inter [create_bd_cell -type ip -vlnv xilinx.com:ip:axis_interconnect $inter_name]
                        set inter_conf [list CONFIG.NUM_MI $num_mi CONFIG.NUM_SI {1}]

                        for {set j 0} {$j < $num_mi} {incr j} {
                            set master_num [format %02u $j]
                            set base_dest [format "32\'d%d" [expr $i*$stride*16 + $j*$stride]]
                            set high_dest [format "32\'d%d" [expr $i*$stride*16 + ($j+1)*$stride - 1]]
                            lappend inter_conf CONFIG.M${master_num}_AXIS_BASETDEST $base_dest CONFIG.M${master_num}_AXIS_HIGHTDEST $high_dest
                        }

                        set_property -dict $inter_conf $inter

                        connect_bd_net $clk [get_bd_pins $inter_name/ACLK]
                        connect_bd_net $inter_rstn [get_bd_pins $inter_name/ARESETN]
                        for {set j 0} { $j < $num_mi} {incr j} {
                            set inf_num [format %02u $j]
                            connect_bd_net $clk [get_bd_pins $inter_name/M${inf_num}_AXIS_ACLK]
                            connect_bd_net $peri_rstn [get_bd_pins $inter_name/M${inf_num}_AXIS_ARESETN]
                        }
                        connect_bd_net $clk [get_bd_pins $inter_name/S00_AXIS_ACLK]
                        connect_bd_net $peri_rstn [get_bd_pins $inter_name/S00_AXIS_ARESETN]

                        for {set j 0} {$j < $num_mi} {incr j} {
                            set slave_inter_num [expr $i*16+$j]
                            set slave_inter_level [expr $inter_level-1]
                            set master [format %02u $j]
                            if {$inter_level == 1} {
                                set slave_inf [format %02u $s]
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_$slave_inter_num
                            } else {
                                set slave_inf 00
                                set slave_inter ${stream_name}_lvl${slave_inter_level}_s${s}_$slave_inter_num
                            }
                            connect_bd_intf_net [get_bd_intf_pins $slave_inter/S${slave_inf}_AXIS] [get_bd_intf_pins $inter_name/M${master}_AXIS]
                        }
                    }
                }
                set prev_ninter $ninter
                set ninter [expr int(ceil($ninter/16.))]
                set stride [expr $stride*16]
                incr inter_level
            }
            return [expr $inter_level-1]
        }

        # Creates and connects a nested interconnect
        proc create_nested_interconnect {parent_inter {num 1}} {
            variable axi_interfaces
            set index [lsearch -regexp ${::AIT::board::axi_interfaces} $parent_inter]
            set axi_interfaces [lreplace $axi_interfaces $index $index]

            AIT::info_msg "Creating $num nested interconnects for $parent_inter"

            set parent_inter_slaves [get_property CONFIG.NUM_SI [get_bd_cells $parent_inter]]
            set_property CONFIG.NUM_SI [expr $parent_inter_slaves + $num - 1] [get_bd_cells $parent_inter]
            for {set i 0} {$i < $num} {incr i} {
                set nested_inter "${parent_inter}_$i"
                set port_num [format %02u [expr $parent_inter_slaves + $i - 1]]

                # Create new nested interconnect and configure it
                create_bd_cell -vlnv xilinx.com:ip:axi_interconnect $nested_inter
                set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1} CONFIG.STRATEGY ${::AIT::interconOpt}] [get_bd_cells $nested_inter]

                # Connect clocks and resets
                connect_clock [get_bd_pins $nested_inter/ACLK]
                connect_clock [get_bd_pins $nested_inter/M00_ACLK]
                connect_reset [get_bd_pins $nested_inter/ARESETN] "interconnect"
                connect_reset [get_bd_pins $nested_inter/M00_ARESETN] "peripheral"

                # Connect nested interconnect to parent interconnect
                connect_bd_intf_net -boundary_type upper [get_bd_intf_pins $parent_inter/S${port_num}_AXI] [get_bd_intf_pins $nested_inter/M00_AXI]

                connect_clock [get_bd_pins $parent_inter/S${port_num}_ACLK]
                connect_reset [get_bd_pins $parent_inter/S${port_num}_ARESETN] "peripheral"

                lappend axi_interfaces "S [string trim $nested_inter "/"] 0 16"
            }
            set axi_interfaces [lsort -integer -index 2 -increasing $axi_interfaces]
        }

        # Connects the IP to the host through the given port
        proc connect_to_axi_interface {src mode {num ""}} {
            variable axi_interfaces

            # Look for src in dataInterfaces_map
            set index [lsearch -regexp ${::AIT::dataInterfaces_map} [string trim $src "/"]]
            if {$index != -1} {
                set port [lindex [lindex ${::AIT::dataInterfaces_map} $index] 1]
                # Port must be 'S_AXI_X' where X is the value we need for $num
                regsub {S_AXI_} $port "" num
            }

            # Get AXI interface by num or the least occupied
            if {$num ne ""} {
                set index [lsearch -exact $axi_interfaces [lsearch -regexp -inline -index 1 [lsearch -all -inline -index 0 $axi_interfaces $mode] .*_(0)?$num.*]]
                if {$index == -1} {
                    if {$mode eq "S"} {
                        set mode "slave"
                    } elseif {$mode eq "M"} {
                        set mode "master"
                    }
                    AIT::error_msg "Cannot connect $src to $mode interface $num. It does not exist"
                }
            } else {
                set index [lsearch -index 0 $axi_interfaces $mode]
            }

            set mode [lindex [lindex $axi_interfaces $index] 0]
            set dst_name [lindex [lindex $axi_interfaces $index] 1]
            set counter [lindex [lindex $axi_interfaces $index] 2]
            set capacity [lindex [lindex $axi_interfaces $index] 3]
            set axi_interfaces [lreplace $axi_interfaces $index $index]

            # Interconnect is full
            if {!($counter%$capacity) && ($counter > 0)} {
                AIT::error_msg "${dst_name} interface occupation is 100%"
            }

            set dst [get_bd_cells -hierarchical $dst_name]

            set port ${mode}[format %02u $counter]

            set_property -dict [list CONFIG.NUM_${mode}I [expr $counter + 1]] $dst
            set_property -quiet -dict [list CONFIG.STRATEGY ${::AIT::interconOpt}] $dst

            if {${::AIT::interconPriority}} {
                set data_width 32
                if {${::AIT::arch_device} eq "alveo"} {
                    set data_width 512
                } elseif {${::AIT::arch_device} eq "zynqmp"} {
                    set data_width 128
                } elseif {${::AIT::arch_device} eq "zynq"} {
                    set data_width 64
                }

                # Enable advanced settings in order to set priorities and set proper data path
                set_property -dict [list CONFIG.ENABLE_ADVANCED_OPTIONS {1} CONFIG.XBAR_DATA_WIDTH.VALUE_SRC PROPAGATED] $dst
                # Set priority (0-15)
                set_property -dict [list CONFIG.${port}_ARB_PRIORITY [expr 15 - ($counter%16)] CONFIG.XBAR_DATA_WIDTH $data_width] $dst
            }

            set axi_pin [get_bd_intf_pins $dst/${port}_AXI]
            set clk_pin [get_bd_pins $dst/${port}_ACLK]
            set rst_pin [get_bd_pins $dst/${port}_ARESETN]

            # Only interleave slave interfaces
            if {($mode eq "S") && (${::AIT::interleaving_stride} ne "None")} {
                connect_bd_net [get_bd_pins ${src}_awaddr] [get_bd_pins ${axi_pin}_awaddr]
                connect_bd_net [get_bd_pins ${src}_araddr] [get_bd_pins ${axi_pin}_araddr]
            }

            connect_clock $clk_pin
            connect_reset $rst_pin "peripheral"
            connect_bd_intf_net -boundary_type upper $src $axi_pin

            incr counter

            lappend axi_interfaces "$mode $dst_name $counter $capacity"
            set axi_interfaces [lsort -integer -index 2 -increasing $axi_interfaces]

            return [list "$dst_name" "${mode}_AXI"]
        }

        # Connects source clock pin to the output of the clock generator IP
        proc connect_clock {src_clk} {
            if {!([llength [get_bd_nets -quiet -of_objects $src_clk]])} {
                connect_bd_net $src_clk [get_bd_pins clock_generator/clk_out1]
            }
        }

        # Connects source reset to either interconnect or peripheral reset
        proc connect_reset {src_rst dst_rst} {
            if {!([llength [get_bd_nets -quiet -of_objects $src_rst]])} {
                connect_bd_net $src_rst [get_bd_pins processor_system_reset/${dst_rst}_aresetn]
            }
        }

        # Sets target frequency, retrieves actual achieved frequency and returns it
        proc set_and_get_freq {targetFreq} {
            AIT::info_msg "Using generic set_and_get_freq procedure"

            set_property -dict [list CONFIG.CLKOUT1_REQUESTED_OUT_FREQ $targetFreq] [get_bd_cells clock_generator]
            set actFreq [expr [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_out1]]/1000000]

            return $actFreq
        }

        # Returns base frequency used to feed the clock generator
        proc get_base_freq {} {

            if {[llength [get_bd_pins -quiet clock_generator/clk_in1]]} {
                # Using single pin clocks
                set baseFreq [get_property CONFIG.FREQ_HZ [get_bd_pins clock_generator/clk_in1]]
            } else {
                # Using differential clock
                set baseFreq [get_property CONFIG.FREQ_HZ [get_bd_intf_pins clock_generator/clk_in1_d]]

            }
            return $baseFreq
        }


        # Generates HDL wrapper
        proc generate_wrapper {} {
            AIT::info_msg "Using generic generate_wrapper procedure"

            set_property target_language ${::AIT::target_lang} [current_project]

            make_wrapper -files [get_files [current_bd_design].bd] -top -import -force
        }

        # Removes derelict and unused IPs
        proc cleanup_bd {} {
            variable axi_interfaces

            foreach interface $axi_interfaces {
                foreach {mode name counter capacity} $interface {
                    if {$counter == 0} {
                        set mem_type [dict get ${::AIT::address_map} "mem_type"]
                        if {$mem_type eq "hbm"} {
                            set port [string trim [string trim $name {_Inter}] {S_AXI_}]
                            set_property -dict [list CONFIG.USER_SAXI_$port {false}] [get_bd_cells -hierarchical HBM]
                            delete_bd_objs [get_bd_intf_pins bridge_to_host/memory/S${port}_AXI]
                            delete_bd_objs [get_bd_intf_pins bridge_to_host/S${port}_AXI]
                        }
                        delete_bd_objs [get_bd_cells -hierarchical $name]
                    }
                }
            }
        }
    }
}
