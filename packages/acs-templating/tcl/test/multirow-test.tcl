# used in multirow-procs.tcl

template::multirow create test f1 f2 f3
template::multirow append test I 1 a
template::multirow append test I 1 b
template::multirow append test I 1 c

if { $second_level_stays_p } {
    # the mode that fails - change in level f1 and f3
    multirow append test I 2 a
    multirow append test I 1 a

} else {
    # a mode that works, for testing the test case
    template::multirow append test I 3 a
    template::multirow append test I 2 b
}

template::multirow append test II 1 a
template::multirow append test II 1 b
template::multirow append test II 2 a
template::multirow append test II 2 b

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
