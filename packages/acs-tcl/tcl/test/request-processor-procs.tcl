ad_library {

    Tests for procs defined in request-processor-procs

}

namespace eval request_processor::test {}

ad_proc -private request_processor::test::a_proc_with_no_args {} {
    A proc with no arguments
} {
    ns_return 200 text/plain OK
}

ad_proc -private request_processor::test::a_proc_with_some_flags {
    {-a_flag DEFAULT1}
    {-another_flag DEFAULT2}
} {
    A proc with two flags
} {
    ns_return 200 text/plain [list \
                                  a_flag $a_flag \
                                  another_flag $another_flag]
}

ad_proc -private request_processor::test::a_proc_with_any_args args {
    A proc with arbitrary args
} {
    ns_return 200 text/plain $args
}

ad_proc -private request_processor::test::a_proc_with_flags_and_args {
    {-a_flag DEFAULT1}
    {-another_flag DEFAULT2}
    args
} {
    A proc with two flags and arbitrary args
} {
    ns_return 200 text/plain [list \
                                  a_flag $a_flag \
                                  another_flag $another_flag \
                                  args $args]
}

ad_proc -private request_processor::test::require_registered_procs {} {
    Requires that the test procs are registered under the test URLs
} {
    set procs [list \
                   request_processor::test::a_proc_with_no_args \
                   request_processor::test::a_proc_with_some_flags \
                   request_processor::test::a_proc_with_any_args \
                   request_processor::test::a_proc_with_flags_and_args]
    # Exit immediately if any of the test procs is already registered.
    if {![nsv_get rp_registered_procs . registered_procs]} {
        set registered_procs [list]
    }
    foreach proc_info $registered_procs {
        set proc_name [lindex $proc_info 2]
        if {$proc_name in $procs} {
            return false
        }
    }

    foreach proc_name $procs {
        switch $proc_name {
            request_processor::test::a_proc_with_no_args {
                set args [list]
            }
            request_processor::test::a_proc_with_some_flags {
                set args [list -a_flag 1 -another_flag 2]
            }
            request_processor::test::a_proc_with_any_args {
                set args [list 1 2 3 4 5]
            }
            request_processor::test::a_proc_with_flags_and_args {
                set args [list -a_flag 1 -another_flag 2 foo bar]
            }
        }
        regsub -all {:} $proc_name {_} path
        ns_log warning "Registered - $path $proc_name {*}$args"
        ad_register_proc * $path $proc_name $args
    }

    set proc_name request_processor::test::a_proc_with_flags_and_args
    regsub -all {:} $proc_name {_} path
    append path __invoked_without_args
    ad_register_proc * $path $proc_name

    set proc_name request_processor::test::a_proc_with_some_flags
    regsub -all {:} $proc_name {_} path
    append path __invoked_without_args
    ad_register_proc * $path $proc_name
}

request_processor::test::require_registered_procs

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_register_proc
    } test_ad_register_proc {
        Test that ad_register_proc works as expected. We do so by
        registering procs with different signatures and then trying to
        poke them with HTTP requests.
    } {
        set expected_values [list \
                                 OK \
                                 [list \
                                      a_flag 1 \
                                      another_flag 2] \
                                 [list \
                                      1 2 3 4 5] \
                                 [list \
                                      a_flag 1 \
                                      another_flag 2 \
                                      args [list foo bar]] \
                                 [list \
                                      a_flag DEFAULT1 \
                                      another_flag DEFAULT2] \
                                 [list \
                                      a_flag DEFAULT1 \
                                      another_flag DEFAULT2 \
                                      args [list]] \
                                ]
        set procs [list \
                       request_processor::test::a_proc_with_no_args \
                       request_processor::test::a_proc_with_some_flags \
                       request_processor::test::a_proc_with_any_args \
                       request_processor::test::a_proc_with_flags_and_args]
        set i 0
        foreach proc_name $procs {
            regsub -all {:} $proc_name {_} path
            set r [util::http::get -url [acs::test::url]/$path]
            aa_equals "Request for '$proc_name' successful" [dict get $r status] 200
            aa_equals "Request for '$proc_name' returns the expected value" \
                [join [dict get $r page]] [join [lindex $expected_values $i]]
            incr i
        }

        set procs_invoked_without_args [list \
                                            request_processor::test::a_proc_with_some_flags \
                                            request_processor::test::a_proc_with_flags_and_args]
        foreach proc_name $procs_invoked_without_args {
            regsub -all {:} $proc_name {_} path
            append path __invoked_without_args
            set r [util::http::get -url [acs::test::url]/$path]
            aa_equals "Request for '$proc_name' invoked without args successful" [dict get $r status] 200
            aa_equals "Request for '$proc_name' invoked without args returns the expected value" \
                [join [dict get $r page]] [join [lindex $expected_values $i]]
            incr i
        }
    }


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
