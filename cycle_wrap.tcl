proc carry4of {pin} {
    set nets [get_nets -of_objects [get_pins $pin]]
    return [get_cells -filter { REF_NAME == CARRY4 } -of_objects $nets]
}

set_property LOC SLICE_X31Y91 [carry4of {cycle/I3_reg[0]/D}]
set_property LOC SLICE_X33Y91 [carry4of {cycle/I2_reg[0]/D}]
set_property LOC SLICE_X34Y91 [carry4of {cycle/I1_reg[0]/D}]
set_property LOC SLICE_X35Y91 [carry4of {cycle/A_reg[0]/D}]
