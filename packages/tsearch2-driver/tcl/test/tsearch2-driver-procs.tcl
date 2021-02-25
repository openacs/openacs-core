ad_library {

    Tests for tsearch2-driver

    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-03-07
    @cvs-id $Id$
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    tsearch2::build_query
} build_query {
    build_query test
} {
    aa_run_with_teardown -test_code {
        # some tests to see if we can turn the english query into
        # something tsearch2 to_tsquery can handle

        set q "openacs test automated"
        set query [tsearch2::build_query -query $q]
        aa_true "Multiple terms automatic AND '$query'" \
            {"openacs & test & automated" eq $query}

        set q "openacs test not automated"
        set query [tsearch2::build_query -query $q]
        aa_true "Multiple terms automatic AND, explicit NOT '$query'" \
            {"openacs & test & ! automated" eq $query}

        set q "openacs test or automated"
        set query [tsearch2::build_query -query $q]
        aa_true "Multiple terms automatic AND, explicit OR '$query'" \
            {"openacs & test | automated" eq $query}

        set q "(openacs test) or automated"
        set query [tsearch2::build_query -query $q]
        aa_true "Multiple terms grouped '$query'" \
            {"(openacs & test) | automated" eq $query}

        set q "(openacs or test) automated"
        set query [tsearch2::build_query -query $q]
        aa_true "Multiple terms grouped automatic AND '$query'" \
            {"(openacs | test) & automated" eq $query}

        set q "one a two"
        set query [tsearch2::build_query -query $q]
        aa_true "Single letter elements '$query'" \
            {"one & a & two" eq $query}

        set q "or else"
        set query [tsearch2::build_query -query $q]
        aa_true "Or at beginning by itself '$query'" \
            {"else" eq $query}

        set q "not"
        set query [tsearch2::build_query -query $q]
        aa_true "Not all alone '$query'" \
            {"" eq $query}

        set q "openacs and"
        set query [tsearch2::build_query -query $q]
        aa_true "AND at the end of the query '$query'" \
            {"openacs & and" eq $query}

        set q "openacs or"
        set query [tsearch2::build_query -query $q]
        aa_true "OR at the end of the query '$query'" \
            {"openacs & or" eq $query}

        set q "openacs and or"
        set query [tsearch2::build_query -query $q]
        aa_true "AND and OR at the end of the query '$query'" \
            {"openacs & or" eq $query}

    }
}

aa_register_case -cats {
    api
    production_safe
} -procs {
    tsearch2::driver_info
} driver_info {
    Trivial test for driver_info
} {
    set expected_driver_info [list package_key tsearch2-driver \
                                   version 2 \
                                   automatic_and_queries_p 0 \
                                   stopwords_p 1]
    aa_equals "Driver info" [tsearch2::driver_info] $expected_driver_info
}

aa_register_case -cats {
    api
    production_safe
    smoke
} -procs {
    tsearch2::summary
} summary {
    Test tsearch2::summary
} {
    set query bold
    set txt "wow, this is bold"
    set expected "wow, this is <b>bold</b>"
    aa_equals "Summary" [tsearch2::summary $query $txt] $expected
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
