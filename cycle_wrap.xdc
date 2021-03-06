
create_clock -period 2.500 -waveform {0.000 1.250} [get_nets clk]

create_pblock pblock_cycle
add_cells_to_pblock [get_pblocks pblock_cycle] [get_cells -quiet [list cycle]]
resize_pblock [get_pblocks pblock_cycle] -add {SLICE_X28Y91:SLICE_X31Y98}
#resize_pblock [get_pblocks pblock_cycle] -add {SLICE_X32Y90:SLICE_X35Y98}
resize_pblock [get_pblocks pblock_cycle] -add {SLICE_X32Y91:SLICE_X35Y98}
#set_property EXCLUDE_PLACEMENT 1 [get_pblocks pblock_cycle]

create_pblock pblock_cycle_W
add_cells_to_pblock [get_pblocks pblock_cycle_W] [get_cells cycle/W*]
resize_pblock [get_pblocks pblock_cycle_W] -add {SLICE_X28Y91:SLICE_X31Y98}

create_pblock pblock_cycle_CD
add_cells_to_pblock [get_pblocks pblock_cycle_CD] [get_cells cycle/C2*]
add_cells_to_pblock [get_pblocks pblock_cycle_CD] [get_cells cycle/D2*]
#resize_pblock [get_pblocks pblock_cycle_CD] -add {SLICE_X32Y90:SLICE_X33Y98}
resize_pblock [get_pblocks pblock_cycle_CD] -add {SLICE_X30Y91:SLICE_X33Y98}
resize_pblock [get_pblocks pblock_cycle_CD] -add {SLICE_X34Y94:SLICE_X35Y98}

create_pblock pblock_QQ
add_cells_to_pblock [get_pblocks pblock_QQ] [get_cells QQ_reg*]
resize_pblock [get_pblocks pblock_QQ] -add {SLICE_X38Y91:SLICE_X41Y98}

create_pblock pblock_DD
add_cells_to_pblock [get_pblocks pblock_DD] [get_cells DD_reg*]
add_cells_to_pblock [get_pblocks pblock_DD] [get_cells Din_reg*]
resize_pblock [get_pblocks pblock_DD] -add {SLICE_X28Y86:SLICE_X37Y89}

set_property PARENT pblock_cycle [get_pblocks pblock_cycle_*]
