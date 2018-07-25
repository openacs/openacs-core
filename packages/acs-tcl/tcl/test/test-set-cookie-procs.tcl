ad_library {
    
    Test Case for set_cookie procs
    
    @author Cesar Hernandez (cesarhj@galileo.edu)
    @creation-date 2006-08-10
    @cvs-id $Id$
}

aa_register_case \
    -cats {web smoke} \
    -procs {
        ad_get_cookie
        ad_set_cookie
        ad_set_signed_cookie
    } \
    test_set_cookie_procs \
    {
	Test Case for testing if a cookie is fixed
    } {
	#-----------------------------------------------------------------------------
	#Set values for default
	#-----------------------------------------------------------------------------
	set data [ad_generate_random_string]

	aa_log "The content of the cookie is: $data"

	aa_run_with_teardown -test_code {

	    #-------------------------------------------------------------------------
	    #set the cookie
	    #------------------------------------------------------------------------- 
	    ad_set_cookie "test_cookie_test_case" "$data"

	    #-------------------------------------------------------------------------
	    #Get the cookie and we try if exist
	    #-------------------------------------------------------------------------
	    set cookie_info_p [ad_get_cookie -include_set_cookies t test_cookie_test_case "" ]
	    aa_equals "Check if the cookie exist"  $cookie_info_p $data

	    #-------------------------------------------------------------------------
	    #clearing the cookie
	    #-------------------------------------------------------------------------
	    ad_set_cookie -replace t -max_age 0 test_cookie_test_case ""
	    set cookie_info_d [ad_get_cookie -include_set_cookies t test_cookie_test_case ""]

	    #-------------------------------------------------------------------------
	    #Check if the cookie was cleared
	    #-------------------------------------------------------------------------
	    aa_false "Check if the cookie was cleared" [string equal $cookie_info_d $data]


	    # known secret
	    ad_set_signed_cookie -secret "hello" -max_age 100 -token_id 101 testcookie "as,df"
	    # random secret
	    ad_set_signed_cookie -max_age 1 testcookie2 "lots,of,,commas"

	    #set cookie_value [ad_get_signed_cookie testcookie]
	    set cookie_value [ns_urldecode [ad_get_cookie testcookie]]

	    aa_equals "cookie payload" "as,df" [lindex $cookie_value 0]

	    set cookie_meta [lindex $cookie_value 1]

	    aa_equals "cookie meta length" 3 [llength $cookie_meta]

	    lassign $cookie_meta token_id expire hash

	    aa_equals "cookie meta token_id" 101 $token_id


	} -teardown_code {

	}
    }

aa_register_case \
    -cats {web smoke} \
    -procs {
        ad_get_client_property
        ad_set_client_property
    } \
    client_properties \
    {
	Test Case client properties
    } {
	aa_run_with_teardown -test_code {
	    ad_set_client_property test MyName MyValue

	    aa_equals "Obtain client property" MyValue [ad_get_client_property test MyName]
	    
	}
    }
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
