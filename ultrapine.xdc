# -*- tcl -*-

set_property PACKAGE_PIN AM10 [get_ports PCIE_REFCLK_N]
set_property PACKAGE_PIN AM11 [get_ports PCIE_REFCLK_P]

# Goes to sysmon I presume.
#set_property -dict {PACKAGE_PIN BF19 IOSTANDARD LVCMOS18       } [get_ports I2C_MAIN_RESETN   ]; # Bank 64 VCCO - VCC1V8 Net "I2C_MAIN_RESET_B_LS" - IO_L19N_T3L_N1_DBC_AD9N_64
set_property -dict {PACKAGE_PIN BF20 IOSTANDARD LVCMOS18} [get_ports I2C_FPGA_SCL_LS]
set_property -dict {PACKAGE_PIN BF17 IOSTANDARD LVCMOS18} [get_ports I2C_FPGA_SDA_LS]

# Sat. controller UART.
set_property -dict {PACKAGE_PIN BB19 IOSTANDARD LVCMOS18} [get_ports FPGA_TXD_MSP]
set_property -dict {PACKAGE_PIN BA19 IOSTANDARD LVCMOS18} [get_ports FPGA_RXD_MSP]

set_property -dict {PACKAGE_PIN BD21 IOSTANDARD LVCMOS18} [get_ports PCIE_PERST_LS]

# GPIO to sat controller "currently not used"



set_false_path -from [get_clocks -of_objects [get_pins con/PCIe/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -to [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT0]]

#set_property CLOCK_DELAY_GROUP clk_gating [get_nets {clk clk_continuous}]

set_false_path -from [get_clocks -of_objects [get_pins con/PCIe/inst/pcie4_ip_i/inst/gt_top_i/diablo_gt.diablo_gt_phy_wrapper/phy_clk_i/bufg_gt_userclk/O]] -to [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT1]]
set_false_path -from [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT1]] -to [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT0]]
set_false_path -from [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT0]] -to [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT1]]
create_pblock pblock_control
add_cells_to_pblock [get_pblocks pblock_control] [get_cells -quiet [list con/AXI con/CMS con/Clock con/ClockBuffer con/Convert con/PCIe con/proc_sys_reset_0 con/ultracontrol dbg_hub]]
resize_pblock [get_pblocks pblock_control] -add {CLOCKREGION_X5Y5:CLOCKREGION_X5Y9}
set_property IS_SOFT TRUE [get_pblocks pblock_control]

set_max_delay -from [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT0]] 40.000
set_max_delay -from [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT2]] -to [get_clocks -of_objects [get_pins con/Clock/inst/CLK_CORE_DRP_I/clk_inst/mmcme4_adv_inst/CLKOUT1]] 40.000


set_max_delay -to [get_pins clkmux/S0] 20.000
set_max_delay -to [get_pins clkmux/S0] 20.000
set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_1]
