
create_clock -period 10 [get_nets sys_clk_i_0]
create_clock -period 40.000 [get_nets fifo_clk]
set_switching_activity -default_toggle_rate 40.000
