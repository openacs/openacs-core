# 

ad_library {
    
    Tests for tsearch2-driver
    
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2005-03-07
    @arch-tag: 17a26a17-9fd6-4ae9-90ae-ce445c020ab7
    @cvs-id $Id$
}

aa_register_case build_query {
    build_query test
} {
    aa_run_with_teardown \
        -test_code {
            # some tests to see if we can turn the english query into
            # something tsearch2 to_tsquery can handle

            set q "openacs test automated"
            aa_true "Multiple terms automatic AND '[tsearch2::build_query -query $q]'" \
                [string equal "openacs & test & automated" \
                     [tsearch2::build_query -query $q]]
            set q "openacs test not automated"
            aa_true "Multiple terms automatic AND, explicit NOT '[tsearch2::build_query -query $q]'" \
                [string equal "openacs & test & ! automated" \
                     [tsearch2::build_query -query $q]]
            set q "openacs test or automated"
            aa_true "Multiple terms automatic AND, explicit OR '[tsearch2::build_query -query $q]'" \
                [string equal "openacs & test | automated" \
                     [tsearch2::build_query -query $q]]
            set q "(openacs test) or automated"
            aa_true "Multiple terms grouped '[tsearch2::build_query -query $q]'" \
                [string equal "(openacs & test) | automated" \
                     [tsearch2::build_query -query $q]]
            set q "(openacs or test) automated"
            aa_true "Multiple terms grouped automatic AND '[tsearch2::build_query -query $q]'" \
                [string equal "(openacs | test) & automated" \
                     [tsearch2::build_query -query $q]]
            set q "one a two"
            aa_true "Single letter elements" \
                [string equal "one & a & two" \
                     [tsearch2::build_query -query $q]]

	    set q "or else"
	    aa_true "Or at beginning by itself" \
		[string equal "else" \
		     [tsearch2::build_query -query $q]]
	    set q "not" 
	    aa_true "Not all alone" \
		[string equal "" \
		     [tsearch2::build_query -query $q]]
        }
}
