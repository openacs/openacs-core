ad_library {

    Tests for adp parsing

    @author Gustaf Neumann
    @creation-date 2018-03-09
}

aa_register_case \
    -cats {api} \
    -procs {
        template::head::flush_link
        template::head::flush_script
        template::head::included_p
        template::head::includes
    } \
    head_includes {
    simple test head includes test cases
} {

    #
    # Define two containers, both with two elements
    #
    template::head::includes -container a -parts {b c}
    template::head::includes -container e -parts {f g}

    aa_equals "is 'a' already included" [template::head::included_p a] 0
    aa_equals "is 'b' already included" [template::head::included_p b] 1

    #
    # Flush one container via flush_link; the contained elements
    # should be flushed as well.
    #
    template::head::flush_link -href a -rel stylesheet

    aa_equals "is 'a' already included" [template::head::included_p a] 0
    aa_equals "is 'b' already included" [template::head::included_p b] 0

    aa_equals "is 'e' already included" [template::head::included_p e] 0
    aa_equals "is 'f' already included" [template::head::included_p f] 1

    #
    # Flush the second container via flush_script; the contained
    # elements should be flushed as well.
    #
    template::head::flush_script -src e

    aa_equals "is 'e' already included" [template::head::included_p e] 0
    aa_equals "is 'f' already included" [template::head::included_p f] 0
}

aa_register_case \
    -cats {api} \
    -procs {
        template::register_urn
        template::head::can_resolve_urn
    } \
    urn_api {
        Test the URN api
    } {
        try {
            set urn test_urn

            aa_section "Absolute URL"
            set resource http://testresource

            aa_false "Resource '$resource' cannot be found" \
                [template::head::can_resolve_urn $urn]

            aa_log "Register '$resource'"
            template::register_urn \
                -urn $urn \
                -resource $resource \
                -csp_list {a b c}

            aa_true "Resource '$resource' can be found" \
                [template::head::can_resolve_urn $urn]
            aa_equals "CSP list is expected" \
                $::template::head::urn_csp($urn) {a b c}


            aa_section "Local URL"

            set resource testresource

            aa_log "Register '$resource'"
            template::register_urn \
                -urn $urn \
                -resource $resource \
                -csp_list {c d e}

            aa_equals "CSP list was changed" \
                $::template::head::urn_csp($urn) {c d e}


            aa_section "Another Local URL (Ignored)"

            set resource anything

            aa_log "Register '$resource'"

            template::register_urn \
                -urn $urn \
                -resource $resource \
                -csp_list {f g h}

            aa_equals "URN was NOT changed" \
                $::template::head::urn($urn) testresource

            aa_equals "CSP list was NOT changed" \
                $::template::head::urn_csp($urn) {c d e}


        } finally {
            unset -nocomplain ::template::head::urn_csp($urn)
            unset -nocomplain ::template::head::urn($urn)
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
