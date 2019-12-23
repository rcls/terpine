
create_clock -period 10.000 [get_nets sys_clk_i_0]
create_clock -period 40.000 [get_nets fifo_clk]
set_switching_activity -default_toggle_rate 40.000

set_property LOC RAMB36_X3Y31 [get_cells b2/fifo/fifo]
set_property LOC RAMB36_X2Y30 [get_cells b1/fifo/fifo]
set_property LOC RAMB36_X2Y29 [get_cells b4/fifo/fifo]
set_property LOC RAMB36_X3Y29 [get_cells b3/fifo/fifo]
set_property LOC RAMB36_X2Y18 [get_cells b5/fifo/fifo]
set_property LOC RAMB36_X2Y16 [get_cells b8/fifo/fifo]
set_property LOC RAMB36_X3Y17 [get_cells b7/fifo/fifo]
set_property LOC RAMB36_X2Y4 [get_cells b12/fifo/fifo]
set_property LOC RAMB36_X3Y7 [get_cells b10/fifo/fifo]
set_property LOC RAMB36_X3Y5 [get_cells b11/fifo/fifo]
set_property LOC RAMB36_X2Y6 [get_cells b9/fifo/fifo]

set_switching_activity -default_toggle_rate 40.000
