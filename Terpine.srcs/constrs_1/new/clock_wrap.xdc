set_property BEL CARRY4 [get_cells cycle/_carry]
set_property LOC SLICE_X32Y91 [get_cells cycle/_carry]
set_property BEL CARRY4 [get_cells cycle/__89_carry]
set_property LOC SLICE_X33Y91 [get_cells cycle/__89_carry]
set_property BEL CARRY4 [get_cells cycle/__183_carry]
set_property LOC SLICE_X34Y91 [get_cells cycle/__183_carry]
set_property BEL CARRY4 [get_cells cycle/__277_carry]
set_property LOC SLICE_X35Y91 [get_cells cycle/__277_carry]


create_clock -period 2.500 -waveform {0.000 1.250} [get_nets clk]

create_pblock pblock_cycle
add_cells_to_pblock [get_pblocks pblock_cycle] [get_cells -quiet [list cycle]]
resize_pblock [get_pblocks pblock_cycle] -add {SLICE_X28Y90:SLICE_X35Y98}









