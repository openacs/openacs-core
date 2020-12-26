ad_library {
    automated-testing for memoizing procs

    @author Adrian Catalan (ykro@galileo.edu)
    @creation-date 2006-07-28
}

namespace eval memoizing_procs_test {}

ad_proc -private memoizing_procs_test::return_string {
    {-name:required}
} {
    Test proc that returns a string
} {
    set response "This is a test for "
    append response $name
    return $response
}

ad_proc -private memoizing_procs_test::return_upper_case_text {
    {-txt:required}
} {
    Test proc that returns a string in uppercase
} {
    set response $txt
    append response " in uppercase is "
    append response [string toupper $txt]
    return $response
}

aa_register_case \
    -cats {api smoke} \
    -procs {util_memoize util_memoize_cached_p} \
    util_memoize_cache {
    Test caching of a cmd call
} {
    aa_log "caching a cmd call"
    util_memoize {memoizing_procs_test::return_string -name "foobar"}
    aa_log "checking if the proc is cached"
    set success_p [util_memoize_cached_p {memoizing_procs_test::return_string -name "foobar"}]

    aa_equals "cmd call was cached successful" $success_p 1
}

aa_register_case \
    -cats {api smoke} \
    -bugs {3448} \
    -procs {util_memoize util_memoize_cached_p} \
    util_memoize_cache_script {
        Test passing a script to util_memoize.
    } {
        aa_log "caching a script"
        set script {
            set x 1
            set y 2
            expr {$x + $y}
        }
        set r [util_memoize $script]
        aa_equals "the script was executed successfully via util_memoize" $r 3

        set success_p [util_memoize_cached_p $script]
        aa_equals "the script is recognized as being cached" $success_p 1
    }


aa_register_case \
    -cats {api smoke} \
    -procs {util_memoize util_memoize_cached_p util_memoize_flush_regexp} \
    util_memoize_cache_flush {
    Test flush of a proc cached
} {
    aa_log "caching"
    util_memoize {memoizing_procs_test::return_string -name "foobar"}
    aa_log "checking if the proc is cached"
    aa_log "flushing"
    util_memoize_flush_regexp {return_upper_case_text}
    set success_p [util_memoize_cached_p {memoizing_procs_test::return_upper_case_text -txt "foobar"}]
    aa_equals "proc was flushed successful" $success_p 0
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
