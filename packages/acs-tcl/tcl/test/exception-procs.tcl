ad_library {

    Test for api in tcl/exception-procs.tcl

}

aa_register_case \
    -cats {api smoke production_safe} \
    -procs {
        ad_raise
        ad_exception
    } \
    ad_raise_exception {
        Test the behavior of ad_raise and ad_exception
    } {
        try {
            ad_raise "I am ad_ded" 42
        } on error {e} {
            aa_equals "ad_exception returns expected" \
                [ad_exception $::errorCode] "I am ad_ded"
        }
        try {
            error "I am normal ded"
        } on error {e} {
            aa_equals "ad_exception returns expected" \
                [ad_exception $::errorCode] ""
        }
    }
