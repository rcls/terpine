
create_clock -period 10 [get_nets sys_clk_i_0]
create_clock -period 40.000 [get_nets fifo_clk]
set_switching_activity -default_toggle_rate 40.000

set_property LOC RAMB36_X0Y27 [get_cells b1/fifo]
set_property LOC RAMB36_X2Y27 [get_cells b2/fifo]

set_property LOC RAMB36_X0Y21 [get_cells b3/fifo]
set_property LOC RAMB36_X2Y21 [get_cells b4/fifo]

set_property LOC RAMB36_X0Y13 [get_cells b5/fifo]
set_property LOC RAMB36_X2Y13 [get_cells b6/fifo]

set_property LOC RAMB36_X0Y32 [get_cells b7/fifo]
set_property LOC RAMB36_X2Y35 [get_cells b8/fifo]
set_property LOC RAMB36_X0Y38 [get_cells b9/fifo]

set_property LOC RAMB36_X0Y6 [get_cells b11/fifo]
set_property LOC RAMB36_X0Y1 [get_cells b10/fifo]
set_property LOC RAMB36_X2Y4 [get_cells b12/fifo]

set_property IOSTANDARD SSTL15 [get_ports sys_clk_i_0]
set_property PACKAGE_PIN F4 [get_ports sys_clk_i_0]
