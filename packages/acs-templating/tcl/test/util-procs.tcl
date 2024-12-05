ad_library {
    Automated tests for template::util

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
    @cvs-id $Id$
}

aa_register_case -cats {
    api
    smoke
} -procs {
    template::multirow
    template::util::list_to_multirow
    template::util::multirow_to_list
} lists_and_multirows {

    Check conversion back and forth lists and multirows.

} {
    set the_list {
        {one 1 two 2 three 3 four 4 five 5}
        {one 11 two 22 three 33 four 44 five 55}
        {one 111 two 222 three 333 four 444 five 555}
        {one 1111 two 2222 three 3333 four 4444 five 5555}
        {one 11111 two 22222 three 33333 four 44444 five 55555}
    }

    set expected_columns [lsort [list rownum {*}[dict keys [lindex $the_list 0]]]]

    set level \#[::template::adp_level]

    aa_section {List to Multirow}

    ::template::util::list_to_multirow the_multirow $the_list $level

    aa_true "Multirow exists" [template::multirow exists the_multirow]

    aa_equals "[llength $the_list] elements" \
        [template::multirow size the_multirow] [llength $the_list]

    aa_equals "Columns are correct" \
        [lsort [template::multirow columns the_multirow]] $expected_columns


    aa_section {Multirow to List}

    set the_second_list [::template::util::multirow_to_list -level $level the_multirow]

    set i 1
    foreach converted $the_second_list {
        aa_equals "Element $i has the expected dict format" \
            [lsort [dict keys $converted]] $expected_columns
        incr i
    }

    aa_equals "Converted list has the same size" \
        [llength $the_second_list] [llength $the_list]
}

aa_register_case -cats {
    api
    smoke
} -procs {
    template::util::write_file
    template::util::read_file
    template::util::set_file_encoding
} read_write_file {
    Test utilities to read/write files.
} {
    set tmpfile [ns_config ns/parameters tmpdir]/__test_acs_templating_read_write_file.txt

    foreach v {
        avalue
        anötervalue
        1234
        &scene
    } {
        template::util::write_file $tmpfile $v
        aa_equals "In/out from file returns the same" \
            [template::util::read_file $tmpfile] $v
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::get_opts
} get_opts {
    Test template::util::get_opts

    This test exposes a documented behavior that might not be obvious
    to the user: when an argument is specified with its value, and the
    latter is something starting with a "-" sign, the argument will be
    treated as a flag and its value set to 1.
} {
    set testcases {
        {-datatype integer -widget hidden -value 0}
        {widget hidden datatype integer value 0}

        {-widget submit -label {       OK       } -datatype text}
        {datatype text label {       OK       } widget submit}

        {-datatype text -widget textarea -optional -label #acs-subsite.Caption# -value {-test} -html {rows "6" cols "50"}}
        {label "#acs-subsite.Caption#" widget textarea datatype text html {rows "6" cols "50"} value 1 test 1 optional 1}
    }

    foreach {input output} $testcases {
        unset -nocomplain opts
        template::util::get_opts $input

        aa_equals "Array has exactly the keys we expect" [lsort [dict keys $output]] [lsort [array names opts]]
        foreach {key value} $output {
            aa_equals "The value stored for each option is the expected one" $value $opts($key)
        }
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::number_list
} number_list {
    Test template::util::number_list

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    set lists {
        {0 5} {0 1 2 3 4 5}
        {0 0} {0}
        {9 20} {9 10 11 12 13 14 15 16 17 18 19 20}
        {9999999 10000000} {9999999 10000000}
        {1 0} {}
        {-1 1} {-1 0 1}
    }
    dict for {value result} $lists {
        set start_at    [lindex $value 0]
        set last_number [lindex $value 1]
        aa_equals "List from $start_at to $last_number" \
            [template::util::number_list $last_number $start_at] \
            $result
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::get_url_directory
} get_url_directory {
    Test template::util::get_url_directory

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 30 June 2021
} {
    set url_dirs {
        // //
        /test /
        /test/ /test/
        /test/foo/bar /test/foo/
        /test/foo/bar/ /test/foo/bar/
    }
    dict for {url dir} $url_dirs {
        aa_equals "Url: $url, directory: $dir" \
            [template::util::get_url_directory $url] \
            $dir
    }
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::is_nil
} util_is_nil {
    Test template::util::is_nil
} {
    aa_true "'test' is nil?" [template::util::is_nil test]

    set test 1
    aa_false "'test' is nil?" [template::util::is_nil test]

    set test ""
    aa_true "'test' is nil?" [template::util::is_nil test]

    unset test
    array set test {}
    aa_false "'test' is nil?" [template::util::is_nil test]
}

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    template::util::list_to_lookup
} util_list_to_lookup {
    Test template::util::list_to_lookup
} {
    set values {
        a
        b
        c
        d
        e
        f
        g
    }
    template::util::list_to_lookup $values lookup

    set e {![info exists lookup(z)]}
    aa_true "Element 'z' is not found in the lookup" $e

    for {set i 1} {$i <= 7} {incr i} {
        set e {$lookup([lindex $values $i-1]) == $i}
        aa_true "Element '[lindex $values $i-1]' is at position '$i' of the lookup" $e
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
