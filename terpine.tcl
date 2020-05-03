proc slice {X Y} {
    return SLICE_X${X}Y${Y}
}

proc get_slice {X Y} {
    return [get_sites SLICE_X${X}Y${Y}]
}

proc cycle {P X Y} {
#    create_pblock pblock_$P
#    set PB [get_pblocks pblock_$P]
#    add_cells_to_pblock $PB [get_cells -filter {REF_NAME == CARRY4} $P/*]
#    resize_pblock $PB -add [slices $X $Y 8 8]

    foreach C {0 2 4 6} {
        set T$C [get_property SITE_TYPE [get_slice [expr $X + $C] $Y]]
    }
    set EIGHT {0 1 2 3 4 5 6 7}
    set LEFT [expr [string equal SLICEM $T0] && [string equal SLICEM $T4]]
    set RGHT [expr [string equal SLICEM $T2] && [string equal SLICEM $T6]]
    if {!$LEFT && !$RGHT} {error {Not left nor right}}

    if {$LEFT} {
        lassign {7 5 3 2} XA XI1 XI2 XI3
    } else {
        lassign {1 3 4 5} XA XI1 XI2 XI3
    }
    foreach RR {A I1 I2 I3} {
        set XR X$RR
        set XX [expr $X + $$XR]
        foreach I $EIGHT {
            set J [expr $I * 4 + 3]
            set YY [expr $I + $Y]
            set_property LOC [slice $XX $YY] [get_cells $P/${RR}_reg[$J]_i_1]
        }
    }
}

proc square {P X Y {DX 8}} {
    cycle $P/cA       $X              $Y
    cycle $P/cB [expr $X + $DX]       $Y
    cycle $P/cC       $X        [expr $Y + 8]
    cycle $P/cD [expr $X + $DX] [expr $Y + 8]
}

proc column {P X Y1 Y2} {
    cycle $P/cA $X       $Y1
    cycle $P/cB $X [expr $Y1 + 8]
    cycle $P/cC $X       $Y2
    cycle $P/cD $X [expr $Y2 + 8]
}

proc fullrow {P Q Y FY} {
    square $P/qA   0 $Y
    square $P/qB  16 $Y 20
    square $P/qC  44 $Y
    square $P/qD  68 $Y
    square $Q/qA  84 $Y
    square $Q/qB 108 $Y
    square $Q/qC 128 $Y
    square $Q/qD 148 $Y

    set_property LOC RAMB36_X3Y$FY [get_cells $P/fifo/fifo]
    set_property LOC RAMB36_X6Y$FY [get_cells $Q/fifo/fifo]
}

proc nonet {P Q X1 X2 X3 Y} {
    square $P/qA $X1 [expr $Y + 34]
    square $P/qB $X2 [expr $Y + 34]
    square $P/qC $X3 [expr $Y + 34]
    square $P/qD $X3 [expr $Y + 17]

    square $Q/qA $X1 [expr $Y +  1]
    square $Q/qB $X2 [expr $Y +  1]
    square $Q/qC $X3 [expr $Y +  1]
    square $Q/qD $X1 [expr $Y + 17]
}

nonet b[1].b b[2].b 114 132 148   0
nonet b[3].b b[4].b 114 132 148 200

column b[5].b/qA   0   1  17
column b[5].b/qB   8   1  17
column b[5].b/qC  16   1  17
square b[5].b/qD   0 34

column b[6].b/qA   0 217 234
column b[6].b/qB   8 217 234
column b[6].b/qC  16 217 234
square b[6].b/qD   0 201

fullrow b[7].b  b[8].b   51 11
fullrow b[9].b  b[10].b  67 14
fullrow b[11].b b[12].b  84 17

fullrow b[13].b b[14].b 101 21
fullrow b[15].b b[16].b 117 24
fullrow b[17].b b[18].b 134 27

fullrow b[19].b b[20].b 151 31
fullrow b[21].b b[22].b 167 34
fullrow b[23].b b[24].b 184 37

for {set i 0} {$i < 32} {incr i 2} {
    set j [expr $i + 1]
    set_property HLUTNM "lut_srl5_$i" [get_cells "b*/q*/c*/W*[$i]_srl5"]
    set_property HLUTNM "lut_srl5_$i" [get_cells "b*/q*/c*/W*[$j]_srl5"]

    set_property HLUTNM "lut_srl6_$i" [get_cells "b*/q*/c*/W*[$i]_srl6"]
    set_property HLUTNM "lut_srl6_$i" [get_cells "b*/q*/c*/W*[$j]_srl6"]
}

set_property LOC RAMB36_X7Y5 [get_cells b[1].b/fifo/fifo]
set_property LOC RAMB36_X7Y4 [get_cells b[2].b/fifo/fifo]

set_property LOC RAMB36_X7Y45 [get_cells b[3].b/fifo/fifo]
set_property LOC RAMB36_X7Y44 [get_cells b[4].b/fifo/fifo]

set_property LOC RAMB36_X1Y8 [get_cells b[5].b/fifo/fifo]
set_property LOC RAMB36_X1Y41 [get_cells b[6].b/fifo/fifo]


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
