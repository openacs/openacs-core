ad_library {

    Test Case for set_cookie procs

    @author Cesar Hernandez (cesarhj@galileo.edu)
    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2006-08-10
    @cvs-id $Id$
}

aa_register_case -cats {
    api
    smoke
} -procs {
    ad_get_cookie
    ad_set_cookie
    ad_get_signed_cookie
    ad_set_signed_cookie
} test_set_cookie_procs {
    Test Case for testing cookie creation and deletion
} {
    aa_run_with_teardown -rollback -test_code {
        aa_section "Set and get cookie"
        #
        # Set the cookie
        #
        set data [ad_generate_random_string]
        ad_set_cookie testcookie "$data"
        #
        # Get the cookie
        #
        set cookie_info_p [ad_get_cookie -include_set_cookies t testcookie "" ]
        aa_equals "Check if the new cookie exists (content: $data)" \
            $cookie_info_p $data
        #
        # Set cookie with known secret
        #
        aa_section "Cookie with known secret"
        set secret_token hello
        ad_set_signed_cookie \
            -secret $secret_token \
            -max_age 100 \
            -token_id 101 \
            testcookie2 "as,df"
        set cookie_value    [ns_urldecode [ad_get_cookie testcookie2]]
        set cookie_payload  [lindex $cookie_value 0]
        set cookie_meta     [lindex $cookie_value 1]
        lassign $cookie_meta token_id expire hash
        #
        # Check payload
        #
        aa_equals "Cookie payload" "as,df" $cookie_payload
        #
        # Check meta length
        #
        aa_equals "Cookie meta length" 3 [llength $cookie_meta]
        #
        # Check meta token_id
        #
        aa_equals "Cookie meta token_id" 101 $token_id
        #
        # Check hash
        #
        set computed_hash [ns_sha1 \
            "$cookie_payload$token_id$expire$secret_token"]
        aa_equals "Cookie hash" $computed_hash $hash
        #
        # Set cookie with random secret
        #
        aa_section "Cookie with random secret"
        ad_set_signed_cookie -max_age 1 testcookie3 "lots,of,,commas"
        set cookie_payload [lindex [ad_get_signed_cookie testcookie3] 0]
        #
        # Check payload
        #
        aa_equals "Cookie payload" "lots,of,,commas" $cookie_payload
        #
        # Clear the cookies
        #
        aa_section "Clear cookies"
        foreach cookie {testcookie testcookie2 testcookie3} {
            ad_set_cookie -replace t -max_age 0 $cookie ""
            set cookie_info_d [ad_get_cookie \
                                -include_set_cookies t \
                                $cookie ""]
            aa_false "Check if the cookie ($cookie) was cleared" \
                [string equal $cookie_info_d $data]
        }
    }
}

aa_register_case \
    -cats {api smoke} \
    -procs {
        ad_get_client_property
        ad_set_client_property
    } \
    client_properties \
    {
        Test Case client properties
    } {
        aa_run_with_teardown -rollback -test_code {
            ad_set_client_property test MyName MyValue

            aa_equals "Obtain client property" MyValue [ad_get_client_property test MyName]

        }
    }

aa_register_case -cats {
    api
    smoke
    production_safe
} -procs {
    sec_get_random_cached_token_id
    sec_get_token
} secret_tokens_get {
    Test secret_tokens
} {
    aa_run_with_teardown -rollback -test_code {
        #
        # Check random token in nsv and DB, n times
        #
        set n 10
        for {set i 0} {$i < $n} {incr i} {
            set random_token_id [sec_get_random_cached_token_id]
            #
            # Check random token in nsv
            #
            set list_of_names [nsv_array get secret_tokens]
            aa_true "Random token ($random_token_id) is contained in nsv" \
                {[lsearch -exact $list_of_names $random_token_id]}
            #
            # Check random token in DB
            #
            set token_value     [sec_get_token $random_token_id]
            set token_value_db  [db_string get_token_value {
                select token
                  from secret_tokens
                 where token_id = :random_token_id
            }]
            aa_equals "Random token ($random_token_id) value is in DB" \
                "$token_value" "$token_value_db"
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
