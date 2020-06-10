# -*- tcl -*-

set_property PACKAGE_PIN AM10 [get_ports PCIE_REFCLK_N]
set_property PACKAGE_PIN AM11 [get_ports PCIE_REFCLK_P]

#  Bank 65 Ultrascale+ Device SYSMON I2C Slave Interface to Satellite Controller to monitor Ultrascale+ Device Temperatures and Voltages.
#    SYSMON_SCL   Slave I2C clock connection from Satellite Controller to Ultrascale+ Device
#    SYSMON_SDA   Slave I2C data connection from Satellite Controller to Ultrascale+ Device
set_property -dict {PACKAGE_PIN AR26 IOSTANDARD LVCMOS12 DRIVE 8 SLEW SLOW} [get_ports SYSMON_SDA]; # Bank 65   - IO_L23N_T3U_N9_PERSTN1_I2C_SDA_65
set_property -dict {PACKAGE_PIN AR25 IOSTANDARD LVCMOS12 DRIVE 8 SLEW SLOW} [get_ports SYSMON_SCL]; # Bank 65   - IO_L23P_T3U_N8_I2C_SCLK_65

# Sat. controller UART.
set_property -dict {PACKAGE_PIN BB19 IOSTANDARD LVCMOS18 DRIVE 4 SLEW SLOW} [get_ports FPGA_TXD_MSP]
set_property -dict {PACKAGE_PIN BA19 IOSTANDARD LVCMOS18} [get_ports FPGA_RXD_MSP]

set_property -dict {PACKAGE_PIN BD21 IOSTANDARD LVCMOS18} [get_ports PCIE_PERST_LS]

# GPIO to sat controller "currently not used"
set_property -dict {PACKAGE_PIN AR20 IOSTANDARD LVCMOS12 DRIVE 4 SLEW SLOW} [get_ports GPIO_MSP[0]]; # Bank 64 VCCO - VCC1V2 Net "GPIO_MSP0"           - IO_T0U_N12_VRP_64
set_property -dict {PACKAGE_PIN AM20 IOSTANDARD LVCMOS12 DRIVE 4 SLEW SLOW} [get_ports GPIO_MSP[1]]; # Bank 64 VCCO - VCC1V2 Net "GPIO_MSP1"           - IO_L6N_T0U_N11_AD6N_64
set_property -dict {PACKAGE_PIN AM21 IOSTANDARD LVCMOS12 DRIVE 4 SLEW SLOW} [get_ports GPIO_MSP[2]]; # Bank 64 VCCO - VCC1V2 Net "GPIO_MSP2"           - IO_L6P_T0U_N10_AD6P_64
set_property -dict {PACKAGE_PIN AN21 IOSTANDARD LVCMOS12 DRIVE 4 SLEW SLOW} [get_ports GPIO_MSP[3]]; # Bank 64 VCCO - VCC1V2 Net "GPIO_MSP3"           - IO_L5N_T0U_N9_AD14N_64


#set_property CLOCK_DELAY_GROUP clk_gating [get_nets {clk clk_continuous}]


set_property C_CLK_INPUT_FREQ_HZ 300000000 [get_debug_cores dbg_hub]
set_property C_ENABLE_CLK_DIVIDER false [get_debug_cores dbg_hub]
set_property C_USER_SCAN_CHAIN 1 [get_debug_cores dbg_hub]
connect_debug_port dbg_hub/clk [get_nets clk_1]
