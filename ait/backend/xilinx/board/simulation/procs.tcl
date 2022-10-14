# Connects source pin received as argument to the output of the clock generator IP
proc connectClock {srcPin} {
    connect_bd_net -quiet [get_bd_pins $srcPin] [get_bd_pins /clk]
}

# Connects reset
proc connectRst {rst_source rst_name} {
    connect_bd_net -quiet $rst_source [get_bd_pins /rstn]
}

proc setAndGetFreq {targetFreq} {
    return $targetFreq
}

proc configureAddressMap {address_map} {
    #assign_bd_address [get_bd_addr_segs {axi_stub_0/s_axi/reg0 }] -offset 0 -range 16E
}

proc getBaseFreq {} {
    return 100
}

