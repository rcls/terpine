# -*- tcl -*-

create_clock -period 20.000 [get_nets rmii_CLK_pad]
set_switching_activity -default_toggle_rate 40.000

