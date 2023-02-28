ad_library {
    Tcl helper procedures for the acs-automated-testing tests of
    the widget procs on the acs-tcl package.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-06-26
}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs ad_integer_optionlist \
    ad_integer_optionlist {

        Test the ad_integer_optionlist proc

    } {
        set result [ad_integer_optionlist 1 4 8]
        aa_true "Result is expected" \
            [regexp \
                 {^\s*<option value="1">1</option>\s*<option value="2">2</option>\s*<option value="3">3</option>\s*<option value="4">4</option>\s*$} \
                 $result]

        set result [ad_integer_optionlist 1 4 bogus]
        aa_true "Result is expected" \
            [regexp \
                 {^\s*<option value="1">1</option>\s*<option value="2">2</option>\s*<option value="3">3</option>\s*<option value="4">4</option>\s*$} \
                 $result]

        set result [ad_integer_optionlist 1 4 1]
        aa_true "Result is expected" \
            [regexp \
                 {^\s*<option selected="selected" value="1">1</option>\s*<option value="2">2</option>\s*<option value="3">3</option>\s*<option value="4">4</option>\s*$} \
                 $result]

        set result [ad_integer_optionlist 1 4 1 f]
        aa_true "Result is expected" \
            [regexp \
                 {^\s*<option selected="selected" value="1">1</option>\s*<option value="2">2</option>\s*<option value="3">3</option>\s*<option value="4">4</option>\s*$} \
                 $result]

        set result [ad_integer_optionlist 1 4 1 t]
        aa_true "Result is expected" \
            [regexp \
                 {^\s*<option selected="selected" value="01">01</option>\s*<option value="02">02</option>\s*<option value="03">03</option>\s*<option value="04">04</option>\s*$} \
                 $result]
    }


aa_register_case \
    -cats {api smoke production_safe} \
    -procs ad_color_to_hex \
    ad_color_to_hex {

        Test the ad_color_to_hex proc

        @author Hanifa Hasan
} {
    set colors { 0,0,0 #000000 255,255,255 #ffffff 218,18,26 #da121a 252,221,9 #fcdd09 99,11,87 #630b57 }
    dict for { color hex } $colors {
        aa_equals "ad_color_to_hex $color return $hex " "$hex" "[ad_color_to_hex $color]"
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    ad_future_years_list
} ad_future_years_list {
    Test the ad_future_years_list proc.
} {
    set future_years 25
    set this_year [ns_fmttime [ns_time] %Y]
    set next_years [ad_future_years_list $future_years]
    set index 0
    foreach year $next_years {
        aa_equals "Next year" $year [expr {$this_year + $index}]
        incr index
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    ad_generic_optionlist
} ad_generic_optionlist {
    Test the ad_generic_optionlist proc.
} {
    set items {a b c}
    set values {1 2 3}
    set default 3

    set options [ad_generic_optionlist $items $values $default]

    aa_true "Options are expected" \
        [regexp {^<option value="1">a</option>\s+<option value="2">b</option>\s+<option selected="selected" value="3">c</option>\s+$} $options]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
