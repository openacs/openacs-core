#/packages/acs-tcl/tcl/test 

ad_library {
    
    Test Case for set_cookie procs
    
    @author Cesar Hernandez (cesarhj@galileo.edu)
    @creation-date 2006-08-10
    @arch-tag: 0AA7362F-83FF-4067-B391-A2F8D6918F3E
    @cvs-id $Id$
}

aa_register_case \
    -cats {web smoke} \
    -libraries tclwebtest \
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
	    aa_true "Check if the cookie exist" [string equal $cookie_info_p $data]

	    #-------------------------------------------------------------------------
	    #clearing the cookie
	    #-------------------------------------------------------------------------
	    ad_set_cookie -replace t -max_age 0 test_cookie_test_case ""
	    set cookie_info_d [ad_get_cookie -include_set_cookies t test_cookie_test_case ""]

	    #-------------------------------------------------------------------------
	    #Check if the cookie was cleared
	    #-------------------------------------------------------------------------
	    aa_false "Check if the cookie was cleared" [string equal $cookie_info_d $data]

	} -teardown_code {

	}
    }
