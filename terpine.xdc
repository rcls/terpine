# -*- tcl -*-

create_clock -period 20.000 [get_nets rmii_CLK_pad]
set_switching_activity -default_toggle_rate 40.000

set_property LOC RAMB36_X2Y4 [get_cells ro/memory_reg]


set_property CFGBVS VCCO [current_design]

set_property DRIVE 4 [get_ports eth_rst]
set_property DRIVE 4 [get_ports {rmii_TX[0]}]
set_property DRIVE 4 [get_ports {rmii_TX[1]}]
set_property DRIVE 4 [get_ports rmii_TX_EN]
set_property PACKAGE_PIN N17 [get_ports eth_rst]
set_property PACKAGE_PIN P14 [get_ports {rmii_TX[0]}]
set_property PACKAGE_PIN P15 [get_ports {rmii_TX[1]}]
set_property PACKAGE_PIN R14 [get_ports rmii_TX_EN]
set_property PACKAGE_PIN N13 [get_ports {rmii_RX[0]}]
set_property PACKAGE_PIN N14 [get_ports {rmii_RX[1]}]
set_property PACKAGE_PIN P20 [get_ports rmii_RX_CRS_DV]
set_property PACKAGE_PIN N15 [get_ports link_led]
set_property IOSTANDARD LVCMOS33 [get_ports eth_rst]
set_property IOSTANDARD LVCMOS33 [get_ports link_led]
set_property IOSTANDARD LVCMOS33 [get_ports rmii_TX_EN]
set_property IOSTANDARD LVCMOS33 [get_ports rmii_RX_CRS_DV]
set_property IOSTANDARD LVCMOS33 [get_ports {rmii_RX[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rmii_RX[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rmii_TX[1]}]
set_property IOSTANDARD LVCMOS33 [get_ports {rmii_TX[0]}]
set_property PULLTYPE PULLUP [get_ports link_led]

set_property PACKAGE_PIN H4 [get_ports sys_diff_clock_clk_p]
set_property PACKAGE_PIN G4 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_diff_clock_clk_n]
set_property IOSTANDARD DIFF_SSTL15 [get_ports sys_diff_clock_clk_p]

set_property CONFIG_VOLTAGE 3.3 [current_design]
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLNONE [current_design]

create_pblock pblock_control
resize_pblock [get_pblocks pblock_control] -add {SLICE_X36Y0:SLICE_X51Y30}
add_cells_to_pblock [get_pblocks pblock_control] \
    [get_cells -hier -filter {NAME =~ con/*}] \
    [get_cells -hier -filter {NAME =~ ro/*}]

set_property BITSTREAM.CONFIG.OVERTEMPPOWERDOWN ENABLE [current_design]
