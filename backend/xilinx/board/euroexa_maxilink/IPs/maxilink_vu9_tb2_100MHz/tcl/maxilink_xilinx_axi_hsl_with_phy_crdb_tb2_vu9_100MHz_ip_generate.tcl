    ipx::package_project -root_dir ${src_directory} -vendor manchester.ac.uk -library maxilink -taxonomy /TB2

    ipx::infer_bus_interface clk_freerun_in xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
    ipx::remove_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces clk_freerun_in -of_objects [ipx::current_core]]
    ipx::remove_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces clk_freerun_in -of_objects [ipx::current_core]]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces clk_freerun_in -of_objects [ipx::current_core]]
    set_property value 150000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces clk_freerun_in -of_objects [ipx::current_core]]]
    ipx::infer_bus_interface mgtrefclk xilinx.com:signal:clock_rtl:1.0 [ipx::current_core]
    ipx::remove_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces mgtrefclk -of_objects [ipx::current_core]]
    ipx::remove_bus_parameter ASSOCIATED_RESET [ipx::get_bus_interfaces mgtrefclk -of_objects [ipx::current_core]]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces mgtrefclk -of_objects [ipx::current_core]]
    set_property value 100000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces mgtrefclk -of_objects [ipx::current_core]]]
    ipx::associate_bus_interfaces -busif maxi_zu9m -clock zu9_axi_clk [ipx::current_core]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces maxi_zu9m -of_objects [ipx::current_core]]
    set_property value 300000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces maxi_zu9m -of_objects [ipx::current_core]]]
    ipx::associate_bus_interfaces -busif maxi_apezu9 -clock zu9_axi_clk [ipx::current_core]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces maxi_apezu9 -of_objects [ipx::current_core]]
    set_property value 300000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces maxi_apezu9 -of_objects [ipx::current_core]]]
    ipx::associate_bus_interfaces -busif maxi_vu9m1 -clock zu9_cci_clk [ipx::current_core]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces maxi_vu9m1 -of_objects [ipx::current_core]]
    set_property value 150000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces maxi_vu9m1 -of_objects [ipx::current_core]]]
    ipx::associate_bus_interfaces -busif maxi_vu9m0 -clock zu9_cci_clk [ipx::current_core]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces maxi_vu9m0 -of_objects [ipx::current_core]]
    set_property value 150000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces maxi_vu9m0 -of_objects [ipx::current_core]]]
    ipx::associate_bus_interfaces -busif maxi_apevu9 -clock zu9_axi_clk [ipx::current_core]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces maxi_apevu9 -of_objects [ipx::current_core]]
    set_property value 300000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces maxi_apevu9 -of_objects [ipx::current_core]]]
    ipx::associate_bus_interfaces -busif cfgs -clock zu9_cci_clk [ipx::current_core]
    ipx::add_bus_parameter FREQ_HZ [ipx::get_bus_interfaces cfgs -of_objects [ipx::current_core]]
    set_property value 150000000 [ipx::get_bus_parameters FREQ_HZ -of_objects [ipx::get_bus_interfaces cfgs -of_objects [ipx::current_core]]]

    ipx::create_xgui_files [ipx::current_core]
    ipx::update_checksums [ipx::current_core]
    ipx::save_core [ipx::current_core]
    set_property  ip_repo_paths  $src_directory [current_project]
    update_ip_catalog

