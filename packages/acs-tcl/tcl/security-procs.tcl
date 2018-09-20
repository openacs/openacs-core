ad_library {

    Provides methods for authorizing and identifying ACS users
    (both logged in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @author Richard Li (richardl@arsdigita.com)
    @author Archit Shah (ashah@arsdigita.com)
    @cvs-id $Id$
}

namespace eval security {
    set log(login_url) debug    ;# notice
    set log(login_cookie) debug ;# notice
}


# cookies (all are signed cookies):
#   cookie                value                          max-age         secure
#   ad_session_id         session_id,user_id,login_level SessionTimeout  yes|no  (when SecureSessionCookie set: yes)
#   ad_user_login         user_id,issue_time,auth_token  never expires   no
#   ad_user_login_secure  user_id,random                 never expires   yes
#   ad_secure_token       session_id,random,peeraddr     SessionLifetime yes
#
#   the random data is used to hinder attack the secure hash.
#   currently the random data is ns_time
#   peeraddr is used to avoid session hijacking
#
#   ad_user_login issue_time: [ns_time] at the time the user last authenticated
#
#   ad_session_id login_level: 0 = none/expired, 1 = ok, 2 = auth ok, but account closed
#


ad_proc -private sec_random_token {} {
    Generates a random token.
} {
    # ::tcl_sec_seed is used to maintain a small subset of the previously
    # generated random token to use as the seed for the next
    # token. This makes finding a pattern in sec_random_token harder
    # to guess when it is called multiple times in the same thread.

    if { [ad_conn -connected_p] } {
        set request [ad_conn request]
        set start_clicks [ad_conn start_clicks]
    } else {
        set request "yoursponsoredadvertisementhere"
        set start_clicks "cvs.openacs.org"
    }

    if { ![info exists ::tcl_sec_seed] } {
        set ::tcl_sec_seed "listentowmbr89.1"
    }

    set random_base [ns_sha1 "[ns_time][ns_rand]$start_clicks$request$::tcl_sec_seed"]
    set ::tcl_sec_seed [string range $random_base 0 10]

    return [ns_sha1 [string range $random_base 11 39]]
}

ad_proc -private sec_session_lifetime {} {
    Returns the maximum lifetime, in seconds, for sessions.
} {
    # default value is 7 days ( 7 * 24 * 60 * 60 )
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter SessionLifetime -default 604800]
}

ad_proc -private sec_sweep_sessions {} {
    set expires [expr {[ns_time] - [sec_session_lifetime]}]

    db_dml sessions_sweep {}
    db_release_unused_handles
}

ad_proc -private sec_handler_reset {} {

    Provide dummy values for global variables provided by the
    sec_handler, in case, the sec_handler is not called or runs into
    an exception.

} {
    set ::__csp_nonce [::security::csp::nonce]
    set ::__csrf_token ""
}

ad_proc -private sec_handler {} {

    Reads the security cookies, setting fields in ad_conn accordingly.

} {
    ns_log debug "OACS= sec_handler: enter"

    if {$::security::log(login_cookie) ne "debug"} {
        foreach c [list ad_session_id ad_secure_token ad_user_login ad_user_login_secure] {
            lappend msg "$c '[ad_get_cookie $c]'"
        }
        ns_log notice "OACS [ns_conn url] cookies: $msg"
    }

    if { [catch {
        set cookie_list [ad_get_signed_cookie "ad_session_id"]
    } errmsg ] } {
        # Cookie is invalid because either:
        # -> it was never set
        # -> it failed the cryptographic check
        # -> it expired.

        # Now check for login cookie
        ns_log $::security::log(login_cookie) "OACS: Not a valid session cookie, looking for login cookie '$errmsg'"
        if {[string match "*does not exist*" $errmsg]} {
            #
            # We have no cookie. Maybe we are running under aa_test.
            #
            #if {[nsv_array exists aa_test]} {
            #    ns_log notice "nsv_array logindata [nsv_get aa_test logindata logindata]"
            #    ns_log notice "ns_conn peeraddr [ns_conn peeraddr]"
            #    ns_log notice "dict get $logindata peeraddr [dict get $logindata peeraddr]"                
            #}
            if {[nsv_array exists aa_test]
                && [nsv_get aa_test logindata logindata]
                && [ns_conn peeraddr] eq [dict get $logindata peeraddr]
            } {
                #ns_log notice logindata=$logindata
                if {[dict exists $logindata user_id]} {
                    set user_id [dict get $logindata user_id]
                    ad_conn -set user_id $user_id
                    ad_conn -set untrusted_user_id $user_id
                    ad_conn -set account_status ok
                    ad_conn -set auth_level ok
                    #ad_conn -set session_id [sec_allocate_session]
                    set auth_level ok
                    set untrusted_user_id $user_id
                    set ::__aa_testing_mode 1
                }
            }
        } else {
            #
            # We have a cookie, but it is not ok, so logout.
            #
            ad_user_logout
        }

        #
        # Unless we have managed to get credentials above, get it now.
        #
        if {![info exists auth_level]} {
            sec_login_handler
        }
    } else {
        #
        # The session cookie already exists and is valid.
        #
        set cookie_data [split [lindex $cookie_list 0] {,}]
        set session_last_renew_time [lindex $cookie_data 3]
        if {![string is integer -strict $session_last_renew_time]} {
            # This only happens if the session cookie is old style
            # previous to OpenACS 5.7 and does not have session review time
            # embedded.
            # Assume cookie expired and force login handler
            set session_last_renew_time 0
        }

        set session_expr [expr {$session_last_renew_time + [sec_session_timeout]}]
        if {$session_expr < [ns_time]} {
            sec_login_handler
        }

        lassign $cookie_data session_id untrusted_user_id login_level
        set user_id 0
        set account_status closed

        switch -- $login_level {
            1 {
                set auth_level ok
                set user_id $untrusted_user_id
                set account_status ok
            }
            2 {
                set auth_level ok
            }
            default {
                if { $untrusted_user_id == 0 } {
                    set auth_level none
                } else  {
                    set auth_level expired
                }
            }
        }

        ns_log $::security::log(login_cookie) "Security: Insecure session OK: session_id $session_id, untrusted_user_id $untrusted_user_id, auth_level $auth_level, user_id $user_id"

        # We're okay, insofar as the insecure session, check if it's also secure
        if { $auth_level eq "ok" && [security::secure_conn_p] } {
            catch {
                set sec_token [split [ad_get_signed_cookie "ad_secure_token"] {,}]
                if {[lindex $sec_token 0] eq $session_id
                    && [lindex $sec_token 2] eq [ad_conn peeraddr]
                } {
                    set auth_level secure
                }
            }
            ns_log $::security::log(login_cookie) "Security: Secure session checked: session_id = $session_id, untrusted_user_id = $untrusted_user_id, auth_level = $auth_level, user_id = $user_id"
        }

        # Setup ad_conn
        ad_conn -set session_id $session_id
        ad_conn -set untrusted_user_id $untrusted_user_id
        ad_conn -set user_id $user_id
        ad_conn -set auth_level $auth_level
        ad_conn -set account_status $account_status

        # Reissue session cookie so session doesn't expire if the
        # renewal period has passed. This is a little tricky because
        # the cookie doesn't know about sec_session_renew; it only
        # knows about sec_session_timeout.
        # [sec_session_renew] = SessionTimeout - SessionRenew (see security-init.tcl)
        # $session_expr = PreviousSessionIssue + SessionTimeout
        if { $session_expr - [sec_session_renew] < [ns_time] } {

            # # LARS: We abandoned the use of sec_login_handler here. This lets people stay logged in forever
            # # if only they keep requesting pages frequently enough, but the alternative was that
            # # the situation where LoginTimeout = 0 (infinte) and the user unchecks the "Remember me" checkbox
            # # would cause users' sessions to expire as soon as the session needed to be renewed
            sec_generate_session_id_cookie

            # apisano 2018-06-08: as discussed in
            # https://openacs.org/forums/message-view?message_id=1691183#msg_1691183,
            # this would break sec_change_user_auth_token as a mean to
            # invalidate user login...
            #
            # GN: when we use "sec_login_handler" instead of the
            # previous code using "sec_generate_session_id_cookie",
            # persistent logins stop to work (people are logged out
            # from time to time). So, i switched for the time being
            # the to old code.
            #
            #sec_login_handler
        }

        #
        # generate a csrf token and a csp nonce value
        #
        security::csrf::new
    }
}

ad_proc -private sec_login_read_cookie {} {

    Fetches values either from ad_user_login_secure or ad_user_login,
    depending whether we are in a secured connection or not.

    @author Victor Guerra

    @return List of values read from cookie ad_user_login_secure or ad_user_login
} {
    #
    # If over HTTPS, we look for the *_secure cookie
    #
    if { [security::secure_conn_p] } {
        set cookie_name "ad_user_login_secure"
    } else {
        set cookie_name "ad_user_login"
    }
    return [split [ad_get_signed_cookie $cookie_name] ","]
}

ad_proc -private sec_login_handler {} {

    Reads the login cookie, setting fields in ad_conn accordingly.

} {
    ns_log debug "OACS= sec_login_handler: enter"

    set auth_level none
    set new_user_id 0
    set untrusted_user_id 0
    set account_status closed

    # check for permanent login cookie
    catch {
        lassign [sec_login_read_cookie] untrusted_user_id login_expr auth_token
        set auth_level expired

        # Check authentication cookie
        # First, check expiration
        if { [sec_login_timeout] == 0 || [ns_time] - $login_expr < [sec_login_timeout] } {
            # Then check auth_token
            if {$auth_token eq [sec_get_user_auth_token $untrusted_user_id]} {
                # Are we secure?
                if { [security::secure_conn_p] } {
                    # We retrieved the secure login cookie over HTTPS, we're secure
                    set auth_level secure
                } else {
                    set auth_level ok
                }
            }
        }

        # Check account status
        set account_status [auth::get_local_account_status -user_id $untrusted_user_id]

        if {$account_status eq "no_account"} {
            set untrusted_user_id 0
            set auth_level none
            set account_status "closed"
        }
    }

    sec_setup_session $untrusted_user_id $auth_level $account_status
}


ad_proc -public ad_user_login {
    {-account_status "ok"}
    {-cookie_domain ""}
    -forever:boolean
    user_id
} {
    Logs the user in, forever (via the user_login cookie) if -forever
    is true. This procedure assumes that the user identity has been
    validated.
} {
    set prev_user_id [ad_conn user_id]

    # deal with the permanent login cookies (ad_user_login and ad_user_login_secure)
    if { $forever_p } {
        set max_age inf
    } else {
        # ad_user_login cookie will live for as long as the maximum login time
        set max_age [sec_login_timeout]
    }

    set auth_level "ok"
    set secure_p [security::secure_conn_p]
    if {$cookie_domain eq ""} {
        set cookie_domain [parameter::get -parameter CookieDomain -package_id $::acs::kernel_id]
    }

    # If you're logged in over a secure connection, you're secure
    if { $secure_p } {
        ad_set_signed_cookie \
            -max_age $max_age \
            -secure t \
            -domain $cookie_domain \
            ad_user_login_secure \
            "$user_id,[ns_time],[sec_get_user_auth_token $user_id],[ns_time],$forever_p"

        # We're secure
        set auth_level "secure"
    } elseif { $prev_user_id != $user_id } {
        # Hose the secure login token if this user is different
        # from the previous one.
        ad_unset_cookie -secure t ad_user_login_secure
    }

    ns_log Debug "ad_user_login: Setting new ad_user_login cookie with max_age $max_age"
    ad_set_signed_cookie \
        -expire [expr {$forever_p ? false : true}] \
        -max_age $max_age \
        -domain $cookie_domain \
        -secure f \
        ad_user_login \
        "$user_id,[ns_time],[sec_get_user_auth_token $user_id],$forever_p"

    # deal with the current session
    sec_setup_session -cookie_domain $cookie_domain $user_id $auth_level $account_status
}

ad_proc -public sec_get_user_auth_token {
    user_id
} {
    Get the user's auth token for verifying login cookies.
} {
    set auth_token [db_string select_auth_token {
        select auth_token from users where user_id = :user_id
    } -default {}]
    db_release_unused_handles

    if { $auth_token eq "" } {
        ns_log Debug "Security: User $user_id does not have any auth_token, creating a new one."
        set auth_token [sec_change_user_auth_token $user_id]
    }

    return $auth_token
}

ad_proc -public sec_change_user_auth_token {
    user_id
} {
    Change the user's auth_token, which invalidates all existing login cookies, i.e. forces user logout at the server.
} {
    set auth_token [ad_generate_random_string]

    ns_log Debug "Security: Changing user $user_id's auth_token to '$auth_token'"
    db_dml update_auth_token {
        update users set auth_token = :auth_token where user_id = :user_id
    }
    db_release_unused_handles

    return $auth_token
}


ad_proc -public ad_user_logout {
    {-cookie_domain ""}
} {
    Logs the user out.
} {
    if {$cookie_domain eq ""} {
        set cookie_domain [parameter::get -parameter CookieDomain -package_id $::acs::kernel_id]
    }
    #
    # Use the same "secure" setting for unsetting the cookie as it was
    # used for setting the cookie. The implementation is not 100%
    # correct, for cases, when the parameter value for
    # "SecureSessionCookie" was altered during a session, but this
    # should be a seldom border case.
    #
    ad_unset_cookie -domain $cookie_domain -secure [expr {[parameter::get \
                            -parameter SecureSessionCookie \
                            -package_id [ad_acs_kernel_id] \
                            -default 0] ? "t" : "f"}] ad_session_id
    ad_unset_cookie -domain $cookie_domain -secure f ad_user_login
    ad_unset_cookie -domain $cookie_domain -secure t ad_secure_token
    ad_unset_cookie -domain $cookie_domain -secure t ad_user_login_secure
}

ad_proc -public ad_check_password {
    user_id
    password_from_form
} {
    Returns 1 if the password is correct for the given user ID.
} {

    set found_p [db_0or1row password_select {select password, salt from users where user_id = :user_id}]
    db_release_unused_handles
    if { !$found_p } {
        return 0
    }

    set salt [string trim $salt]

    if {$password ne [ns_sha1 "$password_from_form$salt"]  } {
        return 0
    }

    return 1
}

ad_proc -public ad_change_password {
    user_id
    new_password
} {
    Change the user's password
} {
    # In case someone wants to change the salt from now on, you can do
    # this and still support old users by changing the salt below.

    if { $user_id eq "" } {
        error "No user_id supplied"
    }

    set salt [sec_random_token]
    set new_password [ns_sha1 "$new_password$salt"]
    db_dml password_update {}
    db_release_unused_handles
}

ad_proc -private sec_setup_session {
    {-cookie_domain ""}
    new_user_id
    auth_level
    account_status
} {

    Set up the session, generating a new one if necessary,
    and generates the cookies necessary for the session

} {
    ns_log debug "OACS= sec_setup_session: enter"

    set session_id [ad_conn session_id]

    # figure out the session id, if we don't already have it
    if { $session_id eq ""} {

        ns_log debug "OACS= empty session_id"

        set session_id [sec_allocate_session]
        # if we have a user on an newly allocated session, update
        # users table

        ns_log debug "OACS= newly allocated session $session_id"

        if { $new_user_id != 0 } {
            ns_log debug "OACS= about to update user session info, user_id NONZERO"
            sec_update_user_session_info $new_user_id
            ns_log debug "OACS= done updating user session info, user_id NONZERO"
        }
    } else {
        # $session_id is an active verified session
        # this call is either a user logging in
        # on an active unidentified session, or a change in identity
        # for a browser that is already logged in

        # this is an active session [ad_conn user_id] will not return
        # the empty string
        set prev_user_id [ad_conn user_id]

        #
        # Change the session id for all user_id changes, also on
        # changes from user_id 0, since owasp recommends to renew the
        # session_id after any privilege level change
        #
        ns_log debug "prev_user_id $prev_user_id new_user_id $new_user_id"

        if { $prev_user_id != 0 && $prev_user_id != $new_user_id } {
            # this is a change in identity so we should create
            # a new session so session-level data is not shared
            ns_log debug "sec_allocate_session"
            set session_id [sec_allocate_session]
        }

        if { $prev_user_id != $new_user_id } {
            # a change of user_id on an active session
            # demands an update of the users table
            ns_log debug "sec_update_user_session_info"
            sec_update_user_session_info $new_user_id
        }
    }

    set user_id 0

    # If both auth_level and account_status are 'ok' or better, we have a solid user_id
    if { ($auth_level eq "ok" || $auth_level eq "secure") && $account_status eq "ok" } {
        set user_id $new_user_id
    }

    # Set ad_conn variables
    ad_conn -set untrusted_user_id $new_user_id
    ad_conn -set session_id $session_id
    ad_conn -set auth_level $auth_level
    ad_conn -set account_status $account_status
    ad_conn -set user_id $user_id

    ns_log debug "OACS= about to generate session id cookie"

    sec_generate_session_id_cookie -cookie_domain $cookie_domain

    ns_log debug "OACS= done generating session id cookie"

    if { $auth_level eq "secure" && [security::secure_conn_p] && $new_user_id != 0 } {
        # this is a secure session, so the browser needs
        # a cookie marking it as such
        sec_generate_secure_token_cookie
    }
}

ad_proc -private sec_update_user_session_info {
    user_id
} {
    Update the session info in the users table. Should be called when
    the user login either via permanent cookies at session creation
    time or when they login by entering their password.
} {
    db_dml update_last_visit {}
    db_release_unused_handles
}

ad_proc -private sec_generate_session_id_cookie {
    {-cookie_domain ""}
} {
    Sets the ad_session_id cookie based on global variables.
} {
    set user_id [ad_conn untrusted_user_id]
    #
    # Maybe we need the session_id of the cookie-domain
    #
    set session_id [ad_conn session_id]
    set auth_level [ad_conn auth_level]
    set account_status [ad_conn account_status]

    set login_level 0
    if { $auth_level eq "ok" || $auth_level eq "secure" } {
        if {$account_status eq "ok"} {
            set login_level 1
        } else {
            set login_level 2
        }
    }

    ns_log Debug "Security: [ns_time] sec_generate_session_id_cookie setting session_id=$session_id, user_id=$user_id, login_level=$login_level"

    if {$cookie_domain eq ""} {
        set cookie_domain [parameter::get -parameter CookieDomain -package_id $::acs::kernel_id]
    }

    # Fetch the last value element of ad_user_login cookie (or
    # ad_user_login_secure) that indicates if user wanted to be
    # remembered when logging in.

    set discard t
    set max_age [sec_session_timeout]
    catch {
        set login_list [sec_login_read_cookie]
        if {[lindex $login_list end] == 1} {
            set discard f
            set max_age inf
        }
    }
    ad_set_signed_cookie \
        -secure [expr {[parameter::get \
                            -parameter SecureSessionCookie \
                            -package_id [ad_acs_kernel_id] \
                            -default 0] ? "t" : "f"}] \
        -discard $discard \
        -replace t \
        -max_age $max_age \
        -domain $cookie_domain \
        ad_session_id "$session_id,$user_id,$login_level,[ns_time]"
}

ad_proc -private sec_generate_secure_token_cookie { } {
    Sets the ad_secure_token cookie.
} {
    ad_set_signed_cookie -secure t "ad_secure_token" "[ad_conn session_id],[ns_time],[ad_conn peeraddr]"
}

ad_proc -private sec_allocate_session {} {

    Returns a new session id

} {

    if { ![info exists ::acs::sec_id_max_value] || ![info exists ::acs::sec_id_current_sequence_id]
         || $::acs::sec_id_current_sequence_id > $::acs::sec_id_max_value } {
        # Thread just spawned or we exceeded preallocated count.
        set ::acs::sec_id_current_sequence_id [db_nextval sec_id_seq]
        db_release_unused_handles
        set ::acs::sec_id_max_value [expr {$::acs::sec_id_current_sequence_id + 100}]
    }

    set session_id $::acs::sec_id_current_sequence_id
    incr ::acs::sec_id_current_sequence_id

    return $session_id
}

ad_proc -private ad_login_page {} {

    Returns 1 if the page is used for logging in, 0 otherwise.

} {
    set url [ad_conn url]
    if { [string match "*register/*" $url]
         || [string match "/index*" $url]
         || [string match "/index*" $url]
         || "/" eq $url
         || [string match "*password-update*" $url]
     } {
        return 1
    }

    return 0
}






#####
#
# Login/logout URLs, redirecting, etc.
#
#####

ad_proc -private ad_get_node_id_from_host_node_map {hostname} {
    Obtain node_id from host_node_map
    @param hostname
    @return node_id (or 0, if the provided hostname is not mapped)
} {
    #
    # Get all entries in one sweep, such that the result can be
    # cached, no matter which hostname is provided as input; the code
    # assumes that the host-node-map is always short. This allows us
    # as well to purge the entries without a pattern match.
    #
    set lists [db_list_of_lists -cache_key ad_get_host_node_map \
                  get_node_host_names {select host, node_id from host_node_map}]
    set p [lsearch -index 0 -exact $lists $hostname]
    if {$p != -1} {
        set result [lindex $lists $p 1]
    } else {
        set result 0
    }
    return $result
}

ad_proc -public ad_redirect_for_registration {} {

    Redirects user to [subsite]/register/index to require the user to
    register. When registration is complete, the user will be returned
    to the current location.  All variables in ns_getform (both posts and
    gets) will be maintained.

    <p>

    It's up to the caller to issue an ad_script_abort, if that's what you want.

    @see ad_get_login_url
} {
    ad_returnredirect [ad_get_login_url -return]
    # caller might call "ad_script_abort"
}


ad_proc -private security::replace_host_in_url {-hostname url} {

    Given a fully qualified url, replace the hostname in this URL with
    the given hostname.

    @return url with remapped hostname
} {
    set ui [ns_parseurl $url]
    if {[dict exists $ui port]} {
        set _port [dict get $ui port]
    } else {
        set _port ""
    }
    set location [util::join_location \
                      -proto [dict get $ui proto] \
                      -hostname $hostname \
                      -port $_port]
    set elements ""
    if {[dict get $ui path] ne ""} {
        lappend elements [dict get $ui path]
    }
    lappend elements [dict get $ui tail]

    return $location/[join $elements /]
}

ad_proc -private security::get_register_subsite {} {

    Returns a URL pointing to the subsite, on which the
    register/unregister should be performed. If there is no current
    connection, the main site url is returned.

    TODO: util_current_location and security::get_register_subsite
    can be probably cached, when using the following parameters in
    the cache key:
       - host header field
       - [ns_conn location]
       - ...
    also [security::get_register_subsite] could/should be cached

    @author Gustaf Neumann
} {

    util::split_location [util_current_location] current_proto current_host current_port
    set config_hostname [dict get [util_driver_info] hostname]
    set UseHostnameDomainforReg [parameter::get \
                                     -package_id [apm_package_id_from_key acs-tcl] \
                                     -parameter UseHostnameDomainforReg \
                                     -default 0]
    set require_qualified_return_url $UseHostnameDomainforReg
    set host_node_id [ad_get_node_id_from_host_node_map $current_host]

    if { $host_node_id > 0 } {
        #
        # We are on a host-node mapped subsite
        #
        set package_id  [site_node::get_object_id -node_id $host_node_id]
        set package_key [apm_package_key_from_id $package_id]
        if {$package_key eq "acs-subsite"} {
            #
            # The host-node-map points to a subsite, use this for
            # login.
            #
            set url /
            set subsite_id $package_id

            if {$UseHostnameDomainforReg} {
                set url [subsite::get_element -subsite_id $package_id -element url]
                set url [security::get_qualified_url $url]
                # We have a fully qualified url, but we have to remap
                # the URL to the configured host name, since
                # get_qualified prepends the [ad_conn location], which
                # points to the virtual host name.
                set url [security::replace_host_in_url -hostname $config_hostname $url]
            }
        } else {
            #
            # The host-node-map points to an application package and
            # not to a subsite. We have to provide logins via next
            # available subsite.
            #
            set subsite_id [site_node::closest_ancestor_package \
                                     -node_id $host_node_id \
                                     -package_key acs-subsite \
                                     -include_self \
                                     -element "object_id"]
            set url [subsite::get_element -subsite_id $subsite_id -element url]
            set url [security::get_qualified_url $url]
            set url [security::replace_host_in_url -hostname $config_hostname $url]
            set require_qualified_return_url 1
        }
    } else {
        #
        # We are on normal subsite
        #
        if { [ad_conn isconnected] } {
            set url [subsite::get_element -element url]
            #
            # Check to see that the user (most likely "The Public"
            # party, since there's probably no user logged in)
            # actually have permission to view that subsite, otherwise
            # we'll get into an infinite redirect loop.
            #
            array set site_node [site_node::get_from_url -url $url]
            set subsite_id $site_node(object_id)
            if { ![permission::permission_p -no_login \
                       -object_id $subsite_id \
                       -privilege read \
                       -party_id 0] } {
                set url /
            }
        } else {
            #
            # If we are not connected, there can't be a virtual
            # server, so we assume to perform the login on the main
            # subsite.
            #
            set url /
            set host_node_id [dict get [site_node::get_from_url -url $url] node_id]
            set subsite_id [site_node::get_object_id -node_id $host_node_id]
        }
        if {$UseHostnameDomainforReg} {
            set url [security::get_qualified_url $url]
            set url [security::replace_host_in_url -hostname $config_hostname $url]
        }
    }
    return [list \
                url $url \
                subsite_id $subsite_id \
                require_qualified_return_url $require_qualified_return_url \
                host_node_id $host_node_id]
}


ad_proc -public ad_get_login_url {
    {-authority_id ""}
    {-username ""}
    -return:boolean
} {

    Returns a URL to the login page of the closest subsite, or the main site, if there's no current connection.

    @option return      If set, will export the current form, so when the registration is complete,
    the user will be returned to the current location.  All variables in
    ns_getform (both posts and gets) will be maintained.

    @author Lars Pind (lars@collaboraid.biz)
    @author Gustaf Neumann

} {

    set subsite_info [security::get_register_subsite]
    foreach var {url require_qualified_return_url host_node_id} {
        set $var [dict get $subsite_info $var]
    }

    append url "register/"

    #
    # Don't add a return_url if you're already under /register,
    # because that will frequently interfere with the normal login
    # procedure.
    #
    if { [ad_conn isconnected] && $return_p && ![string match "register/*" [ad_conn extra_url]] } {
        #
        # In a few cases, we do not need to add a fully qualified
        # return url. The secure cases have to be still tested.
        #
        if { !$require_qualified_return_url && ([security::secure_conn_p] || ![security::RestrictLoginToSSLP]) } {
            set return_url [ad_return_url]
        } else {
            set return_url [ad_return_url -qualified]
        }
    }
    if {$host_node_id == 0} {
        unset host_node_id
    }
    set url [export_vars -base $url -no_empty {authority_id username return_url host_node_id}]

    ns_log $::security::log(login_url) "ad_get_login_url: final login_url <$url>"

    return $url
}

ad_proc -public ad_get_logout_url {
    -return:boolean
    {-return_url ""}
} {

    Returns a URL to the logout page of the closest subsite, or the main site, if there's no current connection.

    @option return      If set, will export the current form, so when the logout is complete
    the user will be returned to the current location.  All variables in
    ns_getform (both posts and gets) will be maintained.

    @author Lars Pind (lars@collaboraid.biz)
} {

    set subsite_info [security::get_register_subsite]
    set url [dict get $subsite_info url]

    append url "register/logout"

    if { $return_p && $return_url eq "" } {
        set return_url [ad_return_url]
    }
    if { $return_url ne "" } {
        set url [export_vars -base $url { return_url }]
    }

    return $url
}

# JCD 20020915 I think this probably should not be deprecated since it is
# far more reliable than permissioning esp for a development server

ad_proc -public ad_restrict_entire_server_to_registered_users {
    conn
    args
    why
} {
    A preauth filter that will halt service of any page if the user is
    unregistered, except the site index page and stuff underneath
    [subsite]/register. Use permissions on the site node map to control access.
} {
    if {"/favicon.ico" ne [ad_conn url]
        && "/index.tcl" ne [ad_conn url]
        && "/" ne [ad_conn url]
        && ![string match "/global/*" [ad_conn url]]
        && ![string match "*/register/*" [ad_conn url]]
        && ![string match "*/SYSTEM/*" [ad_conn url]]
        && ![string match "*/user_please_login.tcl" [ad_conn url]]} {
        # not one of the magic acceptable URLs
        set user_id [ad_conn user_id]
        if {$user_id == 0} {
            ad_returnredirect "[subsite::get_element -element url]register/?return_url=[ns_urlencode [ad_conn url]?[ad_conn query]]"
            return filter_return
        }
    }
    return filter_ok
}












#####
#
# Signed cookie handling
#
#####

ad_proc -public ad_sign {
    {-secret ""}
    {-token_id ""}
    {-max_age ""}
    value
} {
    Returns a digital signature of the value. Negative token_ids are
    reserved for secrets external to the ACS digital signature
    mechanism. If a token_id is specified, a secret must also be
    specified.

    @param max_age specifies the length of time the signature is
    valid in seconds. The default is forever.

    @param secret allows the caller to specify a known secret external
    to the random secret management mechanism.

    @param token_id allows the caller to specify a token_id which is then ignored so don't use it.

    @param value the value to be signed.
} {
    if {$token_id eq ""} {
        # pick a random token_id
        set token_id [sec_get_random_cached_token_id]
    }

    if { $secret eq "" } {
        set secret_token [sec_get_token $token_id]
    } else {
        set secret_token $secret
    }


    ns_log Debug "Security: Getting token_id $token_id, value $secret_token"

    if { $max_age eq "" } {
        set expire_time 0
    } else {
        set expire_time [expr {$max_age + [ns_time]}]
    }

    set hash [ns_sha1 "$value$token_id$expire_time$secret_token"]
    set signature [list $token_id $expire_time $hash]

    return $signature
}

ad_proc -public ad_verify_signature {
    {-secret ""}
    value
    signature
} {
    Verifies a digital signature. Returns 1 for success, and 0 for
    failed validation. Validation can fail due to tampering or
    expiration of signature.

    @param secret specifies an external secret to use instead of the
    one provided by the ACS signature mechanism.
} {
    lassign $signature token_id expire_time hash
    return [__ad_verify_signature $value $token_id $secret $expire_time $hash]
}

ad_proc -public ad_verify_signature_with_expr {
    {-secret ""}
    value
    signature
} {
    Verifies a digital signature. Returns either the expiration time
    or 0 if the validation fails.

    @param secret specifies an external secret to use instead of the
    one provided by the ACS signature mechanism.
} {
    lassign $signature token_id expire_time hash
    if { [__ad_verify_signature $value $token_id $secret $expire_time $hash] } {
        return $expire_time
    } else {
        return 0
    }

}

ad_proc -private __ad_verify_signature {
    value
    token_id
    secret
    expire_time
    hash
} {

    Returns 1 if signature validated; 0 if it fails.

} {

    if { $secret eq "" } {
        if { $token_id eq "" } {
            ns_log Debug "__ad_verify_signature: Neither secret, nor token_id supplied"
            return 0
        } elseif {![string is integer -strict $token_id]} {
            ns_log Warning "__ad_verify_signature: token_id <$token_id> is not an integer"
            return 0
        }
        set secret_token [sec_get_token $token_id]

    } else {
        set secret_token $secret
    }

    ns_log Debug "__ad_verify_signature: Getting token_id $token_id, value $secret_token ; "
    ns_log Debug "__ad_verify_signature: Expire_Time is $expire_time (compare to [ns_time]), hash is $hash"

    # validate cookie: verify hash and expire_time
    set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

    # Need to verify both hash and expiration
    set hash_ok_p 0
    set expiration_ok_p 0

    if {$computed_hash eq $hash} {
        ns_log Debug "__ad_verify_signature: Hash matches - Hash check OK"
        set hash_ok_p 1
    } else {
        # check to see if IE is lame (and buggy!) and is expanding \n to \r\n
        # See: http://rhea.redhat.com/bboard-archive/webdb/000bfF.html
        set value [string map [list \r ""] $value]
        set org_computed_hash $computed_hash
        set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

        if {$computed_hash eq $hash} {
            ns_log Debug "__ad_verify_signature: Hash matches after correcting for IE bug - Hash check OK"
            set hash_ok_p 1
        } else {
            ns_log Debug "__ad_verify_signature: Hash ($hash) doesn't match what we expected ($org_computed_hash) - Hash check FAILED"
        }
    }

    if { $expire_time == 0 } {
        ns_log Debug "__ad_verify_signature: No expiration time - Expiration OK"
        set expiration_ok_p 1
    } elseif { $expire_time > [ns_time] } {
        ns_log Debug "__ad_verify_signature: Expiration time ($expire_time) greater than current time ([ns_time]) - Expiration check OK"
        set expiration_ok_p 1
    } else {
        ns_log Debug "__ad_verify_signature: Expiration time ($expire_time) less than or equal to current time ([ns_time]) - Expiration check FAILED"
    }

    # Return validation result
    return [expr {$hash_ok_p && $expiration_ok_p}]

}

ad_proc -public ad_get_signed_cookie {
    {-include_set_cookies t}
    {-secret ""}
    name
} {

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and ensures that the cookie has not
    expired. Throws an exception if validation fails.

} {

    set cookie_value [ad_get_cookie -include_set_cookies $include_set_cookies $name]
    if { $cookie_value eq "" } {
        error "Cookie does not exist."
    }

    lassign $cookie_value value signature
    ns_log $::security::log(login_cookie) "ad_get_signed_cookie: Got signed cookie $name with value $value, signature $signature."

    if { [ad_verify_signature -secret $secret $value $signature] } {
        ns_log $::security::log(login_cookie) "ad_get_signed_cookie: Verification of cookie $name OK"
        return $value
    }

    ns_log $::security::log(login_cookie) "ad_get_signed_cookie: Verification of cookie $name FAILED"
    error "Cookie could not be authenticated."
}

ad_proc -public ad_get_signed_cookie_with_expr {
    {-include_set_cookies t}
    {-secret ""}
    name
} {

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and ensures that the cookie has not
    expired. Returns a two-element list, the first element of which is
    the cookie data, and the second element of which is the expiration
    time. Throws an exception if validation fails.

} {

    set cookie_value [ad_get_cookie -include_set_cookies $include_set_cookies $name]

    if { $cookie_value eq "" } {
        error "Cookie does not exist."
    }

    lassign $cookie_value value signature
    set expr_time [ad_verify_signature_with_expr -secret $secret $value $signature]

    ns_log Debug "Security: Done calling get_cookie $cookie_value for $name; received $expr_time expiration, getting $value and $signature."

    if { $expr_time } {
        return [list $value $expr_time]
    }

    error "Cookie could not be authenticated."
}

ad_proc -public ad_set_signed_cookie {
    {-replace f}
    {-secure f}
    {-expire f}
    {-discard f}
    {-scriptable f}
    {-max_age ""}
    {-signature_max_age ""}
    {-domain ""}
    {-path "/"}
    {-secret ""}
    {-token_id ""}
    name
    value
} {

    Sets a signed cookie. Negative token_ids are reserved for secrets
    external to the signed cookie mechanism. If a token_id is
    specified, a secret must be specified.

    @author Richard Li (richardl@arsdigita.com)
    @creation-date 18 October 2000

    @param max_age specifies the maximum age of the cookies in
    seconds (consistent with RFC 2109). max_age inf specifies cookies
    that never expire. (see ad_set_cookie). The default is session
    cookies.

    @param secret allows the caller to specify a known secret external
    to the random secret management mechanism.

    @param token_id allows the caller to specify a token_id.

    @param scriptable allow access to the cookie from JavaScript

    @param value the value for the cookie. This is automatically
    url-encoded.

} {
    if { $signature_max_age eq "" } {
        if { $max_age eq "inf" } {
            set signature_max_age ""
        } elseif { $max_age ne "" } {
            set signature_max_age $max_age
        } else {
            # this means we want a session level cookie,
            # but that is a user interface expiration, that does
            # not give us a security expiration. (from the
            # security perspective, we use SessionLifetime)
            ns_log Debug "Security: SetSignedCookie: Using sec_session_lifetime [sec_session_lifetime]"
            set signature_max_age [sec_session_lifetime]
        }
    }

    set cookie_value [ad_sign -secret $secret -token_id $token_id -max_age $signature_max_age $value]
    set data [list $value $cookie_value]

    ad_set_cookie \
        -replace $replace \
        -secure $secure \
        -discard $discard \
        -scriptable $scriptable \
        -expire $expire \
        -max_age $max_age \
        -domain $domain \
        -path $path \
        $name $data
}





#####
#
# Token generation and handling
#
#####

ad_proc -private sec_get_token {
    token_id
} {

    Returns the token corresponding to the token_id. This first checks
    the thread-persistent Tcl cache, then checks the server
    size-limited cache before finally hitting the db in the worst case
    if the secret_token value is not in either cache. The procedure
    also updates the caches.

    Cache eviction is handled by the ns_cache API for the size-limited
    cache and is handled by AOLserver (via thread termination) for the
    thread-persistent Tcl cache.

} {

    set key ::security::tcl_secret_tokens($token_id)
    if { [info exists $key] } { return [set $key] }

    if {[array size ::security::tcl_secret_tokens] == 0} {
        populate_secret_tokens_thread_cache
        if { [info exists $key] } { return [set $key] }
    }

    #
    # We might get token_ids from previous runs, so we have fetch these
    # in case of a validation
    #
    set token [ns_cache eval secret_tokens $token_id {
        set token [db_string get_token {select token from secret_tokens
            where token_id = :token_id} -default 0]
        db_release_unused_handles

        # Very important to throw the error here if $token == 0

        if { $token == 0 } {
            error "Invalid token ID"
        }

        return $token
    }]

    set $key $token
    return $token
}

ad_proc -private sec_get_random_cached_token_id {} {

    Randomly returns a token_id from the token cache

} {
    #set list_of_names [ns_cache names secret_tokens]
    set list_of_names [array names ::security::tcl_secret_tokens]
    if {[llength $list_of_names] == 0} {
        populate_secret_tokens_thread_cache
        set list_of_names [array names ::security::tcl_secret_tokens]
    }

    set random_seed [ns_rand [llength $list_of_names]]
    return [lindex $list_of_names $random_seed]
}

ad_proc -private populate_secret_tokens_thread_cache {} {

    Copy secret_tokens cache to per-thread variables

} {
    set ids [ns_cache names secret_tokens]
    if {[llength $ids] == 0} {
        populate_secret_tokens_cache
        set ids [ns_cache names secret_tokens]
    }
    foreach name $ids {
        set ::security::tcl_secret_tokens($name) [ns_cache get secret_tokens $name]
    }
}

ad_proc -private populate_secret_tokens_cache {} {

    Randomly populates the secret_tokens cache.

} {

    set num_tokens [parameter::get -package_id [ad_acs_kernel_id] -parameter NumberOfCachedSecretTokens -default 100]

    # this is called directly from security-init.tcl,
    # so it runs during the install before the data model has been loaded
    if { [db_table_exists secret_tokens] } {
        db_foreach get_secret_tokens {} {
            ns_cache set secret_tokens $token_id $token
        }
    }
    db_release_unused_handles
}

ad_proc -private populate_secret_tokens_db {} {

    Populates the secret_tokens table. Note that this will take a while
    to run.

} {

    set num_tokens [parameter::get -package_id [ad_acs_kernel_id] -parameter NumberOfCachedSecretTokens -default 100]
    # we assume sample size of 10%.
    set num_tokens [expr {$num_tokens * 10}]
    set counter 0
    set list_of_tokens [list]

    # the best thing to use here would be an array_dml, except
    # that an array_dml makes it hard to use sysdate and sequences.
    while { $counter < $num_tokens } {
        set random_token [sec_random_token]

        db_dml insert_random_token {}
        incr counter
    }

    db_release_unused_handles
}




#####
#
# Client property procs
#
#####

ad_proc -private sec_lookup_property {
    id
    module
    name
} {

    Used as a helper procedure for util_memoize to look up a
    particular property from the database.

    @return empty, when no property is recorded or a list containing property_value and secure_p

} {
    if {
        ![db_0or1row property_lookup_sec {
            select property_value, secure_p
            from sec_session_properties
            where session_id = :id
            and module = :module
            and property_name = :name
        }]
    } {
        return ""
    }

    set new_last_hit [clock seconds]

    db_dml update_last_hit_dml {
        update sec_session_properties
        set last_hit = :new_last_hit
        where session_id = :id and
        property_name = :name
    }

    return [list $property_value $secure_p]
}

ad_proc -public ad_get_client_property {
    {-cache t}
    {-cache_only f}
    {-default ""}
    {-session_id ""}
    module
    name
} {
    Looks up a property for a session. If -cache is true, will use the
    cached value if available. If -cache_only is true, will never
    incur a database hit (i.e., will only return a value if
    cached). If the property is secure, we must be on a validated session
    over HTTPS.

    @param session_id controls which session is used
    @param module typically the name of the package to which the property
           belongs (serves as a namespace)
    @param name name of the property
    @return value of the property or default

    @see ad_set_client_property
} {
    if { $session_id eq "" } {
        set id [ad_conn session_id]
        #
        # If session_id is still undefined in the connection then just
        # return the default.
        #
        if { $id eq "" } {
            return $default
        }
    } else {
        set id $session_id
    }

    set cmd [list sec_lookup_property $id $module $name]

    if { $cache_only == "t" && ![util_memoize_cached_p $cmd] } {
        return $default
    }

    if { $cache != "t" } {
        util_memoize_flush $cmd
    }

    set property [util_memoize $cmd [sec_session_timeout]]
    if { $property eq "" } {
        return $default
    }
    lassign $property value secure_p

    if { $secure_p != "f" && ![security::secure_conn_p] } {
        return $default
    }

    return $value
}

ad_proc -public ad_set_client_property {
    {-clob f}
    {-secure f}
    {-persistent t}
    {-session_id ""}
    module
    name
    value
} {
    Sets a client (session-level) property. If -persistent is true,
    the new value will be written through to the database (it will
    survive a server restart, bit it will be slower). If -secure is true,
    the property will not be retrievable except via a validated,
    secure (HTTPS) connection.

    @param session_id controls which session is used
    @param clob tells us to use a large object to store the value
    @param module typically the name of the package to which the property
           belongs (serves as a namespace)
    @param name name of the property
    @param value value if the property

    @see ad_get_client_property
} {

    if { $secure != "f" && ![security::secure_conn_p] } {
        error "Unable to set secure property in insecure or invalid session"
    }

    if { $session_id eq "" } {
        set session_id [ad_conn session_id]
    }

    if { $persistent == "t" } {
        # Write to database - either defer, or write immediately. First delete the old
        # value if any; then insert the new one.

        set last_hit [ns_time]

        if { $clob == "t" } {

            db_transaction {

                # DRB: Older versions of this code did a delete/insert pair in an attempt
                # to guard against duplicate insertions.  This didn't work if there was
                # no value for this property in the table and two transactions ran in
                # parallel.  The problem is that without an existing row the delete had
                # nothing to lock on, thus allowing the two inserts to conflict.  This
                # was discovered on a page built of frames, where the two requests from
                # the browser spawned two AOLserver threads to service them.

                # Oracle doesn't allow a RETURNING clause on an insert with a
                # subselect, so this code first inserts a dummy value if none exists
                # (ensuring it does exist afterwards) then updates it with the real
                # value.  Ugh.

                set clob_update_dml [db_map prop_update_dml_clob]

                db_dml prop_insert_dml ""

                if { $clob_update_dml ne "" } {
                    db_dml prop_update_dml_clob "" -clobs [list $value]
                } else {
                    db_dml prop_update_dml ""
                }
            }
        } else {
            #
            # Perform an upsert operation via stored procedure
            #
            db_exec_plsql prop_upsert {}
        }
    }

    # Remember the new value, seeding the memoize cache with the proper value.
    util_memoize_seed [list sec_lookup_property $session_id $module $name] [list $value $secure]
}



#####
#
# security namespace public procs
#
#####

ad_proc -public security::https_available_p {} {
    Return 1 if server is configured to support HTTPS and 0 otherwise.

    @author Peter Marklund
} {
    return [expr {[get_https_port] ni {"" 0}}]
}

ad_proc -public security::secure_conn_p {} {
    Returns true if the connection [ad_conn] is secure (HTTPS), or false otherwise.
} {
    # interestingly, "string match" is faster than "string range" + "eq"

    return [string match "https:*" [ns_conn location]]
}

ad_proc -public security::RestrictLoginToSSLP {} {
    Return 1 if login pages and other pages taking user password
    should be restricted to a secure (HTTPS) connection and 0 otherwise.
    Based on acs-kernel parameter with same name.

    @author Peter Marklund
} {
    if { ![security::https_available_p] } {
        return 0
    }
    return [parameter::get \
                -boolean \
                -parameter RestrictLoginToSSLP \
                -package_id [ad_acs_kernel_id]]
}

ad_proc -public security::require_secure_conn {} {
    Redirect back to the current page in secure mode (HTTPS) if
    we are not already in secure mode.
    Does nothing if the server is not configured for HTTPS support.

    @author Peter Marklund
} {
    if { [https_available_p] } {
        if { ![security::secure_conn_p] } {
            security::redirect_to_secure [ad_return_url -qualified]
        }
    }
}

ad_proc -public security::redirect_to_secure {
    {-script_abort:boolean true}
    url
} {
    Redirect to the given URL and enter secure (HTTPS) mode.
    Does nothing if the server is not configured for HTTPS support.

    @author Peter Marklund
} {
    if { [https_available_p] } {
        set secure_url [get_secure_qualified_url $url]
        ns_set put [ad_conn outputheaders] Vary "Upgrade-Insecure-Requests"
        #ns_log notice "redirect $url to secure url $secure_url"
        ad_returnredirect $secure_url
        if {$script_abort_p} {ad_script_abort}
    }
}

ad_proc -public security::redirect_to_insecure {
    url
} {
    Redirect to the given URL and enter insecure (HTTP) mode.

    @author Peter Marklund
} {
    set insecure_url [get_insecure_qualified_url $url]

    ad_returnredirect $insecure_url
    ad_script_abort
}

#####
#
# security namespace private procs
#
#####

ad_proc -private security::get_https_port {} {
    Return the HTTPS port specified in the server's config file.

    @return The HTTPS port number or the empty string if none is configured.

    @author Gustaf Neumann
} {
    # get secure driver server modules
    set sdriver [security::driver]

    if {$sdriver ne ""} {
        set d [util_driver_info -driver $sdriver]
        return [dict get $d port]
    }
}

ad_proc -private security::get_http_port {} {
    Return the HTTP port specified in the server's config file.

    @return The HTTP port number or the empty string if none is configured.

    @author Gustaf Neumann
} {
    set d [util_driver_info -driver nssock]
    return [dict get $d port]
}


ad_proc -private security::get_qualified_url { url } {
    @return secure or insecure qualified url
} {
    if { [security::secure_conn_p] || [ad_conn behind_secure_proxy_p] } {
        set qualified_url [security::get_secure_qualified_url $url]
    } else {
        set qualified_url [security::get_insecure_qualified_url $url]
    }
    return $qualified_url
}


ad_proc -private security::get_secure_qualified_url { url } {
    Given a relative or qualified url, return the fully qualified
    HTTPS version.

    @author Peter Marklund
} {
    set qualified_uri [get_qualified_uri_part $url]
    set secure_url [get_secure_location]${qualified_uri}

    return $secure_url
}

ad_proc -private security::get_insecure_qualified_url { url } {
    Given a relative or qualified url, return the fully qualified
    HTTP version.

    @author Peter Marklund
} {
    # Get part of URL after location
    set qualified_uri [get_qualified_uri_part $url]

    set insecure_url [get_insecure_location]${qualified_uri}

    return $insecure_url
}

ad_proc -private security::get_uri_part { url } {
    Get the URI following the location of the given URL. Assumes
    the given URL has the "http" or "https" protocol or is a relative
    URL.

    @author Peter Marklund
} {
    regexp {^(?:http[s]?://[^/]+)?(.*)} $url match uri

    return $uri
}

ad_proc -private security::get_qualified_uri_part { url } {

} {
    set uri [get_uri_part $url]

    if { [string index $uri 0] ne "/" } {
        # Make relative URI qualified
        return [ad_conn url]/$uri
    }

    return $uri
}

ad_proc -private security::get_secure_location {} {
    Return the current location in secure (https) mode.

    @author Peter Marklund
} {
    set current_location [util_current_location]

    if { [regexp {^https://} $current_location] } {
        #
        # Current location is already secure - do nothing
        #
        set secure_location $current_location
    } elseif {[util::split_location $current_location proto hostname port]} {
        #
        # Do not return a location with a port number, when
        # SuppressHttpPort is set.
        #
        set suppress_http_port [parameter::get -parameter SuppressHttpPort \
                                    -package_id [apm_package_id_from_key acs-tcl] \
                                    -default 0]
        set secure_location [util::join_location \
                                 -proto https \
                                 -hostname $hostname \
                                 -port [expr {$suppress_http_port ? "" : [security::get_https_port]}]]
    } else {
        error "invalid location $current_location"
    }

    return $secure_location
}

ad_proc -private security::get_insecure_location {} {
    Return the current location in insecure mode (http).

    @author Peter Marklund
} {
    set current_location [util_current_location]
    set http_prefix {http://}

    if { [string match "$http_prefix*" $current_location] } {
        #
        # Current location is already insecure - do nothing
        #
        set insecure_location $current_location
    } elseif {[util::split_location $current_location proto hostname port]} {
        #
        # Do not return a location with a port number, when
        # SuppressHttpPort is set.
        #
        set suppress_http_port [parameter::get -parameter SuppressHttpPort \
                                    -package_id [apm_package_id_from_key acs-tcl] \
                                    -default 0]
        set insecure_location [util::join_location \
                                   -proto http \
                                   -hostname $hostname \
                                   -port [expr {$suppress_http_port ? "" : [security::get_http_port]}]]
    } else {
        error "invalid location $current_location"
    }

    return $insecure_location
}

if {[ns_info name] ne "NaviServer"} {
    #
    # Compatibility function for AOLserver, which allows abstracts
    # from the configuration section in the config files. NaviServer
    # supports in general global and per-server defined drivers. The
    # emulated version just supports per-server configurations, since
    # these are the only ones supported by AOLserver.
    #
    ad_proc -public ns_driversection {
        {-driver "nssock"}
        {-server ""}
    } {
        Return the section name in the config file containing configuration information about the
        network connection.
        @param driver (e.g. nssock)
        @param server symobolic server name
        @return name of section of the drive in the config file
    } {
        if {$server eq ""} {set server [ns_info server]}
        return "ns/server/$server/module/$driver"
    }
}

ad_proc -public ad_server_modules {} {
    Return the list of the available server modules
    @author Gustaf Neumann
} {
    if {[info exists ::acs::server_modules]} {
        return $::acs::server_modules
    }
    set ::acs::server_modules ""
    set nssets [ns_configsection ns/server/[ns_info server]/modules]
    lappend nssets {*}[ns_configsection ns/modules]
    foreach nsset $nssets {
        foreach {module file} [ns_set array $nsset] {
            if {$file ne ""} {
                lappend ::acs::server_modules $module
            }
        }
    }
    return $::acs::server_modules
}

ad_proc -public security::driver {} {
    Return the secure driver if available
    @author Gustaf Neumann
} {
    if {[info exists ::acs::sdriver]} {
        return $::acs::sdriver
    }
    set ::acs::sdriver ""
    set server_modules [ad_server_modules]
    foreach driver {nsssl nsssl_v4 nsssl_v6 nsopenssl nsssle} {
        if {$driver ni $server_modules} continue
        set ::acs::sdriver $driver
        break
    }
    return $::acs::sdriver
}

if {[info commands ns_driver] ne ""} {

    ad_proc -private security::configured_driver_info {} {

        Return a list of dicts containing type, driver, location and port
        of all configured drivers

        @see util_driver_info

    } {
        set defaultport {http 80 https 433}
        set result {}
        foreach i [ns_driver info] {
            set type     [dict get $i type]
            set location [dict get $i location]
            set proto    [dict get $i protocol]
            set li       [ns_parseurl $location]

            if {[dict exists $li port]} {
                set port [dict get $li port]
                set suffix ":$port"
            } else {
                set port [dict get $defaultport $proto]
                set suffix ""
            }
            lappend result [list \
                                proto $proto \
                                driver [dict get $i module] \
                                host [dict get $li host] \
                                location $location port $port suffix $suffix]
        }
        return $result
    }

} else {

    ad_proc -private security::configured_driver_info {} {
        set result ""
        #
        # Find the first insecure driver based on driver names from
        # recommended config files
        #
        foreach driver {nssock nssock_v4 nssock_v6} {
            set driver_section [ns_driversection -driver $driver]
            if {$driver_section ne ""} {

                set location [ns_config $driver_section location]
                if {$location ne "" && [util::split_location $location proto host port]} {
                    lappend result [list proto http driver $driver host $host \
                                        location $location port $port suffix $suffix]
                }

                set host [ns_config $driver_section hostname]
                if {$host eq ""} {
                    set host [ns_config $driver_section address]
                    if {[string match "*:*" $host]} {
                        set host "\[$host\]"
                    }
                }
                set location "http://$host"

                set port [ns_config -int $driver_section port 80]
                if { $port ne "" && $port != 80 } {
                    set suffix ":$port"
                    append location $suffix
                } else {
                    set port 80
                    set suffix ""
                }
                lappend result [list proto http driver $driver host $host \
                                    location $location port $port suffix $suffix]
            }
        }

        #
        # Obtain information about secure locations.
        #
        set sdriver [security::driver]

        # nsopenssl 3 has variable locations for the secure
        # port, OpenACS standardized at:

        if { $sdriver eq "nsopenssl" } {
            set port [ns_config -int "ns/server/[ns_info server]/module/$sdriver/ssldriver/users" port 443]
            set host [ns_config "ns/server/[ns_info server]/module/$sdriver/ssldriver/users" hostname]

        } elseif { $sdriver ne "" } {
            # get secure port for all other cases of nsssl, nsssle etc
            set driver_section [ns_driversection -driver $sdriver]
            set host [ns_config $driver_section hostname]
            if {$host eq ""} {
                set host [ns_config $driver_section address]
                if {[string match "*:*" $host]} {
                    set host "\[$host\]"
                }
            }
            set port [ns_config -int $driver_section port]

            # checking nsopenssl 2.0 which has different names for
            # the secure port etc, and deprecated with this version of OpenACS
            if {$port eq ""} {
                set port [ns_config -int $driver_section ServerPort 443]
                if {$port ne ""} {
                    ns_log Warning "Using 'ServerPort' in config file in $driver_section is deprecated (use 'port' instead)"
                }
            }
        } else {
            set port ""
        }

        if {$sdriver ne ""} {
            set location "https://$host"
            if {$port eq "" || $port eq "443" } {
                set suffix ""
            } else {
                set suffix ":$port"
                append location $suffix
            }

            lappend result [list proto https driver $sdriver host $host \
                                location $location port $port suffix $suffix]
        }
        return $result
    }
}

ad_proc -public security::locations {} {

    This function returns the configured locations and the current
    location and the vhost locations, potentially in HTTP or in HTTPs
    variants.

    When the package parameter "SuppressHttpPort" of acs-tcl parameter
    is true, then an alternate location without a port is included.
    This proc also assumes hostnames from host_node_map table are
    accurate and legit.

    The term location refers to protocol://domain:port for
    website.

    @return insecure location and secure location followed possibly by alternate location(s) as a list.

} {
    set locations [list]
    set portless_locations {}
    #
    # Get Information from configured servers
    #
    set driver_info [security::configured_driver_info]
    foreach d $driver_info {
        #
        # port == 0 means that the driver is just used for sending, but not for receiveing
        #
        if {[dict get $d port] != 0} {
            set location [dict get $d location]
            if {$location ni $locations} {lappend locations $location}

            set location [dict get $d proto]://[dict get $d host]
            if {$location ni $portless_locations &&
                $location ni $locations} {
                lappend portless_locations $location
            }
            append location :[dict get $d port]
            if {$location ni $locations} {lappend locations $location}
        }
    }

    if {[ns_conn isconnected]} {
        #
        # Is the current connection secure?
        #
        set secure_conn_p [security::secure_conn_p]

        set current_location [util_current_location]
        if {$current_location ni $locations} {
            lappend locations $current_location
        }

        #
        # When we are on a secure connection, the command above added
        # already a secure connection. When we are on a nonsecure
        # connection, but HTTPS is available, allow as well the
        # current host via the secure connection.
        #
        if {!$secure_conn_p && [https_available_p]} {
            set secure_current_location [security::get_secure_location]
            #ns_log notice "ADD secure_current_location: <$secure_current_location>"
            if {$secure_current_location ni $locations} {
                lappend locations $secure_current_location
            }
        }
    } else {
        set secure_conn_p 0
    }

    #
    # Consider if we are behind a proxy and don't want to publish the
    # proxy's backend port. In this cases, SuppressHttpPort can be used
    #
    set suppress_http_port [parameter::get -parameter SuppressHttpPort \
                                -package_id [apm_package_id_from_key acs-tcl] \
                                -default 0]
    if {$suppress_http_port} {
        lappend locations {*}$portless_locations
    }


    #
    # Add locations from host_node_map
    #
    set host_node_map_hosts_list [db_list -cache_key security-locations-host-names \
                                      get_node_host_names {select host from host_node_map}]

    if { [llength $host_node_map_hosts_list] > 0 } {
        if { $suppress_http_port } {
            foreach hostname $host_node_map_hosts_list {
                lappend locations "http://${hostname}"
                if {$secure_conn_p} {
                    lappend locations "https://${hostname}"
                }
            }
        } else {
            foreach hostname $host_node_map_hosts_list {
                foreach d $driver_info {
                    if {[dict get $d proto] eq "http"} {
                        lappend locations "http://${hostname}[dict get $d suffix]"
                    }
                }
                if {$secure_conn_p} {
                    foreach d $driver_info {
                        if {[dict get $d proto] eq "https"} {
                            lappend locations "https://${hostname}[dict get $d suffix]"
                        }
                    }
                }
            }
        }
    }
    #ns_log notice "security::locations <$locations>"
    return $locations
}


ad_proc -public security::validated_host_header {} {
    @return validated host header field or empty
    @author Gustaf Neumann

    Protect against faked or invalid host header fields. Host header
    attacks can lead to web-cache poisoning and password reset attacks
    (for more details, see e.g.
     http://www.skeletonscribe.net/2013/05/practical-http-host-header-attacks.html)
} {
    #
    # Check, if we have a host header field
    #
    set host [ns_set iget [ns_conn headers] Host]
    if {$host eq ""} {
        return ""
    }

    #
    # Check, if we have validated it before, or it belongs to the
    # predefined accepted host header fields.
    #
    set key ::acs::validated($host)
    if {[info exists $key]} {
        return $host
    }

    if {![string match *//* $host]} {
        set splithost [ns_conn protocol]://$host
    } else {
        set splithost $host
    }
    if {![util::split_location $splithost .proto hostName hostPort]} {
        return ""
    }

    #
    # Remove trailing dot, as this is allowed in fully qualified DNS
    # names (see e.g. §3.2.2 of RFC 3976).
    #
    set hostName [string trimright $hostName .]

    #
    # Check, if the provided host is the same as the configured host
    # name for the current driver or one of its IP addresses. Should
    # be true in most cases.
    #
    set driverInfo [util_driver_info]
    set driverHostName [dict get $driverInfo hostname]
    if {$hostName eq $driverHostName || $hostName in [ns_addrbyhost -all $driverHostName]} {
        #
        # port is currently ignored
        #
        set $key 1
        return $host
    }

    #
    # Check, if the provided host is the same in [ns_conn location]
    # (will be used as default, but we do not want a warning in such
    # cases).
    #
    if {[util::split_location [ns_conn location] proto locationHost locationPort]} {
        if {$hostName eq $locationHost} {
            #
            # port is currently ignored
            #
            set $key 1
            return $host
        }
    }

    #
    # Check, if the provided host is the same as in the configured
    # SystemURL.
    #
    if {[util::split_location [ad_url] .proto systemHost systemPort]} {
        if {$hostName eq $systemHost
            && ($hostPort eq $systemPort || $hostPort eq "") } {
            set $key 1
            return $host
        }
    }

    #
    # Check against the virtual server configuration of NaviServer.
    #
    if {[ns_info name] eq "NaviServer"} {
        set s [ns_info server]
        set driverInfo [security::configured_driver_info]
        set drivers [lmap d $driverInfo {dict get $d driver}]

        foreach driver $drivers {
            #
            # Check global "servers" configuration for virtual servers for the driver
            #
            set ns [ns_configsection ns/module/$driver/servers]
            if {$ns ne ""} {
                #
                # We have a global "servers" configuration for the driver
                #
                set names [lmap {key value} [ns_set array $ns] {
                    if {$key ne $s} continue
                    set value
                }]
                if {$host in $names} {
                    ns_log notice "security::validated_host_header: found $host via global virtual server configuration for $driver"
                    set $key 1
                    return $host
                }
            }
        }
    }

    #
    # Check against host node map. Here we need as well protection
    # against invalid utf-8 characters.
    #
    if {![regexp {^[\w.:@+/=$%!*~\[\]-]+$} $host]} {
        ns_log Warning "host header field contains invalid characters: $host"
        return ""
    }
    set result [db_list host_header_field_mapped {select 1 from host_node_map where host = :hostName}]
    #ns_log notice "security::validated_host_header: checking entry <$hostName> from host_node_map -> $result"

    if {$result == 1} {
        #
        # port is ignored
        #
        set $key 1
        #ns_log notice "security::validated_host_header: checking entry <$hostName> from host_node_map return host <$host>"
        return $host
    }

    #
    # Handle aliases for locations, which cannot be determined from
    # config files, but which are supposed to be ok.
    #
    if {$hostName eq "localhost"} {
        #
        # This is not an attempt, where someone tries to lure us to a
        # different host via redirect.
        #
        set $key 1
        return $host
    }

    #
    # We could/should check as well against a white-list of additional
    # host names (maybe via ::acs::validated, or via config file, or
    # via additional package parameter). Probably the best way is to
    # get alternate (alias) names from the driver section of the
    # current driver [ns_conn driver] (maybe check global and local).
    #
    #ns_set array [ns_configsection ns/module/nssock/servers]

    #
    # Now we give up
    #
    ns_log warning "ignore untrusted host header field: '$host'"

    return ""
}

namespace eval ::security::csp {

    #
    # Generate a nonce token as described in W3C Content Security Policy
    # https://www.w3.org/TR/CSP/
    #
    ad_proc -public ::security::csp::nonce { {-tokenname __csp_nonce} } {

        Generate a Nonce token and return it. The nonce token can be used
        in content security policies (CSP2) for "script" and "style"
        elements. Desired Properties: generate a single unique value per
        request which is hard for a hacker to predict, it should only
        contain base64 characters (so hex is fine).

        For details, see https://www.w3.org/TR/CSP/

        @return nonce token
        @author Gustaf Neumann
    } {
        #
        # Compute the nonce value only once per requests. If it was
        # already computed, pick it up and return the precomputed
        # value. Otherwise, compute the value new.
        #
        set globalTokenName ::$tokenname
        if {[info exists $globalTokenName]} {
            set token [set $globalTokenName]
        } else {
            if {![ns_conn isconnected]} {
                #
                # Must be a background job, take the address
                #
                set session_id [ns_info address]
            } else {
                #
                # Anonymous request, use a peer address as session_id
                #
                set session_id [ad_conn peeraddr]
            }
            set secret [ns_config "ns/server/[ns_info server]/acs" parametersecret ""]

            if {[info commands ::crypto::hmac] ne ""} {
                set token  [::crypto::hmac string $secret $session_id-[clock clicks -microseconds]]
            } else {
                set token  [ns_sha1 "$secret-$session_id-[clock clicks -microseconds]"]
            }
            set $globalTokenName $token
        }
        return $token
    }

    # security::csp::require style-src 'unsafe-inline'
    ad_proc -public ::security::csp::require {{-force:boolean} directive value} {

        Add a single value directive to the CSP rule-set. The
        directives are picked up, when the page is rendered, by the
        CSP generator.

        @param directive name of the directive (such as e.g. style-src)
        @param value allowed source for this page (such as e.g. unsafe-inline)

        @author Gustaf Neumann
        @see    security::csp::render
    } {
        set var ::__csp__directive($directive)
        if {![info exists $var] || $value ni [set $var]} {
            lappend $var $value
        }
        if {$force_p} {
            ns_log notice "CSP: forcing $directive $value"
            set var ::__csp__directive_forced($directive)
            if {![info exists $var] || $value ni [set $var]} {
                lappend $var $value
            }
        }
    }

    ad_proc -public ::security::csp::render {} {

        This is the CSP generator. Collect the specified directives
        and build from these directives the full CSP specification for
        the current page.

        @author Gustaf Neumann
        @see    security::csp::require
    } {
        #
        # Fetch the nonce token
        #
        set nonce [::security::nonce_token]

        #
        # Add 'self' rules
        #
        security::csp::require default-src 'self'
        security::csp::require script-src 'self'
        security::csp::require style-src 'self'
        security::csp::require img-src 'self'
        security::csp::require font-src 'self'
        security::csp::require base-uri 'self'

        #
        # Some browser (safari, chrome) need "font-src data:", maybe
        # for plugins or diffent font settings. Seems safe enough.
        #
        security::csp::require font-src data:

        #
        # Always add the nonce-token to script-src. Note, that nonce
        # definition comes via CSP 2, which - at the current time - is
        # not supported by all browsers interpreting CSPs. We could
        # add a "unsafe-inline" here, since the spec defines that when
        # 'unsafe-inline' and a 'nonce-source' is used, the
        # 'unsafe-inline'" will have no effect
        # (https://w3c.github.io/webappsec-csp/ § 6.6.2.2.). However,
        # some security checkers just look for 'unsafe-inline' and
        # downgrade the rating without honoring the 'nonce-src'.
        #
        # Another problem is mixed content. When we set the nonce-src
        # and 'unsafe-inline', and a browser honoring nonces ignores
        # the 'unsafe-inline', but some JavaScript framework requires
        # it (e.g ckeditor4), we have a problem. Therefore, an
        # application can force "'unsafe-inline'" which means that we
        # do not set the nonce-src in such cases.
        #
        if {![info exists ::__csp__directive_forced(script-src)]
            || "'unsafe-inline'" ni $::__csp__directive_forced(script-src)
        } {
            security::csp::require script-src 'nonce-$nonce'
        }

        # We need for the time being 'unsafe-inline' for style-src,
        # otherwise not even the style attribute (e.g. <p
        # style="...">) would be allowed.
        #
        security::csp::require style-src 'unsafe-inline'

        #
        # Define a report URI to ease debugging. CSP 3 will support a
        # "report-to" directive, but will still support "report-uri".
        #
        security::csp::require report-uri /SYSTEM/csp-collector.tcl

        #
        # We do not need object-src
        #
        security::csp::require object-src 'none'

        set policy ""
        foreach directive {
            child-src
            connect-src
            default-src
            font-src
            form-action
            frame-src
            frame-ancestors
            img-src
            media-src
            object-src
            plugin-types
            report-uri
            sandbox
            script-src
            style-src
            base-uri
        } {
            set var ::__csp__directive($directive)
            if {[info exists $var]} {
                append policy "$directive [join [set $var] { }];"
            }
        }
        return $policy
    }

}

#TODO remove me: just for a transition phase
proc ::security::nonce_token args {uplevel ::security::csp::nonce {*}$args}


namespace eval ::security::csrf {

    #
    # CSRF protection.
    #
    # High Level commands:
    #
    #    security::csrf::new
    #    security::csrf::validate

    ad_proc -public ::security::csrf::new {{-tokenname __csrf_token} -user_id} {

        Create a security token to protect against CSRF (Cross-Site
        Request Forgery).  The token is set (and cached) in a global
        per-thread variable an can be included in forms e.g. via the
        following command.

        <if @::__csrf_token@ defined><input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"></if>

        The token is automatically cleared together with other global
        variables at the end of the processing of every request.

        @return csrf token

        @author Gustaf Neumann
    } {
        set globalTokenName ::$tokenname
        if {[info exists $globalTokenName] && [set $globalTokenName] ne ""} {
            return [set $globalTokenName]
        }

        set token [token -tokenname $tokenname]
        return [set $globalTokenName $token]
    }

    #
    # validate
    #
    ad_proc -public ::security::csrf::validate {{-tokenname __csrf_token} {-allowempty false}} {

        Validate a CSRF token and call security::csrf::fail the request if
        invalid.

        @return nothing
    } {
        if {![info exists ::$tokenname] || ![ns_conn isconnected]} {
            #
            # If there is no global csrf token, or we are not in a
            # connection thread, we accept everything.  If there is
            # not csrf token, we assume, that its generation is
            # deactivated,
            #
            return
        }

        set oldToken [ns_queryget $tokenname]
        if {$oldToken eq ""} {
            #
            # There is not token in the query/form parameters, we
            # can't validate, since there is no token.
            #
            if {$allowempty} {
                return
            }
            fail
        }

        set token [token -tokenname $tokenname]
        if {$oldToken ne $token} {
            fail
        }
    }

    #
    # Compute a session id or the best equivalent
    #
    ad_proc -private ::security::csrf::session_id { } {

        Return an ID for the current session for CSRF protection

        @return session ID
    } {
        if {![ns_conn isconnected]} {
            #
            # Must be a background job, take the address
            #
            set session_id [ns_info address]
        } elseif {[ad_conn untrusted_user_id] == 0} {
            #
            # Anonymous request, use a peer address as session_id
            #
            set session_id [ad_conn peeraddr]
        } else {
            #
            # User is logged in, use a session token.
            #
            set session_id [ad_conn session_id]
        }
        return $session_id
    }

    #
    # Generate CSRF token
    #
    ad_proc -public ::security::csrf::token { {-tokenname __csrf_token} } {

        Generate a CSRF token and return it

        @return CSRF token
        @author Gustaf Neumann
    } {
        #
        # We compute the token only once per requests. If it was already
        # computed, and we can pick it up and return it. Otherwise,
        # we compute it new.
        #
        set globalTokenName ::$tokenname
        if {[info exists $globalTokenName] && [set $globalTokenName] ne ""} {
            set token [set $globalTokenName]
        } else {
            set secret [ns_config "ns/server/[ns_info server]/acs" parametersecret ""]
            if {[info commands ::crypto::hmac] ne ""} {
                set token [::crypto::hmac string $secret [session_id]]
            } else {
                set token [ns_sha1 $secret-[session_id]]
            }
            set $globalTokenName $token
        }

        return $token
    }

    #
    # Failure handling
    #
    ad_proc -private ::security::csrf::fail {} {

        This function is called, when a csrf validation fails. Unless the
        current user is swa, it aborts the current request.

    } {
        ad_log Warning "CSRF failure"
        if {[acs_user::site_wide_admin_p]} {
            ns_log notice "would abort if not swa: [ns_conn request]"
        } else {
            ad_page_contract_handle_datasource_error "Invalid request token (potential Cross-Site Request Forgery)"
            ad_script_abort
        }
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
