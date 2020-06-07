proc slice {X Y} {
    return SLICE_X${X}Y${Y}
}

#set laguna_cols {111 124 139 152 164 182 19 194 214 225 37 50 63 8 85 97}
set laguna_cols [lsort {8 19 33 47 62 78 90 104 119 135 150 161}]

proc not_laguna {X} {
    variable laguna_cols
    return [expr [lsearch -sorted $laguna_cols $X] < 0]
}

set slicem_cols {}
for {set X 0} {$X <= 168} {incr X} {
    set T [get_property SITE_TYPE [get_sites SLICE_X${X}Y150]]
    if {$T eq "SLICEM"} {
        lappend slicem_cols $X
    }
}
set slicem_cols [lsort $slicem_cols]

proc is_slicem {X} {
    variable slicem_cols
    return [expr [lsearch -sorted $slicem_cols $X] >= 0]
}

proc cycle {P X Y} {
    set SIX {}
    for {set C $X} {[llength $SIX] < 6} {incr C} {
        if [not_laguna $C] {
            lappend SIX $C
        }
    }
    #puts $SIX

    # Select which columns to avoid.  Find the leftmost and rightmost SLICEMs.
    # Maybe we should try and avoid both at edges?
    set LEFT {}
    set RIGHT {}
    foreach C $SIX {
        if [is_slicem $C] {
            set RIGHT $C
            if {$LEFT eq ""} {set LEFT $C}
        }
    }
    set USE {}
    foreach C $SIX {
        if {$C ne $LEFT && $C ne $RIGHT} {
            lappend USE $C
        }
    }
    #puts $USE
    foreach R {A I1 I2 I3} C [lrange $USE 0 3] {
        foreach I {0 1 2 3} {
            set J [expr $I * 8 + 7]
            set YY [expr $I + $Y]
            set_property LOC [slice $C $YY] [get_cells $P/${R}_reg[$J]_i_1]
        }
    }
}

proc square {P X1 X2 Y} {
    cycle $P/cA $X1 $Y
    cycle $P/cB $X2 $Y
    cycle $P/cC $X1 [expr $Y + 5]
    cycle $P/cD $X2 [expr $Y + 5]
}

proc squaresquare {P X1 X2 X3 X4 Y} {
    square $P/qA $X1 $X2 $Y
    square $P/qB $X3 $X4 $Y
    square $P/qC $X1 $X2 [expr $Y + 10]
    square $P/qD $X3 $X4 [expr $Y + 10]
}

proc nonet {P Q B X1 X2 X3 X4 X5 X6 Y} {
    square $P/qA $X1 $X2 [expr $Y +  1]
    square $P/qB $X1 $X2 [expr $Y + 11]
    square $P/qC $X1 $X2 [expr $Y + 21]
    square $P/qD $X3 $X4 [expr $Y + 21]
    set PF [expr $Y / 5 + 3]
    set_property LOC RAMB36_X${B}Y${PF} [get_cells $P/fifo/fifo]

    square $Q/qA $X5 $X6 [expr $Y + 21]
    square $Q/qB $X5 $X6 [expr $Y + 11]
    square $Q/qC $X5 $X6 [expr $Y +  1]
    square $Q/qD $X3 $X4 [expr $Y +  1]
    set QF [expr $Y / 5 + 2]
    set_property LOC RAMB36_X${B}Y${QF} [get_cells $Q/fifo/fifo]

    set PB [expr $Y / 300]
    #add_cells_to_pblock [get_pblock pblock_$PB] [get_cells $P] [get_cells $Q]
    #add_cells_to_pblock [get_pblock pblock_$PB] [get_cells $P] [get_cells $Q]
    set_property USER_SLR_ASSIGNMENT SLR$PB [get_cells $P] [get_cells $Q]
}

set P 0

proc supercolumn {B X1 X2 X3 X4 X5 X6 XR} {
    global P
    for {set I 0} {$I < 30} {incr I} {
        if {$I % 10 == 0 || $I == 11} {
            continue
        }
        if {$X1 > 120 && $I >= 10 && $I < 20} {
            continue
        }
        set pb [create_pblock pblock_$P]
        set PP b\[$P\].b
        incr P
        set QQ b\[$P\].b
        incr P
        set Y [expr $I * 30]
        set_property IS_SOFT TRUE $pb
        resize_pblock $pb -add "SLICE_X${X1}Y$Y:SLICE_X${XR}Y[expr $Y+29]"
        add_cells_to_pblock $pb [get_cells $PP] [get_cells $QQ]
        nonet $PP $QQ $B $X1 $X2 $X3 $X4 $X5 $X6 $Y
    }
}

supercolumn 1   0   6  13  20  26  32   40
supercolumn 4  41  48  55  61  68  74   81
supercolumn 7  82  88  95 101 112 118  124
supercolumn 9 125 131 139 146 154 162  168

set_param drc.disableLUTOverUtilError 1
