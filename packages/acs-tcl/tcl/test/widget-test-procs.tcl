ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the widget procs on the acs-tcl package.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-06-26
}


aa_register_case \
    -cats {api smoke production_safe} \
    -procs ad_color_to_hex \
    ad_color_to_hex {

        Test the ad_color_to_hex proc

        @author Hanifa Hasan
} {
    aa_run_with_teardown \
        -rollback \
        -test_code {
            set colors { 0,0,0 #000000 255,255,255 #ffffff 218,18,26 #da121a 252,221,9 #fcdd09 99,11,87 #630b57 }
            dict for { color hex } $colors {
                aa_equals "ad_color_to_hex $color return $hex " "$hex" "[ad_color_to_hex $color]" }
            }
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
