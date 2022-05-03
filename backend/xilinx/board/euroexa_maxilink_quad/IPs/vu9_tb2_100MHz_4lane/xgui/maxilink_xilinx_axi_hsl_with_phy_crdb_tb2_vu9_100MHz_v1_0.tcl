# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "CFGS_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAXI_APEVU9_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAXI_APEZU9_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAXI_VU9M0_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAXI_VU9M1_ID_WIDTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "MAXI_ZU9M_ID_WIDTH" -parent ${Page_0}


}

proc update_PARAM_VALUE.CFGS_ID_WIDTH { PARAM_VALUE.CFGS_ID_WIDTH } {
	# Procedure called to update CFGS_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CFGS_ID_WIDTH { PARAM_VALUE.CFGS_ID_WIDTH } {
	# Procedure called to validate CFGS_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_APEVU9_ID_WIDTH { PARAM_VALUE.MAXI_APEVU9_ID_WIDTH } {
	# Procedure called to update MAXI_APEVU9_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_APEVU9_ID_WIDTH { PARAM_VALUE.MAXI_APEVU9_ID_WIDTH } {
	# Procedure called to validate MAXI_APEVU9_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_APEZU9_ID_WIDTH { PARAM_VALUE.MAXI_APEZU9_ID_WIDTH } {
	# Procedure called to update MAXI_APEZU9_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_APEZU9_ID_WIDTH { PARAM_VALUE.MAXI_APEZU9_ID_WIDTH } {
	# Procedure called to validate MAXI_APEZU9_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_VU9M0_ID_WIDTH { PARAM_VALUE.MAXI_VU9M0_ID_WIDTH } {
	# Procedure called to update MAXI_VU9M0_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_VU9M0_ID_WIDTH { PARAM_VALUE.MAXI_VU9M0_ID_WIDTH } {
	# Procedure called to validate MAXI_VU9M0_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_VU9M1_ID_WIDTH { PARAM_VALUE.MAXI_VU9M1_ID_WIDTH } {
	# Procedure called to update MAXI_VU9M1_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_VU9M1_ID_WIDTH { PARAM_VALUE.MAXI_VU9M1_ID_WIDTH } {
	# Procedure called to validate MAXI_VU9M1_ID_WIDTH
	return true
}

proc update_PARAM_VALUE.MAXI_ZU9M_ID_WIDTH { PARAM_VALUE.MAXI_ZU9M_ID_WIDTH } {
	# Procedure called to update MAXI_ZU9M_ID_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.MAXI_ZU9M_ID_WIDTH { PARAM_VALUE.MAXI_ZU9M_ID_WIDTH } {
	# Procedure called to validate MAXI_ZU9M_ID_WIDTH
	return true
}


proc update_MODELPARAM_VALUE.MAXI_ZU9M_ID_WIDTH { MODELPARAM_VALUE.MAXI_ZU9M_ID_WIDTH PARAM_VALUE.MAXI_ZU9M_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_ZU9M_ID_WIDTH}] ${MODELPARAM_VALUE.MAXI_ZU9M_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_APEZU9_ID_WIDTH { MODELPARAM_VALUE.MAXI_APEZU9_ID_WIDTH PARAM_VALUE.MAXI_APEZU9_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_APEZU9_ID_WIDTH}] ${MODELPARAM_VALUE.MAXI_APEZU9_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_VU9M1_ID_WIDTH { MODELPARAM_VALUE.MAXI_VU9M1_ID_WIDTH PARAM_VALUE.MAXI_VU9M1_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_VU9M1_ID_WIDTH}] ${MODELPARAM_VALUE.MAXI_VU9M1_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_VU9M0_ID_WIDTH { MODELPARAM_VALUE.MAXI_VU9M0_ID_WIDTH PARAM_VALUE.MAXI_VU9M0_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_VU9M0_ID_WIDTH}] ${MODELPARAM_VALUE.MAXI_VU9M0_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.MAXI_APEVU9_ID_WIDTH { MODELPARAM_VALUE.MAXI_APEVU9_ID_WIDTH PARAM_VALUE.MAXI_APEVU9_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.MAXI_APEVU9_ID_WIDTH}] ${MODELPARAM_VALUE.MAXI_APEVU9_ID_WIDTH}
}

proc update_MODELPARAM_VALUE.CFGS_ID_WIDTH { MODELPARAM_VALUE.CFGS_ID_WIDTH PARAM_VALUE.CFGS_ID_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CFGS_ID_WIDTH}] ${MODELPARAM_VALUE.CFGS_ID_WIDTH}
}

