proc carry4of {pin} {
    set nets [get_nets -of_objects [get_pins $pin]]
    return [get_cells -filter { REF_NAME == CARRY4 } -of_objects $nets]
}

proc slice {X Y} {
    return SLICE_X${X}Y${Y}
}

proc slices {X Y W H} {
    return SLICE_X${X}Y${Y}:SLICE_X[expr $X+$W-1]Y[expr $Y+$H-1]
}

#set_property LOC SLICE_X31Y91 [carry4of {cycle/I3_reg[0]/D}]
#set_property LOC SLICE_X33Y91 [carry4of {cycle/I2_reg[0]/D}]
#set_property LOC SLICE_X34Y91 [carry4of {cycle/I1_reg[0]/D}]
#set_property LOC SLICE_X35Y91 [carry4of {cycle/A_reg[0]/D}]

proc cycle {P X Y {locs 1}} {
    create_pblock pblock_$P
    set PB [get_pblocks pblock_$P]
    add_cells_to_pblock $PB [get_cells $P]
    set VS 5
    resize_pblock $PB -add [slices $X $Y 8 $VS]
    if {$locs} {
#        set_property LOC [slice [expr $X+3] $Y] [carry4of "$P/I3_reg\[0]/D"]
#        set_property LOC [slice [expr $X+5] $Y] [carry4of "$P/I2_reg\[0]/D"]
#        set_property LOC [slice [expr $X+6] $Y] [carry4of "$P/I1_reg\[0]/D"]
#        set_property LOC [slice [expr $X+7] $Y] [carry4of "$P/A_reg\[0]/D"]
    }
}

proc square {P X1 X2 Y} {
    cycle $P/cA $X1 $Y
    cycle $P/cB $X2 $Y
    cycle $P/cC $X1 [expr $Y + 5]
    cycle $P/cD $X2 [expr $Y + 5]
}

proc squaresquare {P X1 X2 X3 X4 Y1 Y2} {
    square $P/qA $X1 $X2 $Y1
    square $P/qB $X3 $X4 $Y1
    square $P/qC $X1 $X2 $Y2
    square $P/qD $X3 $X4 $Y2
}

proc column {P X Y1 Y2 Y3 Y4 {locs 1}} {
    cycle $P/cA $X $Y1 $locs
    cycle $P/cB $X $Y2 $locs
    cycle $P/cC $X $Y3 $locs
    cycle $P/cD $X $Y4 $locs
}

proc square_of_column {P X1 X2 Y1 Y2 Y3 Y4} {
    set V 5
    column $P/qA $X1 $Y1 [expr $Y1+$V] $Y2 [expr $Y2+$V]
    column $P/qB $X1 $Y3 [expr $Y3+$V] $Y4 [expr $Y4+$V]
    column $P/qC $X2 $Y1 [expr $Y1+$V] $Y2 [expr $Y2+$V]
    column $P/qD $X2 $Y3 [expr $Y3+$V] $Y4 [expr $Y4+$V]
}

square_of_column b1   0  8        140 150 160 170
squaresquare     b2  16 24 33 41  160 170
square_of_column b3        33 41  120 130 140 150
squaresquare     b4   0  8 16 24  120 130


square_of_column b5   0  8         80  90 100 110
squaresquare     b6  16 24 33 41  100 110
square_of_column b7        33 41   60  70  80  90
squaresquare     b8   0  8 16 24   60  70


square_of_column b9   0  8         20  30  40  50
squaresquare     b10 16 24 33 41   40  50
square_of_column b11       33 41    0  10  20  30
squaresquare     b12  0  8 16 24    0  10
