ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case \
    -cats {api smoke} \
    acs_api_browser_trivial_smoke_test {
    Minimal smoke test for acs-api-browser package.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            set result [api_library_documentation packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl]
            aa_true "api documentation proc can document itself" \
                [ string match "*packages/acs-api-browser/tcl/acs-api-documentation-procs.tcl*" $result]
        }
}