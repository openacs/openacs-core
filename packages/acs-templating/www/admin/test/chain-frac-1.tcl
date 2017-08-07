ad_page_contract {
    transform a real number into a chain fraction
} -properties {
    n0:onevalue
    n1:onevalue
    n2:onevalue
    n3:onevalue
    n4:onevalue
    n5:onevalue
    n6:onevalue
    n7:onevalue
    n8:onevalue
    n9:onevalue
    n10:onevalue
    n11:onevalue
    n12:onevalue
    n13:onevalue
    n14:onevalue
    n15:onevalue
    n16:onevalue
    n17:onevalue
    n18:onevalue
    n19:onevalue
    x:onevalue

    e:onevalue
    e0:onevalue
    e1:onevalue
    e2:onevalue
    e3:onevalue
    e4:onevalue
    e5:onevalue
    e6:onevalue
    e7:onevalue
    e8:onevalue
    e9:onevalue
    e10:onevalue
    e11:onevalue
    e12:onevalue
    e13:onevalue
    e14:onevalue
    e15:onevalue
    e16:onevalue
    e17:onevalue
    e18:onevalue
    e19:onevalue

    g:onevalue
    g0:onevalue
    g1:onevalue
    g2:onevalue
    g3:onevalue
    g4:onevalue
    g5:onevalue
    g6:onevalue
    g7:onevalue
    g8:onevalue
    g9:onevalue
    g10:onevalue
    g11:onevalue
    g12:onevalue
    g13:onevalue
    g14:onevalue
    g15:onevalue
    g16:onevalue
    g17:onevalue
    g18:onevalue
    g19:onevalue

    r:onevalue
    r0:onevalue
    r1:onevalue
    r2:onevalue
    r3:onevalue
    r4:onevalue
    r5:onevalue
    r6:onevalue
    r7:onevalue
    r8:onevalue
    r9:onevalue
    r10:onevalue
    r11:onevalue
    r12:onevalue
    r13:onevalue
    r14:onevalue
    r15:onevalue
    r16:onevalue
    r17:onevalue
    r18:onevalue
    r19:onevalue
} -query {
    x
}


# the user's x

set n0 [expr {int (  $x    ) }];		# keep the integer part in n0
set xf  [expr {1 / ($x - $n0) }];		# invert the fractional part
set n1 [expr {int (  $xf    ) }];		# keep the integer part in n1
set xf  [expr {1 / ($xf - $n1) }];	# invert the fractional part
set n2 [expr {int (  $xf    ) }];		# keep the integer part in n2
set xf  [expr {1 / ($xf - $n2) }];	# invert the fractional part
set n3 [expr {int (  $xf    ) }];		# keep the integer part in n3
set xf  [expr {1 / ($xf - $n3) }];	# invert the fractional part
set n4 [expr {int (  $xf    ) }];		# keep the integer part in n4
set xf  [expr {1 / ($xf - $n4) }];	# invert the fractional part
set n5 [expr {int (  $xf    ) }];		# keep the integer part in n5
set xf  [expr {1 / ($xf - $n5) }];	# invert the fractional part
set n6 [expr {int (  $xf    ) }];		# keep the integer part in n6
set xf  [expr {1 / ($xf - $n6) }];	# invert the fractional part
set n7 [expr {int (  $xf    ) }];		# keep the integer part in n7
set xf  [expr {1 / ($xf - $n7) }];	# invert the fractional part
set n8 [expr {int (  $xf    ) }];		# keep the integer part in n8
set xf  [expr {1 / ($xf - $n8) }];	# invert the fractional part
set n9 [expr {int (  $xf    ) }];		# keep the integer part in n9
set xf  [expr {1 / ($xf - $n9) }];	# invert the fractional part
set n10 [expr {int (  $xf    ) }];	# keep the integer part in n10
set xf  [expr {1 / ($xf - $n10) }];	# invert the fractional part
set n11 [expr {int (  $xf    ) }];	# keep the integer part in n11
set xf  [expr {1 / ($xf - $n11) }];	# invert the fractional part
set n12 [expr {int (  $xf    ) }];	# keep the integer part in n12
set xf  [expr {1 / ($xf - $n12) }];	# invert the fractional part
set n13 [expr {int (  $xf    ) }];	# keep the integer part in n13
set xf  [expr {1 / ($xf - $n13) }];	# invert the fractional part
set n14 [expr {int (  $xf    ) }];	# keep the integer part in n14
set xf  [expr {1 / ($xf - $n14) }];	# invert the fractional part
set n15 [expr {int (  $xf    ) }];	# keep the integer part in n15
set xf  [expr {1 / ($xf - $n15) }];	# invert the fractional part
set n16 [expr {int (  $xf    ) }];	# keep the integer part in n16
set xf  [expr {1 / ($xf - $n16) }];	# invert the fractional part
set n17 [expr {int (  $xf    ) }];	# keep the integer part in n17
set xf  [expr {1 / ($xf - $n17) }];	# invert the fractional part
set n18 [expr {int (  $xf    ) }];	# keep the integer part in n18
set xf  [expr {1 / ($xf - $n18) }];	# invert the fractional part
set n19 [expr {int (  $xf    ) }];	# keep the integer part in n19
set xf  [expr {1 / ($xf - $n19) }];	# invert the fractional part


# e

set e [expr {exp(1)}]

set e0 [expr {int (  $e    ) }];		# keep the integer part in e0
set xf  [expr {1 / ($e - $e0) }];		# invert the fractional part
set e1 [expr {int (  $xf    ) }];		# keep the integer part in e1
set xf  [expr {1 / ($xf - $e1) }];	# invert the fractional part
set e2 [expr {int (  $xf    ) }];		# keep the integer part in e2
set xf  [expr {1 / ($xf - $e2) }];	# invert the fractional part
set e3 [expr {int (  $xf    ) }];		# keep the integer part in e3
set xf  [expr {1 / ($xf - $e3) }];	# invert the fractional part
set e4 [expr {int (  $xf    ) }];		# keep the integer part in e4
set xf  [expr {1 / ($xf - $e4) }];	# invert the fractional part
set e5 [expr {int (  $xf    ) }];		# keep the integer part in e5
set xf  [expr {1 / ($xf - $e5) }];	# invert the fractional part
set e6 [expr {int (  $xf    ) }];		# keep the integer part in e6
set xf  [expr {1 / ($xf - $e6) }];	# invert the fractional part
set e7 [expr {int (  $xf    ) }];		# keep the integer part in e7
set xf  [expr {1 / ($xf - $e7) }];	# invert the fractional part
set e8 [expr {int (  $xf    ) }];		# keep the integer part in e8
set xf  [expr {1 / ($xf - $e8) }];	# invert the fractional part
set e9 [expr {int (  $xf    ) }];		# keep the integer part in e9
set xf  [expr {1 / ($xf - $e9) }];	# invert the fractional part
set e10 [expr {int (  $xf    ) }];	# keep the integer part in e10
set xf  [expr {1 / ($xf - $e10) }];	# invert the fractional part
set e11 [expr {int (  $xf    ) }];	# keep the integer part in e11
set xf  [expr {1 / ($xf - $e11) }];	# invert the fractional part
set e12 [expr {int (  $xf    ) }];	# keep the integer part in e12
set xf  [expr {1 / ($xf - $e12) }];	# invert the fractional part
set e13 [expr {int (  $xf    ) }];	# keep the integer part in e13
set xf  [expr {1 / ($xf - $e13) }];	# invert the fractional part
set e14 [expr {int (  $xf    ) }];	# keep the integer part in e14
set xf  [expr {1 / ($xf - $e14) }];	# invert the fractional part
set e15 [expr {int (  $xf    ) }];	# keep the integer part in e15
set xf  [expr {1 / ($xf - $e15) }];	# invert the fractional part
set e16 [expr {int (  $xf    ) }];	# keep the integer part in e16
set xf  [expr {1 / ($xf - $e16) }];	# invert the fractional part
set e17 [expr {int (  $xf    ) }];	# keep the integer part in e17
set xf  [expr {1 / ($xf - $e17) }];	# invert the fractional part
set e18 [expr {int (  $xf    ) }];	# keep the integer part in e18
set xf  [expr {1 / ($xf - $e18) }];	# invert the fractional part
set e19 [expr {int (  $xf    ) }];	# keep the integer part in e19
set xf  [expr {1 / ($xf - $e19) }];	# invert the fractional part

# golden ratio

set g [expr (sqrt(5)+1)/2]

set g0 [expr {int (  $g    ) }];		# keep the integer part in g0
set xf  [expr {1 / ($g - $g0) }];		# invert the fractional part
set g1 [expr {int (  $xf    ) }];		# keep the integer part in g1
set xf  [expr {1 / ($xf - $g1) }];	# invert the fractional part
set g2 [expr {int (  $xf    ) }];		# keep the integer part in g2
set xf  [expr {1 / ($xf - $g2) }];	# invert the fractional part
set g3 [expr {int (  $xf    ) }];		# keep the integer part in g3
set xf  [expr {1 / ($xf - $g3) }];	# invert the fractional part
set g4 [expr {int (  $xf    ) }];		# keep the integer part in g4
set xf  [expr {1 / ($xf - $g4) }];	# invert the fractional part
set g5 [expr {int (  $xf    ) }];		# keep the integer part in g5
set xf  [expr {1 / ($xf - $g5) }];	# invert the fractional part
set g6 [expr {int (  $xf    ) }];		# keep the integer part in g6
set xf  [expr {1 / ($xf - $g6) }];	# invert the fractional part
set g7 [expr {int (  $xf    ) }];		# keep the integer part in g7
set xf  [expr {1 / ($xf - $g7) }];	# invert the fractional part
set g8 [expr {int (  $xf    ) }];		# keep the integer part in g8
set xf  [expr {1 / ($xf - $g8) }];	# invert the fractional part
set g9 [expr {int (  $xf    ) }];		# keep the integer part in g9
set xf  [expr {1 / ($xf - $g9) }];	# invert the fractional part
set g10 [expr {int (  $xf    ) }];	# keep the integer part in g10
set xf  [expr {1 / ($xf - $g10) }];	# invert the fractional part
set g11 [expr {int (  $xf    ) }];	# keep the integer part in g11
set xf  [expr {1 / ($xf - $g11) }];	# invert the fractional part
set g12 [expr {int (  $xf    ) }];	# keep the integer part in g12
set xf  [expr {1 / ($xf - $g12) }];	# invert the fractional part
set g13 [expr {int (  $xf    ) }];	# keep the integer part in g13
set xf  [expr {1 / ($xf - $g13) }];	# invert the fractional part
set g14 [expr {int (  $xf    ) }];	# keep the integer part in g14
set xf  [expr {1 / ($xf - $g14) }];	# invert the fractional part
set g15 [expr {int (  $xf    ) }];	# keep the integer part in g15
set xf  [expr {1 / ($xf - $g15) }];	# invert the fractional part
set g16 [expr {int (  $xf    ) }];	# keep the integer part in g16
set xf  [expr {1 / ($xf - $g16) }];	# invert the fractional part
set g17 [expr {int (  $xf    ) }];	# keep the integer part in g17
set xf  [expr {1 / ($xf - $g17) }];	# invert the fractional part
set g18 [expr {int (  $xf    ) }];	# keep the integer part in g18
set xf  [expr {1 / ($xf - $g18) }];	# invert the fractional part
set g19 [expr {int (  $xf    ) }];	# keep the integer part in g19
set xf  [expr {1 / ($xf - $g19) }];	# invert the fractional part


# Square root of 3

set r [expr {sqrt(3)}]

set r0 [expr {int (  $r    ) }];		# keep the integer part in r0
set xf  [expr {1 / ($r - $r0) }];		# invert the fractional part
set r1 [expr {int (  $xf    ) }];		# keep the integer part in r1
set xf  [expr {1 / ($xf - $r1) }];	# invert the fractional part
set r2 [expr {int (  $xf    ) }];		# keep the integer part in r2
set xf  [expr {1 / ($xf - $r2) }];	# invert the fractional part
set r3 [expr {int (  $xf    ) }];		# keep the integer part in r3
set xf  [expr {1 / ($xf - $r3) }];	# invert the fractional part
set r4 [expr {int (  $xf    ) }];		# keep the integer part in r4
set xf  [expr {1 / ($xf - $r4) }];	# invert the fractional part
set r5 [expr {int (  $xf    ) }];		# keep the integer part in r5
set xf  [expr {1 / ($xf - $r5) }];	# invert the fractional part
set r6 [expr {int (  $xf    ) }];		# keep the integer part in r6
set xf  [expr {1 / ($xf - $r6) }];	# invert the fractional part
set r7 [expr {int (  $xf    ) }];		# keep the integer part in r7
set xf  [expr {1 / ($xf - $r7) }];	# invert the fractional part
set r8 [expr {int (  $xf    ) }];		# keep the integer part in r8
set xf  [expr {1 / ($xf - $r8) }];	# invert the fractional part
set r9 [expr {int (  $xf    ) }];		# keep the integer part in r9
set xf  [expr {1 / ($xf - $r9) }];	# invert the fractional part
set r10 [expr {int (  $xf    ) }];	# keep the integer part in r10
set xf  [expr {1 / ($xf - $r10) }];	# invert the fractional part
set r11 [expr {int (  $xf    ) }];	# keep the integer part in r11
set xf  [expr {1 / ($xf - $r11) }];	# invert the fractional part
set r12 [expr {int (  $xf    ) }];	# keep the integer part in r12
set xf  [expr {1 / ($xf - $r12) }];	# invert the fractional part
set r13 [expr {int (  $xf    ) }];	# keep the integer part in r13
set xf  [expr {1 / ($xf - $r13) }];	# invert the fractional part
set r14 [expr {int (  $xf    ) }];	# keep the integer part in r14
set xf  [expr {1 / ($xf - $r14) }];	# invert the fractional part
set r15 [expr {int (  $xf    ) }];	# keep the integer part in r15
set xf  [expr {1 / ($xf - $r15) }];	# invert the fractional part
set r16 [expr {int (  $xf    ) }];	# keep the integer part in r16
set xf  [expr {1 / ($xf - $r16) }];	# invert the fractional part
set r17 [expr {int (  $xf    ) }];	# keep the integer part in r17
set xf  [expr {1 / ($xf - $r17) }];	# invert the fractional part
set r18 [expr {int (  $xf    ) }];	# keep the integer part in r18
set xf  [expr {1 / ($xf - $r18) }];	# invert the fractional part
set r19 [expr {int (  $xf    ) }];	# keep the integer part in r19
set xf  [expr {1 / ($xf - $r19) }];	# invert the fractional part

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
