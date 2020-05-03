proc slice {X Y} {
    return SLICE_X${X}Y${Y}
}

proc slices {X Y W H} {
    return SLICE_X${X}Y${Y}:SLICE_X[expr $X+$W-1]Y[expr $Y+$H-1]
}

set laguna_cols {111 124 139 152 164 182 19 194 214 225 37 50 63 8 85 97}

proc not_laguna {X} {
    variable laguna_cols
    return [expr [lsearch -sorted $laguna_cols $X] < 0]
}

set slicem_cols {}
for {set X 0} {$X <= 232} {incr X} {
    set T [get_property SITE_TYPE [get_sites SLICE_X${X}Y0]]
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
    puts $SIX

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
    puts $USE
    foreach R {A I1 I2 I3} C [lrange $USE 0 3] {
        foreach I {0 1 2 3} {
            set J [expr $I * 8 + 7]
            set YY [expr $I + $Y]
            set_property LOC [slice $C $YY] [get_cells $P/${R}_reg[$J]_i_1]
        }
    }
}

proc square {P X1 X2 Y} {
#    set PB [create_pblock pblock_$P]
#    resize_pblock $PB -add [slices $X1 $Y 12 8]
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

proc supercolumn {P X1 X2 X3 X4} {
    for {set I 0} {$I < 24} {incr I} {
        set PP [expr $P + $I]
        squaresquare b\[$PP].b $X1 $X2 $X3 $X4 [expr $I * 20 + 1]
    }
}

supercolumn   0    0   9  17  25
supercolumn  24   31  38  44  51
supercolumn  48   58  65  72  80
supercolumn  72   86  95 103 109

supercolumn  96  120 127 133 140
supercolumn 120  150 157 163 170
supercolumn 144  180 187 193 200
supercolumn 168  207 213 220 227

set_property IS_ENABLED 0 [get_drc_checks]

set_param drc.disableLUTOverUtilError 1

#squaresquare b[1].b 0 9 17 25 1
#squaresquare b[2].b 0 9 17 25 21
#squaresquare b[3].b 0 9 17 25 41
#squaresquare b[4].b 0 9 17 25 61
#squaresquare b[5].b 0 9 17 25 81
#squaresquare b[6].b 0 9 17 25 101

#squaresquare b[7].b 31 38 44 51 1
#squaresquare b[8].b 31 38 44 51 21
#squaresquare b[9].b 31 38 44 51 41
#squaresquare b[10].b 31 38 44 51 61
#squaresquare b[11].b 31 38 44 51 81
#squaresquare b[12].b 31 38 44 51 101

#squaresquare b[13].b 57 65 72 80 1
#squaresquare b[14].b 57 65 72 80 21
#squaresquare b[15].b 57 65 72 80 41
#squaresquare b[16].b 57 65 72 80 61
#squaresquare b[17].b 57 65 72 80 81
#squaresquare b[18].b 57 65 72 80 101

#squaresquare b[19].b 86 95 103 109 1
#squaresquare b[20].b 86 95 103 109 21
#squaresquare b[21].b 86 95 103 109 41
#squaresquare b[22].b 86 95 103 109 61
#squaresquare b[23].b 86 95 103 109 81
#squaresquare b[24].b 86 95 103 109 101


set_false_path -to [get_pins -filter {REF_PIN_NAME == RST} -of_objects [get_cells -hierarchical -filter {REF_NAME =~ FIFO*}]]

foreach i {0 1} {
    set_false_path \
        -from [get_clocks -of_objects [get_pins pll/CLKOUT6]] \
        -to [get_clocks -of_objects [get_pins pll/CLKOUT$i]]
}

foreach i {0 1} j {1 0} {
    set_false_path \
        -from [get_clocks -of_objects [get_pins pll/CLKOUT$i]] \
        -to [get_clocks -of_objects [get_pins pll/CLKOUT$j]]
}
