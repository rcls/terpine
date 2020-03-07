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

proc cycle {P X Y {locs 0}} {
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

proc square {P X Y {DX 8}} {
    cycle $P/cA       $X              $Y
    cycle $P/cB [expr $X + $DX]       $Y
    cycle $P/cC       $X        [expr $Y + 8]
    cycle $P/cD [expr $X + $DX] [expr $Y + 8]
}

proc column {P X Y1 Y2 {locs 0}} {
    cycle $P/cA $X       $Y1      $locs
    cycle $P/cB $X [expr $Y1 + 8] $locs
    cycle $P/cC $X       $Y2      $locs
    cycle $P/cD $X [expr $Y2 + 8] $locs
}

proc fullrow {P Q Y FY} {
    square $P/qA   0 $Y
    square $P/qB  16 $Y 20
    square $P/qC  46 $Y
    square $P/qD  66 $Y
    square $Q/qA  84 $Y
    square $Q/qB 108 $Y
    square $Q/qC 124 $Y
    square $Q/qD 148 $Y

    set_property LOC RAMB36_X3Y${FY} [get_cells $P/fifo/fifo]
    set_property LOC RAMB36_X6Y${FY} [get_cells $Q/fifo/fifo]
}

proc nonet {P Q X1 X2 X3 Y} {
    square $P/qA $X1 [expr $Y +  1]
    square $P/qB $X1 [expr $Y + 17]
    square $P/qC $X1 [expr $Y + 34]
    square $P/qD $X2 [expr $Y + 34]

    square $Q/qA $X3 [expr $Y +  1]
    square $Q/qB $X3 [expr $Y + 17]
    square $Q/qC $X3 [expr $Y + 34]
    square $Q/qD $X2 [expr $Y +  1]
}

nonet b1 b2 116 132 148   0
nonet b3 b4 116 132 148 200

column b5/qA   0   1  17
column b5/qB   8   1  17
column b5/qC  16   1  17
square b5/qD   0 34

column b6/qA   0 217 234
column b6/qB   8 217 234
column b6/qC  16 217 234
square b6/qD   0 200

fullrow b7  b8   51 11
fullrow b9  b10  67 14
fullrow b11 b12  84 17

fullrow b13 b14 101 21
fullrow b15 b16 117 24
fullrow b17 b18 134 27

fullrow b19 b20 151 31
fullrow b21 b22 167 34
fullrow b23 b24 184 37
