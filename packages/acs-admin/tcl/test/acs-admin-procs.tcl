ad_library {
    Automated tests.

    @author Joel Aufrecht
    @creation-date 2 Nov 2003
    @cvs-id $Id$
}

aa_register_case acs_admin_trivial_smoke_test {
    Minimal smoke test for acs-admin package.
} {    

    aa_run_with_teardown \
        -rollback \
        -test_code {
            set header_result [apm_header]
            aa_true "apm_header returns a non-null string?" [exists_and_not_null header_result]
        }
}