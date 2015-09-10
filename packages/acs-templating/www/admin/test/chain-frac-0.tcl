ad_page_contract {
    transform a real number into a chain fraction
} -query {
    x
}

set page ""

append page "<html>
  <body>
    <h2>Chain Fraction</h2>"

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

append page "
    <h3>Natural <var>e</var></h3>
    <p>
      $e =
      $e0 + 1/(
      $e1 + 1/(
      $e2 + 1/(
      $e3 + 1/(
      $e4 + 1/(
      $e5 + 1/(
      $e6 + 1/(
      $e7 + 1/(
      $e8 + 1/(
      $e9 + 1/(
      $e10 + 1/(
      $e11 + 1/(
      $e12 + 1/(
      $e13 + 1/(
      $e14 + 1/(
      $e15 + 1/(
      $e16 + 1/(
      $e17 + 1/(
      $e18 + 1/(
      $e19 + ...
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
    </p>"


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

append page "
    <h3>Golden Ratio</h3>
    <p>
      $g =
      $g0 + 1/(
      $g1 + 1/(
      $g2 + 1/(
      $g3 + 1/(
      $g4 + 1/(
      $g5 + 1/(
      $g6 + 1/(
      $g7 + 1/(
      $g8 + 1/(
      $g9 + 1/(
      $g10 + 1/(
      $g11 + 1/(
      $g12 + 1/(
      $g13 + 1/(
      $g14 + 1/(
      $g15 + 1/(
      $g16 + 1/(
      $g17 + 1/(
      $g18 + 1/(
      $g19 + ...
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
    </p>"

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

append page "
    <h3>Square root of 3</h3>
    <p>
      $r =
      $r0 + 1/(
      $r1 + 1/(
      $r2 + 1/(
      $r3 + 1/(
      $r4 + 1/(
      $r5 + 1/(
      $r6 + 1/(
      $r7 + 1/(
      $r8 + 1/(
      $r9 + 1/(
      $r10 + 1/(
      $r11 + 1/(
      $r12 + 1/(
      $r13 + 1/(
      $r14 + 1/(
      $r15 + 1/(
      $r16 + 1/(
      $r17 + 1/(
      $r18 + 1/(
      $r19 + ...
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
    </p>"

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

append page "
    <h3>Your <var>x</var></h3>
    <p>
      $x =
      $n0 + 1/(
      $n1 + 1/(
      $n2 + 1/(
      $n3 + 1/(
      $n4 + 1/(
      $n5 + 1/(
      $n6 + 1/(
      $n7 + 1/(
      $n8 + 1/(
      $n9 + 1/(
      $n10 + 1/(
      $n11 + 1/(
      $n12 + 1/(
      $n13 + 1/(
      $n14 + 1/(
      $n15 + 1/(
      $n16 + 1/(
      $n17 + 1/(
      $n18 + 1/(
      $n19 + ...
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
      )
    </p>
  </body>
</html>
"

doc_return 200 text/html $page

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
