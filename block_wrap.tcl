proc slice {X Y} {
    return SLICE_X${X}Y${Y}
}

proc get_slice {X Y} {
    return [get_sites SLICE_X${X}Y${Y}]
}

proc slices {X Y W H} {
    return SLICE_X${X}Y${Y}:SLICE_X[expr $X+$W-1]Y[expr $Y+$H-1]
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
    # Put the bottom quarter of CD where it's needed...
#    foreach I $EIGHT {
#        set L [slice $X4 [expr $I / 4 + $Y]]
#        set_property LOC $L [get_cells $P/C2_reg[$I]]
#        set_property LOC $L [get_cells $P/D2_reg[$I]]
#    }

#    set PG [string replace $P end-1 end-1 g]
#    set_property LOC [slice $X7 $Y] [get_cells $PG/init1_reg]
#    set_property LOC [slice $X5 $Y] [get_cells $PG/munged_phase2_reg*]
}

#set_property BEL A5FF [get_cells b*/q*/g*/init1_reg]
#set_property BEL A5FF [get_cells b*/q*/g*/munged_phase2_reg[0]]
#set_property BEL ABFF [get_cells b*/q*/g*/munged_phase2_reg[1]]

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

nonet b1 b2 114 132 148   0
nonet b3 b4 114 132 148 200

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

for {set i 0} {$i < 32} {incr i 2} {
    set j [expr $i + 1]
    set_property HLUTNM "lut_srl5_$i" [get_cells "b*/q*/c*/W*[$i]_srl5"]
    set_property HLUTNM "lut_srl5_$i" [get_cells "b*/q*/c*/W*[$j]_srl5"]

    set_property HLUTNM "lut_srl6_$i" [get_cells "b*/q*/c*/W*[$i]_srl6"]
    set_property HLUTNM "lut_srl6_$i" [get_cells "b*/q*/c*/W*[$j]_srl6"]
}

set_property IS_ENABLED 0 [get_drc_checks *]

set_property LOC RAMB36_X7Y5 [get_cells b1/fifo/fifo]
set_property LOC RAMB36_X7Y4 [get_cells b2/fifo/fifo]

set_property LOC RAMB36_X7Y45 [get_cells b3/fifo/fifo]
set_property LOC RAMB36_X7Y44 [get_cells b4/fifo/fifo]

set_property LOC RAMB36_X1Y8 [get_cells b5/fifo/fifo]
set_property LOC RAMB36_X1Y41 [get_cells b6/fifo/fifo]
