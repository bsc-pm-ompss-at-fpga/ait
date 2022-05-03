set src_directory /scratch/tomsw/ip_repo_2017/vu9_tb2_100MHz
create_project project_1 /scratch/tomsw/ip_repo_2017/vu9_tb2_100MHz/project_1 -part xcvu9p-fsgd2104-2-i
set_property include_dirs $src_directory/includes [current_fileset]
add_files -scan_for_includes [list $src_directory/rtl/maxilink_4cee5b40df2e1ab19940.v \
$src_directory/rtl/maxilink_ebde39605bc732533412.v \
$src_directory/rtl/maxilink_6bef28d3b95fbe018f31.v \
$src_directory/rtl/maxilink_df3657f6faf20da25873.v \
$src_directory/rtl/maxilink_2d9dd102f1082b2604ca.v \
$src_directory/rtl/maxilink_43d12418bad5930f88f5.v \
$src_directory/rtl/maxilink_110ca66136cc9628c1e8.v \
$src_directory/rtl/maxilink_4b4a2491b91d6b47c6e8.v \
$src_directory/rtl/maxilink_40b329ac816fc6e80504.v \
$src_directory/rtl/maxilink_dee430a3c85c21b1fd98.v \
$src_directory/rtl/maxilink_28ad256e0ec8bf47e440.v \
$src_directory/rtl/maxilink_5d0ef9d50fd086bdd262.v \
$src_directory/rtl/maxilink_b4e5c0ae7fadd385bac7.v \
$src_directory/rtl/maxilink_c5d3cc94a60402977478.v \
$src_directory/rtl/maxilink_85318786d874d2ebe7ec.v \
$src_directory/rtl/maxilink_c7143e092ca0f5dcd20e.v \
$src_directory/rtl/maxilink_0024487f93c45cc69b9a.v \
$src_directory/rtl/maxilink_09590a866d939c9ee552.v \
$src_directory/rtl/maxilink_da2ea8be887cd27627e1.v \
$src_directory/rtl/maxilink_82bed70a5611a2ff00dd.v \
$src_directory/rtl/maxilink_b498b26cb5fc5ce86421.v \
$src_directory/rtl/maxilink_09788cc7b7ad84634e3e.v \
$src_directory/rtl/maxilink_f1fa0d22ff39e33f0dd1.v \
$src_directory/rtl/maxilink_bf429bbbd4df2fffacf3.v \
$src_directory/rtl/maxilink_db7a8c62457a7f203f26.v \
$src_directory/rtl/maxilink_d5d4d9f0d5078a4e5ed0.v \
$src_directory/rtl/maxilink_9ede58bb28a127708127.v \
$src_directory/rtl/maxilink_f4a758e5ba2817ad2901.v \
$src_directory/rtl/maxilink_3a00951cc6cadcf6e778.v \
$src_directory/rtl/maxilink_ec5fd847f9dcea0585a7.v \
$src_directory/rtl/maxilink_3f42627a90b1b48281fb.v \
$src_directory/rtl/maxilink_f3a60ab91e6372ff20aa.v \
$src_directory/rtl/maxilink_993d367251a90474aba0.v \
$src_directory/rtl/maxilink_88c7ea3d410366391f47.v \
$src_directory/rtl/maxilink_c8a9b19f824c7372583c.v \
]
source ${src_directory}/tcl/maxilink_4dbad74feee7e20d9ae1.tcl
source ${src_directory}/tcl/maxilink_2782d7909c041972fa7f.tcl
source ${src_directory}/tcl/maxilink_6c8af97e40e95b8f0d34.tcl
add_files -fileset constrs_1 -norecurse [list ${src_directory}/constraints/maxilink_xilinx_axi_hsl_with_phy_ooc_crdb_tb2_vu9_100MHz.xdc ${src_directory}/constraints/maxilink_xilinx_axi_hsl_with_phy_crdb_tb2_vu9_100MHz.xdc ]
set_property USED_IN {synthesis implementation out_of_context} [get_files ${src_directory}/constraints/maxilink_xilinx_axi_hsl_with_phy_ooc_crdb_tb2_vu9_100MHz.xdc]
set_property PROCESSING_ORDER {LATE} [get_files ${src_directory}/constraints/maxilink_xilinx_axi_hsl_with_phy_crdb_tb2_vu9_100MHz.xdc]
set_property top maxilink_xilinx_axi_hsl_with_phy_crdb_tb2_vu9_100MHz [current_fileset]
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_4cee5b40df2e1ab19940.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_ebde39605bc732533412.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_6bef28d3b95fbe018f31.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_df3657f6faf20da25873.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_2d9dd102f1082b2604ca.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_43d12418bad5930f88f5.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_110ca66136cc9628c1e8.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_4b4a2491b91d6b47c6e8.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_40b329ac816fc6e80504.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_dee430a3c85c21b1fd98.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_28ad256e0ec8bf47e440.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_5d0ef9d50fd086bdd262.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_b4e5c0ae7fadd385bac7.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_c5d3cc94a60402977478.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_85318786d874d2ebe7ec.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_c7143e092ca0f5dcd20e.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_0024487f93c45cc69b9a.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_09590a866d939c9ee552.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_da2ea8be887cd27627e1.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_82bed70a5611a2ff00dd.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_b498b26cb5fc5ce86421.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_09788cc7b7ad84634e3e.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_f1fa0d22ff39e33f0dd1.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_bf429bbbd4df2fffacf3.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_db7a8c62457a7f203f26.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_d5d4d9f0d5078a4e5ed0.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_9ede58bb28a127708127.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_f4a758e5ba2817ad2901.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_3a00951cc6cadcf6e778.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_ec5fd847f9dcea0585a7.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_3f42627a90b1b48281fb.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_f3a60ab91e6372ff20aa.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_993d367251a90474aba0.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_88c7ea3d410366391f47.v
encrypt -key /scratch/tomsw/maxilink_hss_multiplexer/xilinx_2016_05.v -lang ver $src_directory/rtl/maxilink_c8a9b19f824c7372583c.v
source ${src_directory}/tcl/maxilink_xilinx_axi_hsl_with_phy_crdb_tb2_vu9_100MHz_ip_generate.tcl
