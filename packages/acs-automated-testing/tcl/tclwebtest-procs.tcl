ad_library {
    Helper procs for test cases using tclwebtest (HTTP level tests).

    @author Peter Marklund
    @creation-date 31 March 2004
    @cvs-id $Id$
}

namespace eval twt {}
namespace eval twt::user {}

#########################
#
# twt namespace
#
#########################

ad_proc twt::do_request { page_url } {
    Takes a a url and invokes tclwebtest::do_request. Will retry
    the request a number of times if it fails because of a socket
    connect problem.
} {
    # Qualify page_url if necessary
    if { [regexp {^/} $page_url] } {
        set page_url "[twt::server_url]${page_url}"
    }

    set retry_count 0
    set retry_max 10
    set error_p 0
    while { [catch {::tclwebtest::do_request $page_url} errmsg] } {
        set error_p 1

        if { $retry_count < $retry_max } {
            switch -regexp -- $errmsg {
                {unreachable} - {refused} {
                    ::twt::log "Failed to connect to server with error \"$errmsg\" - retrying"
                    incr retry_count
                    exec "sleep" "5"
                    set error_p 0
                    continue
                }
                default {
                    ::twt::log "Failed to connect to server with error \"$errmsg\" - giving up"
                    break
                }
            }
        } else {
            break
        }
    }

    if { $error_p } {
        # Either some non-socket error, or a socket problem occuring with more than
        # $retry_max times. Propagate the error while retaining the stack trace
        global errorInfo
        error $errmsg $errorInfo
    }

    #::twt::acs_lang::check_no_keys
}

ad_proc twt::log { message } {
    ns_log Notice "twt::log - $message"
}

ad_proc twt::server_url {} {
    Get the URL of the server (like ad_url) using the IP number of the server.
    Is more bulletproof than using the domain name.

    @author Peter Marklund
} {
    set ip_address [ns_config ns/server/[ns_info server]/module/nssock Address]

    regexp {(:[0-9]*)?$} [util_current_location] match port

    if { [exists_and_not_null port] } {
        return "http://${ip_address}${port}"
    } else {
        return "http://$ip_address"
    }
}

#########################
#
# twt::user namespace
#
#########################

ad_proc twt::user::create { 
    {-user_id {}}
 } {
    Create a test user with random email and password for testing
    
    @return The user_info array list returned by auth::create_user. Contains
            the additional keys email and password.

    @author Peter Marklund
} {
    set username "__test_user_[ad_generate_random_string]"
    set email "${username}@test.test"
    set password [ad_generate_random_string]

    array set user_info [auth::create_user \
                                     -user_id $user_id \
                                     -username $username \
                                     -email $email \
                                     -first_names [ad_generate_random_string] \
                                     -last_name [ad_generate_random_string] \
                                     -password $password \
                                     -secret_question [ad_generate_random_string] \
                                     -secret_answer [ad_generate_random_string]]

    if { ![string equal $user_info(creation_status) ok] } {
        # Could not create user
        error "Could not create test user with username=$username user_info=[array get user_info]"
    }

    set user_info(password) $password
    set user_info(email) $email

    return [array get user_info]
}

ad_proc twt::user::delete {
    {-user_id:required}
} {
    Remove a test user.
} {
    acs_user::delete \
        -user_id $user_id \
        -permanent
}

ad_proc twt::user::login { email password } {

    ::twt::user::logout

    # Request the start page
    ::twt::do_request "[twt::server_url]/register"

    # Login the user
    tclwebtest::form find ~n login
    tclwebtest::field find ~n email
    tclwebtest::field fill "$email"
    tclwebtest::field find ~n password
    tclwebtest::field fill $password
    tclwebtest::form submit
}

ad_proc twt::user::logout {} {
    twt::do_request "[twt::server_url]/register/logout"
}
