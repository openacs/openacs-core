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

    aa_equals "is a already included" [template::head::included_p a] 0
    aa_equals "is b already included" [template::head::included_p b] 1

    #
    # Flush one container via flush_link; the contained elements
    # should be flushed as well.
    #
    template::head::flush_link -href a -rel stylesheet

    aa_equals "is a already included" [template::head::included_p a] 0
    aa_equals "is b already included" [template::head::included_p b] 0

    aa_equals "is e already included" [template::head::included_p e] 0
    aa_equals "is f already included" [template::head::included_p f] 1

    #
    # Flush the second container via flush_script; the contained
    # elements should be flushed as well.
    #
    template::head::flush_script -src e

    aa_equals "is e already included" [template::head::included_p e] 0
    aa_equals "is f already included" [template::head::included_p f] 0
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
