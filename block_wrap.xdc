
create_clock -period 10 [get_nets sys_clk_i_0]
create_clock -period 40.000 [get_nets fifo_clk]
set_switching_activity -default_toggle_rate 40.000

set_property LOC RAMB36_X7Y5  [get_cells b1/fifo/fifo]
set_property LOC RAMB36_X7Y4  [get_cells b2/fifo/fifo]

set_property LOC RAMB36_X7Y45 [get_cells b3/fifo/fifo]
set_property LOC RAMB36_X7Y44 [get_cells b4/fifo/fifo]

set_property LOC RAMB36_X1Y8  [get_cells b5/fifo/fifo]
set_property LOC RAMB36_X1Y41 [get_cells b6/fifo/fifo]

#set_property IOSTANDARD SSTL15 [get_ports sys_clk_i_0]
#set_property PACKAGE_PIN F4 [get_ports sys_clk_i_0]
