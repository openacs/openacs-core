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
    Takes a URL and invokes tclwebtest::do_request. Will retry
    the request a number of times if it fails because of a socket
    connect problem.
} {
    aa_log "twt::do_request $page_url"

    # Qualify page_url if necessary
    if { [regexp {^/} $page_url] } {
        set page_url [acs::test::url]${page_url}
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
                    ns_sleep 5s
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
        # Either some non-socket error, or a socket problem occurring with more than
        # $retry_max times. Propagate the error while retaining the stack trace
        aa_log "twt::do_request failed with error=\"$errmsg\" response_url=\"[tclwebtest::response url]\". See error log for the HTML response body"
        ns_log Error "twt::do_request failed with error=\"$errmsg\" response_url=\"[tclwebtest::response url]\" response_body=\"[tclwebtest::response body]\""
        error $errmsg $::errorInfo
    }
}

ad_proc twt::log { message } {
    TWT proc for writing a Notice message to the web server log.
} {
    ns_log Notice "twt::log - $message"
}

ad_proc -deprecated twt::server_url {} {
    Get the URL of the server (like ad_url) using the IP number of the server.
    Is more bulletproof than using the domain name.

    @author Peter Marklund

    DEPRECATED: a more reliable api is now available that also allows
    to override it via parameter.

    @see acs::test::url
} {
    set ip_address [ns_config ns/server/[ns_info server]/module/nssock Address]

    # If the IP is not configured in the config.tcl we will use the ip of localhost
    if {$ip_address eq ""} {
     set ip_address 127.0.0.1
    }

    regexp {(:[0-9]*)?$} [util_current_location] match port

    if { [info exists port] && $port ne "" } {
        return "http://${ip_address}${port}"
    } else {
        return "http://$ip_address"
    }
}

#########################
#
# twt::usernamespace
#
#########################

ad_proc -deprecated twt::user::create {
    {-user_id {}}
    {-admin:boolean}
 } {
    Create a test user with random email and password for testing

    @param admin Provide this switch to make the user site-wide admin

    @return The user_info array list returned by auth::create_user. Contains
            the additional keys email and password.

    @author Peter Marklund

    @see acs::test::user::create
 } {
     return [acs::test::user::create -user_id $user_id -admin=$admin_p]
}

ad_proc -deprecated twt::user::delete {
    {-user_id:required}
} {
    Remove a test user.

    @see ::acs::test::user_delete
} {
    ::acs::test::user_delete -user_id $user_id
}

ad_proc twt::user::login { email password {username ""}}  {
    tclwebtest for logging the user in.

    @param email Email of user to log in.
    @param password Password of user to log in.
} {
    if {$username eq ""} {
        set username $email
    }
    aa_log "twt::login email $email password $password username $username"
    tclwebtest::cookies clear

    # Request the start page
    ::twt::do_request [acs::test::url]/register

    # Login the user
    tclwebtest::form find ~n login

    set local_authority_id [auth::authority::local]
    set local_authority_pretty_name [auth::authority::get_element -authority_id $local_authority_id -element pretty_name]
    if {![catch {tclwebtest::field find ~n authority_id} errmsg]} {
        tclwebtest::field select $local_authority_pretty_name
        aa_log "twt::login selecting authority_id $local_authority_id"
    }
    if {[catch {tclwebtest::field find ~n email} errmsg]} {
        tclwebtest::field find ~n username
        tclwebtest::field fill $username
        aa_log "twt::login using username instead of email"
    } else {
        aa_log "twt::login using email instead of username"
        tclwebtest::field fill "$email"
    }
    tclwebtest::field find ~n password
    tclwebtest::field fill $password
    tclwebtest::form submit

    # Verify that user is actually logged in and throw error otherwise
    set home_uri "/pvt/home"
    twt::do_request $home_uri
    set response_url [tclwebtest::response url]

    if { ![string match "*${home_uri}*" $response_url] } {
        if { [party::get_by_email -email $email] eq "" } {
            error "Failed to login user with email=\"$email\" and password=\"$password\". No user with such email in database."
        } else {
            ns_log Error "Failed to log in user with email=\"$email\" and password=\"$password\" even though email exists (password may be incorrect). response_body=[tclwebtest::response body]"
            error "Failed to log in user with email=\"$email\" and password=\"$password\" even though email exists (password may be incorrect). User should be able to request $home_uri without redirection (response url=$response_url)"

        }
    }
}

ad_proc twt::user::logout {} {
    tclwebtest for logging the user out.
} {
    twt::do_request [acs::test::url]/register/logout
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
