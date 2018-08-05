
create_clock -period 2.500 -waveform {0.000 1.250} [get_nets clk]

create_pblock pblock_cycle
add_cells_to_pblock [get_pblocks pblock_cycle] [get_cells -quiet [list cycle]]
resize_pblock [get_pblocks pblock_cycle] -add {SLICE_X28Y90:SLICE_X35Y98}
set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_cycle]

create_pblock pblock_cycle_W
add_cells_to_pblock [get_pblocks pblock_cycle_W] [get_cells cycle/W*]
resize_pblock [get_pblocks pblock_cycle_W] -add {SLICE_X28Y90:SLICE_X31Y98}

#set_property BEL D5FF [get_cells {cycle/munged_phase2_reg[0]}]
#set_property LOC SLICE_X35Y91 [get_cells {cycle/munged_phase2_reg[0]}]

set_property PARENT pblock_cycle [get_pblocks pblock_cycle_W]

set_property BEL BFF [get_cells {cycle/D2_reg[7]}]
set_property LOC SLICE_X32Y92 [get_cells {cycle/D2_reg[7]}]
