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
    set VS 8
    resize_pblock $PB -add [slices $X $Y 8 $VS]
    set YY [expr $Y + $VS - 8]
    if {$locs} {
        set_property LOC [slice [expr $X+3] $YY] [carry4of "$P/I3_reg\[0]/D"]
        set_property LOC [slice [expr $X+5] $YY] [carry4of "$P/I2_reg\[0]/D"]
        set_property LOC [slice [expr $X+6] $YY] [carry4of "$P/I1_reg\[0]/D"]
        set_property LOC [slice [expr $X+7] $YY] [carry4of "$P/A_reg\[0]/D"]
    }
}

proc square {P X1 X2 Y} {
    cycle $P/cA $X1 $Y
    cycle $P/cB $X2 $Y
    cycle $P/cC $X1 [expr $Y + 8]
    cycle $P/cD $X2 [expr $Y + 8]
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

squaresquare b1  0 28 36 44  117 134
squaresquare b2 52 60 74 82  117 134

squaresquare b3  0 28 36 44   84 101
squaresquare b4 52 60 74 82   84 101

squaresquare b5  0 28 36 44   51  67
squaresquare b6 52 60 74 82   51  67

column b7/qA  0 151 159 167 175
column b7/qB 12 151 159 167 175
column b7/qC 24 151 159 167 175 0
column b7/qD 32 151 159 167 175
column b8/qA 40 151 159 167 175
column b8/qB 48 151 159 167 175
column b8/qC 56 151 159 167 175
column b8/qD 72 151 159 167 175

square b9/qA  0 12 184
square b9/qB 28 36 184
square b9/qC 44 52 184
square b9/qD 60 72 184

square b10/qA  0 12 1
square b10/qB 28 36 1
square b10/qC 44 52 1
square b10/qD 60 72 1

column b11/qA  0 18 26 34 42
column b11/qB 12 18 26 34 42
column b11/qC 24 18 26 34 42 0
column b11/qD 32 18 26 34 42

column b12/qA 40 18 26 34 42
column b12/qB 48 18 26 34 42
column b12/qC 56 18 26 34 42
column b12/qD 72 18 26 34 42
