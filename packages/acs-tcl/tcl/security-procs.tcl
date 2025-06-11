ad_library {

    Provides methods for authorizing and identifying ACS users
    (both logged-in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @author Richard Li (richardl@arsdigita.com)
    @author Archit Shah (ashah@arsdigita.com)
    @cvs-id $Id$
}

namespace eval security {
    #set log(login_url) notice
    #set log(login_cookie) notice
    #set log(timeout) notice
    #set log(session_id) notice

    ad_proc -private log {kind args} {
        Helper proc for debugging security aspects.
        Uncomment some of the log(*) flags above to activate
        debugging and reload this file.
    } {
        set var ::security::log($kind)
        if {[info exists $var]} {
            ns_log [set $var] "$kind [join $args { }]"
        }
    }
}

#
# Cookies (all are signed cookies):
#   cookie                value                                         max-age           secure
#   --------------------------------------------------------------------------------------------
#   ad_session_id         session_id,user_id,login_level                  SessionTimeout    yes|no
#   ad_user_login         user_id,issue_time,auth_token,forever,er        LoginTimeout|inf  no
#   ad_user_login_secure  user_id,issue_time,auth_token,random,forever,er LoginTimeout|inf  yes
#   ad_secure_token       session_id,random,peeraddr                      SessionLifetime   yes
#
#   "random" is used to hinder attack the secure hash.  Currently the
#   random data is ns_time. "peeraddr" is used to avoid session
#   hijacking. "er" stands for external_registry and is only
#   nonempty, when an external registry is used.
#
#   ad_user_login/ad_user_login_secure issue_time:
#      [ns_time] at the time the user last authenticated
#
#   ad_session_id login_level:
#      0 = none/expired,
#      1 = ok,
#      2 = auth ok, but account closed

ad_proc -public sec_random_token {} {
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
    if {[acs::icanuse "ns_crypto::randombytes"]} {
        if {![info exists ::tcl_sec_seed]} { set ::tcl_sec_seed [ns_crypto::randombytes 16].$start_clicks }
        set random_base [ns_sha1 "[ns_time][ns_crypto::randombytes -encoding binary 16]$start_clicks$request$::tcl_sec_seed"]
    } else {
        if {![info exists ::tcl_sec_seed]} { set ::tcl_sec_seed [ns_rand].$start_clicks }
        set random_base [ns_sha1 "[ns_time][ns_rand]$start_clicks$request$::tcl_sec_seed"]
    }
    set ::tcl_sec_seed [string range $random_base 0 10]

    return [ns_sha1 [string range $random_base 11 39]]
}

ad_proc -private sec_session_lifetime {} {
    Returns the maximum lifetime, in seconds, for sessions.
} {
    # default value is 7 days ( 7 * 24 * 60 * 60 )
    return [parameter::get \
                -package_id $::acs::kernel_id \
                -parameter SessionLifetime \
                -default 604800]
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
    ::security::log session_id "OACS= sec_handler: enter"

    if {[info exists ::security::log(login_cookie)]} {
        foreach c [list session_id secure_token user_login user_login_secure] {
            lappend msg "$c '[ad_get_cookie [security::cookie_name $c]]'"
        }
        ns_log notice "OACS [ns_conn url] cookies: $msg"
    }

    try {

        ad_get_signed_cookie [security::cookie_name session_id]

    } trap {AD_EXCEPTION NO_COOKIE} {errorMsg} {
        #
        # We have no session cookie. Maybe we are running under
        # aa_test.
        #
        #if {[nsv_array exists aa_test]} {
        #    ns_log notice "... nsv_array logindata [nsv_get aa_test logindata logindata]"
        #    ns_log notice "... ns_conn peeraddr [ns_conn peeraddr]"
        #    ns_log notice "... dict get $logindata peeraddr [ns_conn peeraddr]"
        #}
        if {[nsv_array exists aa_test]
            && [nsv_get aa_test logindata logindata]
            && [ns_conn peeraddr] in [list [dict get $logindata peeraddr] 127.0.0.1 ::1]
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
                aa_test_start
            }
        }
        if {![aa_test_running_p]} {
            sec_login_handler
        }

    } trap {AD_EXCEPTION INVALID_COOKIE} {errorMsg} {
        #
        # We have a session cookie, but it fails the cryptographic
        # checks.  Make sure to log the current user out and update
        # session cookie and ad_conn information.
        #
        ad_user_logout
        sec_login_handler

    } on ok {session_list} {
        #
        # The session cookie exists and is valid.
        #
        set session_data [split [lindex $session_list 0] {,}]
        set session_id              [lindex $session_data 0]
        set session_user_id         [lindex $session_data 1]
        set login_level             [lindex $session_data 2]
        set session_last_renew_time [lindex $session_data 3]

        if {![string is integer -strict $session_last_renew_time]} {
            #
            # This happens only when the session cookie is old style
            # previous to OpenACS 5.7 and does not have session review
            # time embedded. Assume cookie expired and force login
            # handler.
            #
            set session_last_renew_time 0
        }

        #
        # When the session_cookie comes from an authenticated session,
        # get login cookie as well.
        #
        set login_cookie_exists_p 0
        set persistent_login_p 0

        if {$session_user_id > 0} {
            set login_info [sec_login_read_cookie]
            if {[dict get $login_info status] eq "OK"} {

                set auth_token [dict get $login_info auth_token]

                #
                # Verify currently stored user authentication token
                # against the one on the login cookie.
                #
                if {$auth_token ne [sec_get_user_auth_token $session_user_id]} {
                    #
                    # Invalid user auth token in the login
                    # cookie. This happens e.g. when user changed
                    # their password, hence all logins on different
                    # devices must be invalidated. Make sure to log
                    # the current user out and update session cookie
                    # and ad_conn information.
                    #
                    ad_user_logout
                    sec_login_handler
                } else {
                    set login_cookie_exists_p 1
                    set persistent_login_p [dict get $login_info forever_p]
                    if {$persistent_login_p eq ""} {
                        set persistent_login_p 0
                    }
                }
            }
        }

        ::security::log timeout "login_cookie persistent_login $persistent_login_p [ns_conn url]"

        set session_expr [expr {$session_last_renew_time + [sec_session_timeout]}]

        #
        # Check for persistent logins: If the user requested a
        # persistent login, don't perform session renewing based on
        # SessionTimeout.
        #
        if {!$persistent_login_p} {
            ::security::log timeout "SessionTimeout in [expr {$session_expr - [ns_time]}] secs"
            if {$session_expr < [ns_time]} {
                ::security::log timeout "SessionTimeout reached, call sec_login_handler"
                sec_login_handler
            }
        } else {
            ::security::log timeout "SessionTimeout not checked due to persistent login"
        }

        set user_id 0
        set account_status closed

        ::security::log session_id "sec_handler: session_id $session_id invalidated_p [sec_session_id_invalidated_p $session_id]"

        if {$login_level > 0 && [sec_session_id_invalidated_p $session_id]} {
            #
            # Check, if the session_id was invalidated (e.g. via
            # logout).  In case, someone might be operating with
            # stolen cookies. This check required to make sure that
            # after the logout this sesson_id is not accepted anymore,
            # even when below sec_session_renew time (default 5min).
            #
            ns_log warning "downgrade login_level of user $session_user_id since session_id was invalidated"
            set login_level 0
        }

        if {$login_level > 0 && !$login_cookie_exists_p} {
            #
            # $login_level > 0 requires a login cookie. If we have no
            # login cookie, somebody tries to hack around.
            #
            set login_level 0
            ns_log warning "downgrade login_level of user $session_user_id since there is no login cookie provided"
        }

        switch -- $login_level {
            1 {
                #
                # authentication ok
                #
                set auth_level ok
                set user_id $session_user_id
                set account_status ok
            }
            2 {
                #
                # authentication ok, but account closed
                #
                set auth_level ok
            }
            default {
                #
                # login_level 0: none/expired
                #

                if { $session_user_id == 0 } {
                    set auth_level none
                } else  {
                    set auth_level expired
                }
            }
        }

        ::security::log login_cookie "Insecure session OK: session_id $session_id, session_user_id $session_user_id, auth_level $auth_level, user_id $user_id"

        #
        # We're okay for the insecure session. Check if it's also
        # secure.
        #
        if { $auth_level eq "ok"
             && ([security::secure_conn_p] || [ad_conn behind_secure_proxy_p])
         } {
            catch {
                set sec_token [split [ad_get_signed_cookie [security::cookie_name secure_token]] {,}]
                if {[lindex $sec_token 0] eq $session_id
                    && [lindex $sec_token 2] eq [ad_conn peeraddr]
                } {
                    set auth_level secure
                }
            }
            ::security::log login_cookie "Secure session checked: session_id = $session_id, session_user_id = $session_user_id, auth_level = $auth_level, user_id = $user_id"
        }

        ::security::log session_id "sec_handler: setup ad_conn with session_id $session_id untrusted_user_id $session_user_id user_id $user_id auth_level $auth_level"

        # Setup ad_conn
        ad_conn -set session_id $session_id
        ad_conn -set untrusted_user_id $session_user_id
        ad_conn -set user_id $user_id
        ad_conn -set auth_level $auth_level
        ad_conn -set account_status $account_status

        # Reissue session cookie so session doesn't expire if the
        # renewal period has passed. This is a little tricky because
        # the cookie doesn't know about sec_session_renew; it only
        # knows about sec_session_timeout.
        # [sec_session_renew] = SessionTimeout - SessionRenew (see security-init.tcl)
        # $session_expr = PreviousSessionIssue + SessionTimeout

        ::security::log timeout "SessionRefresh in [expr {($session_expr - [sec_session_renew]) - [ns_time]}] secs"

        if {  $session_expr - [sec_session_renew] < [ns_time] } {
            ::security::log login_cookie "sec_handler: generate new session_id_cookie"
            sec_generate_session_id_cookie
        }
    }
    #
    # Generate a CSRF token.
    #
    security::csrf::new
}

if {[ns_info name] eq "NaviServer"} {
    ad_proc -private sec_invalidate_session_id {session_id} {
        Invalidate the session_id for [sec_session_timeout] secs
    } {
        ns_cache_eval -expires [sec_session_timeout] -- ns:memoize $session_id {set _ 1}
    }
    ad_proc -private sec_session_id_invalidated_p {session_id} {
        Check, if the session_id was invalidated.
    } {
        return [ns_cache_get ns:memoize $session_id .]
    }
} else {
    ad_proc -private sec_invalidate_session_id {session_id} {
        Invalidate the session_id for [sec_session_timeout] secs
    } {
        # stub for now
    }
    ad_proc -private sec_session_id_invalidated_p {session_id} {
        Check, if the session_id was invalidated.
    } {
        # stub for now
    }
}


ad_proc -private sec_login_read_cookie {} {

    Fetches values either from "user_login_secure" or "user_login"
    cookies, depending whether we are in a secured connection or not.

    @author Victor Guerra

    @return dict of values from cookie "user_login_secure" or "user_login".
            Additionally, the dict contains a member "status" with possible
            values "OK", "NO_COOKIE" or "INVALID_COOKIE"
} {
    #
    # ad_user_login         user_id,issue_time,auth_token,forever,external_registry
    # ad_user_login_secure  user_id,issue_time,auth_token,random,forever,external_registry
    #
    # If over HTTPS, we look for the *_secure cookie
    #
    if { [security::secure_conn_p] || [ad_conn behind_secure_proxy_p]} {
        set cookie_name [security::cookie_name user_login_secure]
        set expect_elements 6
    } else {
        set cookie_name [security::cookie_name user_login]
        set expect_elements 5
    }

    #
    # Provide default values for the result.
    #
    set result {
        user_id 0
        issue_time 0
        auth_token ""
        forever_p 0
        external_registry ""
        status NO_COOKIE
    }

    try {
        ad_get_signed_cookie $cookie_name

    } trap {AD_EXCEPTION NO_COOKIE} {errorMsg} {
        dict set result status NO_COOKIE

    } trap {AD_EXCEPTION INVALID_COOKIE} {errorMsg} {
        dict set result status INVALID_COOKIE

    } on ok {cookie_value} {
        set login_list [split $cookie_value ","]
        dict set result status OK
        dict set result user_id    [lindex $login_list 0]
        dict set result issue_time [lindex $login_list 1]
        dict set result auth_token [lindex $login_list 2]

        if {[llength $login_list] == $expect_elements} {
            dict set result forever_p  [lindex $login_list end-1]
            dict set result external_registry [lindex $login_list end]
        } else {
            #
            # Legacy case (no external registry is provided). This is
            # just needed for the transition phase, while still old
            # cookies are in use, having no "external_registry"
            # defined.
            #
            dict set result forever_p  [lindex $login_list end]
            dict set result external_registry ""
        }
    }
    return $result
}

ad_proc -public sec_login_get_external_registry {} {

    If the login was issued from an external_registry, use this as
    well for refreshing.

    @return registry object or the empty string when not applicable

} {
    set external_registry ""
    if {[ns_conn isconnected]} {
        set external_registry [dict get [sec_login_read_cookie] external_registry]
        if {$external_registry ne "" && ![nsf::is object $external_registry]} {
            ns_log warning "external registry object '$external_registry'" \
                "used for login of user [ad_conn untrusted_user_id]" \
                "does not exist. Ignored."
            set external_registry ""
        }
    }
    return $external_registry
}

ad_proc -public sec_login_handler {} {

    If a login cookie exists, it is checked for expiration
    (depending on LoginTimeout) and the account status is validated.
    In every case, the session info including [ad_conn] and the
    session cookie is updated accordingly.

    Modified ad_conn variables: untrusted_user_id, session_id,
    auth_level, account_status, and user_id.

} {
    ns_log debug "OACS= sec_login_handler: enter"

    set auth_level none
    set new_user_id 0
    set untrusted_user_id 0
    set account_status closed

    #
    # Check login cookie.
    #
    set login_info [sec_login_read_cookie]
    if {[dict get $login_info status] eq "OK"} {
        set untrusted_user_id [dict get $login_info user_id]
        set auth_level expired

        #
        # Check conformancy of the auth_token between cookie and
        # database depending on LoginTimeout: When LoginTimeout is 0,
        # check the auth token always.  Otherwise, when check the
        # auth_token, when it LoginTimeout has expired.
        #
        set sec_login_timeout [sec_login_timeout]

        if { $sec_login_timeout == 0
             || [ns_time] - [dict get $login_info issue_time] < $sec_login_timeout
         } {
            #
            # Check auth_token.
            #
            if {[dict get $login_info auth_token] eq [sec_get_user_auth_token $untrusted_user_id]} {
                #
                # Check whether we retrieved the login cookie over
                # HTTPS. If so, we're secure.
                #
                if { [security::secure_conn_p] || [ad_conn behind_secure_proxy_p]} {
                    set auth_level secure
                } else {
                    set auth_level ok
                }

                #
                # In case there is no session_id, do not trust the
                # provided cookie, since it might be stolen. In
                # general, session cookies are recreated on the fly
                # for the current user, but we do not want this in
                # cases, when we have already a "valid" login cookie.
                #
                if {[ad_conn session_id] eq ""} {
                    ns_log warning "downgrade auth_level of user $untrusted_user_id since session_id invalid"
                    set auth_level expired
                }
            } else {
                ns_log notice "OACS= auth_token has changed"
            }
        }

        #
        # Check in addition to the auth_token also the account status.
        #
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
    {-external_registry ""}
    -forever:boolean
    user_id
} {
    Logs the user in, forever (via the user_login cookie) if -forever
    is true. This procedure assumes that the user identity has been
    validated.
} {
    set prev_user_id [ad_conn user_id]

    #
    # Deal with the permanent login cookies (user_login and
    # user_login_secure).
    #
    if { $forever_p } {
        set max_age inf
    } else {
        # user_login cookie will live for as long as the maximum login time
        set max_age [sec_login_timeout]
    }

    set auth_level "ok"
    set secure_p [expr {[security::secure_conn_p] || [ad_conn behind_secure_proxy_p]}]
    if {$cookie_domain eq ""} {
        set cookie_domain [parameter::get -parameter CookieDomain -package_id $::acs::kernel_id]
    }

    # If you're logged-in over a secure connection, you're secure
    if { $secure_p } {
        ad_set_signed_cookie \
            -max_age $max_age \
            -secure t \
            -domain $cookie_domain \
            [security::cookie_name user_login_secure] \
            "$user_id,[ns_time],[sec_get_user_auth_token $user_id],[ns_time],$forever_p,$external_registry"

        # We're secure
        set auth_level "secure"
    } elseif { $prev_user_id != $user_id } {
        # Hose the secure login token if this user is different
        # from the previous one.
        ad_unset_cookie -secure t [security::cookie_name user_login_secure]
    }

    #
    # Set "user_login" Cookie always with secure=f for mixed
    # content.
    #
    ns_log Debug "ad_user_login: Setting new user_login cookie with max_age $max_age"
    ad_set_signed_cookie \
        -expire [expr {$forever_p ? false : true}] \
        -max_age $max_age \
        -domain $cookie_domain \
        -secure f \
        [security::cookie_name user_login] \
        "$user_id,[ns_time],[sec_get_user_auth_token $user_id],$forever_p,$external_registry"

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

    if { $auth_token eq "" } {
        ns_log Debug "Security: User $user_id does not have any auth_token, creating a new one."
        set auth_token [sec_change_user_auth_token $user_id]
    }

    return $auth_token
}

ad_proc -public sec_change_user_auth_token {
    user_id
} {
    Change the user's auth_token, which invalidates all existing login cookies,
    i.e. forces user logout at the server.
} {
    set auth_token [ad_generate_random_string]

    ns_log Debug "Security: Changing user $user_id's auth_token to '$auth_token'"
    db_dml update_auth_token {
        update users set auth_token = :auth_token where user_id = :user_id
    }

    return $auth_token
}

ad_proc -public ad_user_logout {
    {-cookie_domain ""}
} {
    Logs the user out.
} {
    ad_log notice "ad_user_logout user_id [ad_conn user_id]"

    set external_registry [sec_login_get_external_registry]
    if {$external_registry ne ""} {
        #
        # If we were logged in via an external identity provider, try
        # to logout from there as well. Note that not every external
        # identity provider supports a logout (e.g. GitHub), and maybe
        # in some cases, the external logout is not wanted. This
        # should be provided by the implementation of the external
        # registry.
        #
        $external_registry logout
    }

    if {$cookie_domain eq ""} {
        set cookie_domain [parameter::get \
                               -parameter CookieDomain \
                               -package_id $::acs::kernel_id]
    }

    #
    # Make sure, this session_id is not accepted anymore.
    #
    sec_invalidate_session_id [ad_conn session_id]

    #
    # Use the same "secure" setting for unsetting the cookie as it was
    # used for setting the cookie. The implementation is not 100%
    # correct, for cases, when the parameter value for
    # "SecureSessionCookie" was altered during a session, but this
    # should be a seldom border case.
    #
    ad_unset_cookie \
        -domain $cookie_domain \
        -secure [expr {[parameter::get \
                            -boolean \
                            -parameter SecureSessionCookie \
                            -package_id $::acs::kernel_id \
                            -default 0] ? "t" : "f"}] \
        [security::cookie_name session_id]

    set external_registry [dict get [sec_login_read_cookie] external_registry]
    if {$external_registry ne "" && [nsf::is object $external_registry]} {
        #
        # Logout from external registry
        #
        ns_log notice "logout from external registry: $external_registry"
        $external_registry logout
    }

    ad_unset_cookie -domain $cookie_domain -secure f [security::cookie_name user_login]
    ad_unset_cookie -domain $cookie_domain -secure t [security::cookie_name secure_token]
    ad_unset_cookie -domain $cookie_domain -secure t [security::cookie_name user_login_secure]
}

namespace eval ::security {
    ad_proc -private preferred_password_hash_algorithm {} {

        Check the list of preferred password hash algorithms and the
        return the best which is available (or "salted-sha1" if
        nothing applies).

        @return password preferred hash algorithm
    } {

        set preferences [parameter::get \
                             -parameter PasswordHashAlgorithm \
                             -package_id $::acs::kernel_id \
                             -default "salted-sha1"]
        foreach algo $preferences {
            if {[info commands ::security::hash::$algo] ne ""} {
                #
                # This preference is available.
                #
                return $algo
            } else {
                ns_log warning "PasswordHashAlgorithm '$algo' was specified," \
                    "but is not available in your setup."
            }
        }
        #
        # General fallback (only necessary for invalid parameter settings)
        #
        ns_log warning "No valid PasswordHashAlgorithm was specified: '$preferences'." \
            "Fall back to default."

        return "salted-sha1"
    }
}

namespace eval ::security::hash {
    ad_proc -private salted-sha1 {password salt} {

        Classical OpenACS password hash algorithm. This algorithm must
        be always available and is independent of the
        NaviServer/AOLserver version.

        @return hex encoded password hash

    } {
        set salt [string trim $salt]
        return [ns_sha1 ${password}${salt}]
    }

    if {[::acs::icanuse "ns_crypto::pbkdf2_hmac"]} {
        ad_proc -private scram-sha-256 {password salt} {

            SCRAM hash function using sha256 as digest function. The
            SCRAM hash function is PBKDF2 [RFC2898] with HMAC as the
            pseudo-random function and where the output key length ==
            hash length.  We use 15K iterations for PBKDF2 as
            recommended in RFC 7677.

            @return hex encoded password hash (64 bytes)
        } {
            return [::ns_crypto::pbkdf2_hmac \
                        -digest sha256 \
                        -iterations 15000 \
                        -secret $password \
                        -salt $salt]
        }
    }

    if {[::acs::icanuse "ns_crypto::scrypt"]} {
        ad_proc -private scrypt-16384-8-1 {password salt} {

            Compute a "password hash" using the scrypt password based
            key derivation function (RFC 7914)

            @return hex encoded password hash (128 bytes)
        } {
            return [::ns_crypto::scrypt -secret $password -salt $salt -n 16384 -r 8 -p 1]
        }
    }

    if {[::acs::icanuse "ns_crypto::argon2"]} {
        ad_proc -private argon2-12288-3-1 {password salt} {

            Compute a "password hash" using the Argon2 hash algorithm
            key derivation function (RFC 9106).

            Parameterization recommendation from OWASP: m=12288 (12 MiB), t=3, p=1

            @return hex encoded password hash (128 bytes)
        } {
            return [::ns_crypto::argon2 -variant argon2id \
                        -password $password -salt $salt \
                        -memcost 12288 -iter 3 -lanes 1 -threads 1 -outlen 64]
        }

        ad_proc -private argon2-rfc9106-high-mem {password salt} {

            Compute a "password hash" using the Argon2 hash algorithm
            key derivation function (RFC 9106).

            Parameterization first recommendation from RFC 9106:
            t=1, m=2GiB, p=4 (2 GiB = 2,097,152 KB)

            @return hex encoded password hash (128 bytes)
        } {
            return [::ns_crypto::argon2 -variant argon2id \
                        -password $password -salt $salt \
                        -memcost 2097152 -iter 1 -lanes 4 -threads 4 -outlen 64]
        }

        ad_proc -private argon2-rfc9106-low-mem {password salt} {

            Compute a "password hash" using the Argon2 hash algorithm
            key derivation function (RFC 9106).

            Parameterization second recommendation from RFC 9106 (low memory):
            t=3, m=64 MiB, p=4 (64 MiB = 65,536 KB)

            @return hex encoded password hash (128 bytes)
        } {
            return [::ns_crypto::argon2 -variant argon2id \
                        -password $password -salt $salt \
                        -memcost 65536 -iter 3 -lanes 4 -threads 4 -outlen 64]
        }

    }
}

ad_proc -public ad_check_password {
    user_id
    password_from_form
} {

    Check if the provided password is correct. OpenACS never stores
    password, but uses salted hashes for identification. Different
    algorithm can be used. When the stored hash is from another hash
    algorithm, which is preferred, this function updates the password
    hash automatically, but only, when the password is correct.

    @return Returns 1 if the password is correct for the given user ID.
} {

    set found_p [db_0or1row password_select {
        select password, salt, password_hash_algorithm from users where user_id = :user_id
    }]
    if { !$found_p } {
        return 0
    }

    if {$password ne [::security::hash::$password_hash_algorithm $password_from_form $salt]  } {
        return 0
    }

    set preferred_hash_algorithm [security::preferred_password_hash_algorithm]
    if {$preferred_hash_algorithm ne $password_hash_algorithm} {
        ns_log notice "upgrade password hash for user $user_id from" \
            "$password_hash_algorithm to $preferred_hash_algorithm"
        ad_change_password \
            -password_hash_algorithm $preferred_hash_algorithm \
            $user_id \
            $password_from_form
    }
    return 1
}

ad_proc -public ad_change_password {
    {-password_hash_algorithm "salted-sha1"}
    user_id
    new_password
} {
    Change the user's password
} {
    if { $user_id eq "" } {
        error "No user_id supplied"
    }

    #
    # The hash algorithms are called in standard OpenACS with a salt
    # size of 20 bytes (in hex format), which corresponds to 160-bit.
    #
    set salt [sec_random_token]
    set new_password [::security::hash::$password_hash_algorithm $new_password $salt]

    db_dml password_update {
        update users
        set    password = :new_password,
               salt = :salt,
               password_hash_algorithm = :password_hash_algorithm,
               password_changed_date = current_timestamp
        where  user_id = :user_id
    }
}

ad_proc -private sec_setup_session {
    {-cookie_domain ""}
    new_user_id
    auth_level
    account_status
} {

    Set up the session, generating a new one if necessary,
    updates all user_relevant information in [ad_conn],
    and generates the cookies necessary for the session.

} {
    ::security::log session_id "OACS= sec_setup_session: enter"

    set session_id [ad_conn session_id]

    # figure out the session id, if we don't already have it
    if { $session_id eq ""} {

        ::security::log session_id "OACS= empty session_id"

        set session_id [sec_allocate_session]
        # if we have a user on a newly allocated session, update
        # users table

        ::security::log session_id "OACS= newly allocated session $session_id"

        if { $new_user_id != 0 } {
            ns_log debug "OACS= about to update user session info, user_id NONZERO"
            sec_update_user_session_info $new_user_id
            ns_log debug "OACS= done updating user session info, user_id NONZERO"
        }
    } else {
        #
        # $session_id is an active verified session this call is
        # either a user doing a log-in on an active unidentified
        # session, or a change in identity for a browser that is
        # already logged-in.
        #
        set prev_user_id [ad_conn user_id]

        #
        # Change the session id for all user_id changes, also on
        # changes from user_id 0, since owasp recommends to renew the
        # session_id after any privilege level change.
        #
        ns_log debug "prev_user_id $prev_user_id new_user_id $new_user_id"

        if { $prev_user_id != 0 && $prev_user_id != $new_user_id } {
            #
            # This is a change in identity so we create
            # a new session_id to avoid sharing of session-level data
            #
            set session_id [sec_allocate_session]
        }

        if { $prev_user_id != $new_user_id } {
            #
            # A change of user_id on an active session demands an
            # update of the users table.
            #
            ::security::log login_cookie "sec_update_user_session_info"
            sec_update_user_session_info $new_user_id
        }
    }

    set user_id 0
    #
    # If both auth_level and account_status are 'ok' or better, we
    # have a solid user_id.
    #
    if { ($auth_level eq "ok" || $auth_level eq "secure") && $account_status eq "ok" } {
        set user_id $new_user_id
    }

    # Set ad_conn variables
    ad_conn -set untrusted_user_id $new_user_id
    ad_conn -set session_id $session_id
    ad_conn -set auth_level $auth_level
    ad_conn -set account_status $account_status
    ad_conn -set user_id $user_id

    ::security::log session_id "OACS= about to generate session id cookie"

    sec_generate_session_id_cookie -cookie_domain $cookie_domain

    ::security::log session_id "OACS= done generating session id cookie"

    if { $auth_level eq "secure"
         && ([security::secure_conn_p] || [ad_conn behind_secure_proxy_p])
         && $new_user_id != 0
     } {
        #
        # This is a secure session, so the browser needs
        # a cookie marking it as such.
        #
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

ad_proc security::cookie_name {plain_name} {
    @return the supplied cookie name, but potentially prefixed
            according to the NaviServer CookieNamespace parameter, to
            make it unique for this particular domain.
} {
    #
    # Setting a cookie always requires a connection.
    #
    return [ns_config "ns/server/[ns_info server]/acs" CookieNamespace "ad_"]$plain_name
}

ad_proc -private sec_generate_session_id_cookie {
    {-cookie_domain ""}
} {
    Sets the "session_id" cookie based on global variables.
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

    ns_log Debug "Security: [ns_time] sec_generate_session_id_cookie setting" \
        "session_id=$session_id, user_id=$user_id, login_level=$login_level"

    if {$cookie_domain eq ""} {
        set cookie_domain [parameter::get \
                               -parameter CookieDomain \
                               -package_id $::acs::kernel_id]
    }

    # Fetch the last value element of "user_login" or
    # "user_login_secure" cookie that indicates if user wanted to be
    # remembered when logging in.

    set discard t
    set max_age [sec_session_timeout]
    set login_info [sec_login_read_cookie]
    if {[dict get $login_info status] eq "OK"
        && [dict get $login_info forever_p]
    } {
        set discard f
        set max_age inf
    }

    ad_set_signed_cookie \
        -secure [expr {[parameter::get \
                            -boolean \
                            -parameter SecureSessionCookie \
                            -package_id $::acs::kernel_id \
                            -default 0] ? "t" : "f"}] \
        -discard $discard \
        -replace t \
        -max_age $max_age \
        -domain $cookie_domain \
        [security::cookie_name session_id] \
        "$session_id,$user_id,$login_level,[ns_time]"
}

ad_proc -private sec_generate_secure_token_cookie { } {
    Sets the "secure_token" cookie.
} {
    ad_set_signed_cookie \
        -secure t \
        [security::cookie_name secure_token] \
        "[ad_conn session_id],[ns_time],[ad_conn peeraddr]"
}

ad_proc -private sec_allocate_session {} {

    Returns a new session id

} {

    if { ![info exists ::acs::sec_id_max_value] || ![info exists ::acs::sec_id_current_sequence_id]
         || $::acs::sec_id_current_sequence_id > $::acs::sec_id_max_value } {
        ::security::log session_id "sec_allocate_session: info exists ::acs::sec_id_max_value [info exists ::acs::sec_id_max_value]" \
            "info exists ::acs::sec_id_current_sequence_id [info exists ::acs::sec_id_current_sequence_id]"
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
    set mapping [acs::misc_cache eval ad_get_host_node_map {
        db_list_of_lists get_node_host_names {select host, node_id from host_node_map}
    }]
    set p [lsearch -index 0 -exact $mapping $hostname]
    if {$p != -1} {
        set result [lindex $mapping $p 1]
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

ad_proc security::get_register_subsite {} {

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
                # the URL to the configured hostname, since
                # get_qualified prepends the [ad_conn location], which
                # points to the virtual hostname.
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
        if { [ns_conn isconnected] } {
            set url [subsite::get_element -element url]
            #
            # Check to see that the user (most likely "The Public"
            # party, since there's probably no user logged-in)
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

ad_proc security::safe_tmpfile_p {
    -must_exist:boolean
    tmpfile
} {

    Checks that a file is a safe tmpfile, that is, it belongs to the
    configured tmpdir.

    When the file exists, we also enforce additional criteria:
    - file must belong to the current system user
    - file must be readable and writable by the current system user

    @param tmpfile absolute path to a possibly existing tmpfile
    @param must_exist make sure the file exists

    @return boolean
} {
    #
    # Ensure no ".." in the path
    #
    set tmpfile [ns_normalizepath $tmpfile]
    set tmpdir [string trimright [ns_config ns/parameters tmpdir] /]

    if {[ad_file dirname $tmpfile] ne $tmpdir} {
        #
        # File is not a direct child of the tmpfolder: not safe
        #
        return false
    }

    if {![ad_file exists $tmpfile]} {
        #
        # File does not exist yet: safe, unless we demand for the file
        # to exist.
        #
        return [expr {!$must_exist_p}]
    }

    if {![ad_file owned $tmpfile]} {
        #
        # File does not belong to us: not safe
        #
        return false
    }

    if {![ad_file readable $tmpfile]} {
        #
        # We cannot read the file: not safe
        #
        return false
    }

    if {![ad_file writable $tmpfile]} {
        #
        # We cannot write the file: not safe
        #
        return false
    }

    #
    # The file is safe
    #
    return true
}

ad_proc -public ad_get_login_url {
    {-authority_id ""}
    {-username ""}
    -return:boolean
    {-external_registry ""}
} {

    Returns a URL to the login page of the closest subsite, or the
    main site, if there's no current connection.

    @option return  If set, will export the current form, so when
                    the registration is complete, the user will be returned
                    to the current location.  All variables in
                    ns_getform (both posts and gets) will be maintained.

    @author Lars Pind (lars@collaboraid.biz)
    @author Gustaf Neumann

} {

    #
    # Get the login_url 'url' and some more parameters form the
    # register subsite for this registry.
    #
    set subsite_info [security::get_register_subsite]
    foreach var {url require_qualified_return_url host_node_id} {
        set $var [dict get $subsite_info $var]
    }

    if { [ns_conn isconnected]
         && $return_p
     } {
        #
        # In a few cases, we do not need to add a fully qualified
        # return url. The secure cases have to be still tested.
        #
        if { !$require_qualified_return_url
             && ([security::secure_conn_p]
                 || [ad_conn behind_secure_proxy_p]
                 || ![security::RestrictLoginToSSLP]
                 )
         } {
            set return_url [ad_return_url]
        } else {
            set return_url [ad_return_url -qualified]
        }
    }

    if {$external_registry ne ""} {
        ns_log notice "the external registry $external_registry is used"
        #
        # We get here in cases of a refresh of a login, since we know
        # that the current user_id is expired, and the user has
        # registered via an external registry. Therefore, we use
        # the same external registry for the refresh.
        #
        # In general, we have two options: (a) redirect directly to
        # the external registry login page, or (b) redirect to an
        # external registry enhanced classical OpenACS login page. We
        # are here on the (a) path, since potentially, the external
        # identity managers allows one to continue without even showing a
        # login page (when it says, the login is still valid).
        #
        # The path (b) might be chosen via a future package parameter.
        #
        set url [$external_registry login_url -return_url $return_url]
    } else {
        append url "register/"

        #
        # Don't add a return_url if you're already under /register,
        # because that will frequently interfere with the normal login
        # procedure.
        #
        if { [string match "register/*" [ad_conn extra_url]] } {
            set return_url ""
        }
        if {$host_node_id == 0} {
            unset host_node_id
        }
        set url [export_vars -base $url -no_empty {
            authority_id username return_url host_node_id
        }]
    }
    ::security::log login_url "ad_get_login_url: final login_url <$url>"

    return $url
}

ad_proc -public ad_get_logout_url {
    -return:boolean
    {-return_url ""}
} {

    Returns a URL to the logout page of the closest subsite, or the
    main site, if there's no current connection.

    @option return  If set, will export the current form, so when the logout is complete
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

ad_proc -public ad_get_external_registries {
    {-subsite_id ""}
} {

    Return for the specified subsite (or the current registry subsite)
    the external authority interface objs. Per default, all defined
    external registries are returned, but a subsite might restrict this.

} {
    if {$subsite_id eq ""} {
        set subsite_id [dict get [security::get_register_subsite] subsite_id]
    }
    set offered_registries [parameter::get \
                                -parameter OfferedRegistries \
                                -package_id $subsite_id \
                                -default *]

    set result {}
    if {[nsf::is object ::xo::Authorize]} {
        foreach auth_obj [::xo::Authorize info instances -closure] {
            #
            # Don't list on the general available pages the external
            # authorization objects when these are configured in debugging
            # mode.
            #
            if {[$auth_obj cget -debug]} {
                continue
            }

            if {$offered_registries eq "*"
                || $auth_obj in $offered_registries
            } {
                lappend result $auth_obj
            }
        }
    }
    return $result
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
    set url [ad_conn url]
    if {$url ni {"/favicon.ico" "/index.tcl" "/"}
        && ![string match "/global/*"    $url]
        && ![string match "*/register/*" $url]
        && ![string match "*/SYSTEM/*"   $url]
        && ![string match "*/user_please_login.tcl" $url]} {
        # not one of the magic acceptable URLs
        set user_id [ad_conn user_id]
        if {$user_id == 0} {
            auth::require_login
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
    {-binding 0}
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

    @param token_id allows the caller to specify a token_id which
           is then ignored so don't use it.

    @param binding allows the caller to bind a signature to a user/session.
           A value of 0 (default) means no additional binding.
           When the value is "-1" only the user who created the signature can
           obtain the value again.
           When the value is "-2" only the user with the same csrf token can
           obtain the value again.

           The permissible values might be extended in the future.

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

    switch $binding {
        -1 {
            set binding_value [ad_conn user_id]
            append token_id :$binding
        }
        -2 {
            set binding_value [::security::csrf::new]
            append token_id :$binding
        }
        0 {
            set binding_value ""
        }
        default {error "invalid binding"}
    }

    set hash [ns_sha1 "$value$token_id$expire_time$secret_token$binding_value"]
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
    if {![string is list $signature]} {
        ns_log warning "signature is not a list '$signature'"
        return 0
    }
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
    if {![string is list $signature]} {
        ns_log warning "signature is not a list '$signature'"
        return 0
    }
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

    lassign [split $token_id :] raw_token_id binding

    if { $secret eq "" } {
        if { $raw_token_id eq "" } {
            ns_log Debug "__ad_verify_signature: Neither secret, nor token_id supplied"
            return 0
        } elseif {![string is integer -strict $raw_token_id]} {
            ns_log Warning "__ad_verify_signature: token_id <$raw_token_id> is not an integer"
            return 0
        }

        try {
            set secret_token [sec_get_token $raw_token_id]
        } on error {errmsg} {
            ns_log Warning "__ad_verify_signature: token_id <$raw_token_id> validation returns '$errmsg'"
            return 0
        }

    } else {
        set secret_token $secret
    }

    ns_log Debug "__ad_verify_signature: Getting token_id $token_id, value $secret_token"
    ns_log Debug "__ad_verify_signature: Expire_Time is $expire_time (compare to [ns_time], diff [expr {[ns_time]-$expire_time}]), hash is $hash"

    if {$binding == -1} {
        set binding_value [ad_conn user_id]
    } elseif {$binding == -2} {
        set binding_value [::security::csrf::new]
    } else {
        set binding_value ""
    }

    #
    # Compute hash based on token, expire_time and user_id/csrf token
    #
    ns_log Debug "__ad_verify_signature: compute hash based on $value/$token_id/$expire_time/$secret_token/$binding_value (binding $binding)"
    set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token$binding_value"]

    # Need to verify both hash and expiration
    set hash_ok_p 0
    set expiration_ok_p 0

    if {$computed_hash eq $hash} {
        ns_log Debug "__ad_verify_signature: Hash matches - Hash check OK"
        set hash_ok_p 1
    } else {
        #
        # Check to see if IE is lame (and buggy!) and is expanding \n to \r\n
        # See: http://rhea.redhat.com/bboard-archive/webdb/000bfF.html
        #
        ns_log Debug "__ad_verify_signature: hashes differ '$computed_hash' vs '$hash'"
        set value [string map [list \r ""] $value]
        set org_computed_hash $computed_hash
        set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token$binding_value"]

        if {$computed_hash eq $hash} {
            #
            # Not sure, the comments for IE are still true, so issue
            # warnings in the error.log when this happens.
            #
            ns_log warning "__ad_verify_signature: Hash matches after correcting for IE bug - Hash check OK"
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
    ns_log Debug "__ad_verify_signature: hash_ok '$hash_ok_p' expiration_ok_p '$expiration_ok_p'"

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
    expired. Throws an exception if cookie does not exists or
    validation fails (maybe due to expiration).

    @return cookie value

    @see ad_get_cookie
    @see ad_set_signed_cookie
    @see ad_get_signed_cookie_with_expr
} {

    set cookie_value [ad_get_cookie -include_set_cookies $include_set_cookies $name]
    if { $cookie_value eq "" || ![string is list $cookie_value]} {
        throw {AD_EXCEPTION NO_COOKIE} {Cookie does not exist}
    }

    lassign $cookie_value value signature
    ::security::log login_cookie "ad_get_signed_cookie: Got signed cookie $name with value $value, signature $signature."

    if { [ad_verify_signature -secret $secret $value $signature] } {
        ::security::log login_cookie "ad_get_signed_cookie: Verification of cookie $name OK"
        return $value
    }

    ::security::log login_cookie "ad_get_signed_cookie: Verification of cookie $name FAILED"
    throw {AD_EXCEPTION INVALID_COOKIE} "Cookie could not be authenticated."
}

ad_proc -public ad_get_signed_cookie_with_expr {
    {-include_set_cookies t}
    {-secret ""}
    name
} {

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and ensures that the cookie has not
    expired. Throws an exception when cookie does not exist or
    validation fails.

    @return Two-element list containing cookie data and expiration time

    @see ad_get_cookie
    @see ad_get_signed_cookie
    @see ad_set_signed_cookie
} {

    set cookie_value [ad_get_cookie -include_set_cookies $include_set_cookies $name]
    if { $cookie_value eq "" || ![string is list $cookie_value]} {
        throw {AD_EXCEPTION NO_COOKIE} {Cookie does not exist}
    }

    lassign $cookie_value value signature
    set expr_time [ad_verify_signature_with_expr -secret $secret $value $signature]

    ns_log Debug "Security: Done calling get_cookie $cookie_value for $name; received $expr_time expiration, getting $value and $signature."

    if { $expr_time } {
        return [list $value $expr_time]
    }

    throw {AD_EXCEPTION INVALID_COOKIE} "Cookie could not be authenticated."
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
    {-samesite lax}
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

    @see ad_set_cookie
    @see ad_get_signed_cookie
    @see ad_get_signed_cookie_with_expr

} {
    if { $signature_max_age eq "" } {
        if { $max_age in {"inf" 0} } {
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

    ::security::log timeout "ad_set_signed_cookie $name [list signature_max_age $signature_max_age max_age $max_age]"
    ad_set_cookie \
        -replace $replace \
        -secure $secure \
        -discard $discard \
        -scriptable $scriptable \
        -expire $expire \
        -max_age $max_age \
        -domain $domain \
        -path $path \
        -samesite $samesite \
        $name $data
}





#####
#
# Token generation and handling
#
#####

if {[ns_info name] eq "NaviServer"} {
    ad_proc -private sec_get_token_from_nsv {token_id token_var} {

        Just for compatibility with AOLserver, which does not support
        an atomic check and get operation for nsv.

    } {
        upvar $token_var token
        return [nsv_get secret_tokens $token_id token]
    }
} else {
    ad_proc -private sec_get_token_from_nsv {token_id token_var} {

        Compatibility function for AOLserver, which does not support
        nsv_get with the optional output variable.

    } {
        upvar $token_var token
        if {[nsv_exists secret_tokens $token_id]} {
            set token [nsv_get secret_tokens $token_id]
            return 1
        }
        return 0
    }
}

ad_proc -public sec_get_token {
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

    #
    # First check the per-thread cache to obtain a token from the
    # token_id.
    #
    set key ::security::tcl_secret_tokens($token_id)
    if { [info exists $key] } {
        return [set $key]
    }

    #
    # If there is no secret token available per thread,
    # get it and try again.
    #
    if {[array size ::security::tcl_secret_tokens] == 0} {
        sec_populate_secret_tokens_thread_cache
        if { [info exists $key] } {
            return [set $key]
        }
    }

    #
    # We might get token_ids from previous runs, so we have fetch these
    # from the secret tokens cache, or from the data base.
    #
    if {![sec_get_token_from_nsv $token_id token]} {
        set token [db_string get_token {select token from secret_tokens
            where token_id = :token_id} -default 0]
        if {$token ne 0} {
            nsv_set secret_tokens $token_id $token
        } else {
            #
            # Very important to throw the error here if $token == 0
            #
            error "Invalid token ID"
        }
    }

    set $key $token
    return $token
}

ad_proc -public sec_get_random_cached_token_id {} {

    Randomly returns a token_id from the token cache

} {
    #set list_of_names [ns_cache names secret_tokens]
    set list_of_names [array names ::security::tcl_secret_tokens]
    if {[llength $list_of_names] == 0} {
        sec_populate_secret_tokens_thread_cache
        set list_of_names [array names ::security::tcl_secret_tokens]
    }

    set random_seed [ns_rand [llength $list_of_names]]
    return [lindex $list_of_names $random_seed]
}

ad_proc -private sec_populate_secret_tokens_thread_cache {} {

    Copy secret_tokens cache to per-thread variables

} {
    set secret_tokens [nsv_array get secret_tokens]
    if {[llength $secret_tokens] == 0} {
        sec_populate_secret_tokens_cache
        set secret_tokens [nsv_array get secret_tokens]
    }
    foreach {id token} $secret_tokens {
        set ::security::tcl_secret_tokens($id) $token
    }
}

ad_proc -private sec_populate_secret_tokens_cache {} {

    Randomly populates the secret_tokens cache.

} {
    set num_tokens [parameter::get \
                        -package_id $::acs::kernel_id \
                        -parameter NumberOfCachedSecretTokens \
                        -default 100]

    # this is called directly from security-init.tcl,
    # so it runs during the install before the data model has been loaded
    if { [db_table_exists secret_tokens] } {
        db_foreach get_secret_tokens {} {
            nsv_set secret_tokens $token_id $token
        }
    }
    db_release_unused_handles
}

ad_proc -private sec_populate_secret_tokens_db {} {

    Populates the secret_tokens table. Note that this will take a while
    to run.

} {

    set num_tokens [parameter::get \
                        -package_id $::acs::kernel_id \
                        -parameter NumberOfCachedSecretTokens \
                        -default 100]
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

ad_proc -private sec_lookup_property_not_cached {
    id
    module
    name
} {

    Look up a particular session property from the database and record
    the last hit when found.

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
    over HTTPS or the default is returned.

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
        # return the default of the property.
        #
        if { $id eq "" } {
            return $default
        }
    } else {
        set id $session_id
    }

    set cmd [list sec_lookup_property_not_cached $id $module $name]

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

    if { $secure_p != "f" && !([security::secure_conn_p] || [ad_conn behind_secure_proxy_p]) } {
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

    if { $secure != "f" && !([security::secure_conn_p] || [ad_conn behind_secure_proxy_p])} {
        error "Unable to set secure property in insecure or invalid session"
    }

    if { $session_id eq "" } {
        set session_id [ad_conn session_id]
    }

    if { $session_id eq "" } {
        ad_log warning "could not obtain a session_id via 'ad_conn session_id'"
    } else {

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
                if {[db_driverkey ""] eq "oracle"} {
                    acs::dc call sec_session_property upsert \
                        -p_session_id $session_id \
                        -p_module $module \
                        -p_name $name \
                        -p_value $value \
                        -p_secure $secure \
                        -p_last_hit $last_hit
                } else {
                    acs::dc call sec_session_property upsert \
                        -session_id $session_id \
                        -module $module \
                        -name $name \
                        -value $value \
                        -secure $secure \
                        -last_hit $last_hit
                }
            }
        }
    }

    # Remember the new value, seeding the memoize cache with the proper value.
    util_memoize_seed \
        [list sec_lookup_property_not_cached $session_id $module $name] \
        [list $value $secure]
}


#
# Provide a global variable for devopers to activate/deactivate
# client_property_password in case a site has good reasons not to
# using the client property (e.g. site specific code). This is meant
# to be transitional code.
#
set ::acs::pass_password_as_query_variable 0

ad_proc -public security::set_client_property_password {password} {

    Convenience function for remembering user password as client property
    rather than passing it as query parameter.

    @see security::get_client_property_password
} {
    ad_set_client_property -persistent f acs-admin user-password $password
}

ad_proc -public security::get_client_property_password {password} {

    Convenience function for retrieving user password from client property

    @see security::set_client_property_password

} {
    return [ad_get_client_property acs-admin user-password]
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
                -package_id $::acs::kernel_id]
}

ad_proc -public security::require_secure_conn {} {
    Redirect back to the current page in secure mode (HTTPS) if
    we are not already in secure mode.
    Does nothing if the server is not configured for HTTPS support.

    @author Peter Marklund
} {
    if { [https_available_p] } {
        if { !([security::secure_conn_p] || [ad_conn behind_secure_proxy_p])} {
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


ad_proc -public security::get_qualified_url { url } {
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

ad_proc -public security::get_secure_location {} {
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
                                    -boolean \
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
                                    -boolean \
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
    # Compatibility function for AOLserver, which abstracts from the
    # configuration section in the config files. NaviServer supports
    # in general global and per-server defined drivers.
    #
    # In the emulated version for AOLserver just report the per-server
    # configurations, since these are the only ones supported by
    # AOLserver.
    #
    ad_proc -public ns_driversection {
        {-driver "nssock"}
        {-server ""}
    } {
        Return the section name in the config file containing
        configuration information about the network connection.

        @param driver (e.g. nssock)
        @param server symbolic server name
        @return name of section of the drive in the config file
    } {
        if {$server eq ""} {set server [ns_info server]}
        return "ns/server/$server/module/$driver"
    }
}

ad_proc -private ad_server_modules {} {
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

    # Get the drivers registered for nsd (this requires at least NaviServer 4.99.15, Jan 2017)
    try {
        foreach driver_info [ns_driver info] {
            if {[dict get $driver_info type] eq "nsssl"} {
                # check, if the current server is using this driver
                set serversSection [ns_configsection ns/module/[dict get $driver_info module]/servers]
                if {$serversSection ne "" && [ns_info server] in [ns_set keys $serversSection]} {
                    set ::acs::sdriver [dict get $driver_info module]
                    return $::acs::sdriver
                }
            }
        }
        # if we can use the "ns_driver info" interface, and no sdriver
        # is found - there is no secure driver. No need to fall back
        # to the legacy code interface.
        return $::acs::sdriver

    } on error {errorMsg} {
        ns_log warning "Probably use of version of NaviServer before 4.99.15: $errorMsg"
    }
    if {$::acs::sdriver eq ""} {
        #
        # fallback for old NaviServer instances
        #
        set server_modules [ad_server_modules]
        foreach driver {nsssl nsssl_v4 nsssl_v6 nsopenssl nsssle https} {
            if {$driver ni $server_modules} continue
            set ::acs::sdriver $driver
            break
        }
    }
    return $::acs::sdriver
}

if {[namespace which ns_driver] ne ""} {

    ad_proc -public security::configured_driver_info {} {

        Return a list of dicts containing type, driver, location and port
        of all configured drivers

        @see util_driver_info

    } {
        set protos {http 80 https 443}
        set result {}
        foreach i [ns_driver info] {
            set type     [dict get $i type]
            set location [dict get $i location]
            set proto    [dict get $i protocol]
            if {$location ne ""} {
                set li [ns_parseurl $location]

                if {[dict exists $li port]} {
                    set port [dict get $li port]
                    set suffix ":$port"
                } else {
                    set port [dict get $protos $proto]
                    set suffix ""
                }
            } else {
                #
                # In case we have no "location" defined (e.g. virtual
                # hosting), get "port" and suffix directly from the
                # driver.
                #
                if {[dict exists $i port]} {
                    set port [lindex [dict get $i port] 0]
                    set defaultport [dict get $i defaultport]
                } else {
                    set driver_section [ns_driversection -driver [dict exists $i module]]
                    set port [ns_config -int $driver_section port]
                    set defaultport [dict get $protos $proto]
                }
                #
                # Newer versions of NaviServer support multiple ports
                # per driver. For now, take the first one (similar with "address" below).
                #
                set port [lindex [dict get $i port] 0]
                if {$port eq $defaultport} {
                    set suffix ""
                } else {
                    set suffix ":$port"
                }
            }
            lappend result [list \
                                proto $proto \
                                driver [dict get $i module] \
                                host [lindex [dict get $i address] 0] \
                                location $location port $port suffix $suffix]
        }
        return $result
    }

} else {

    ad_proc -public security::configured_driver_info {} {
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

ad_proc -private security::configured_locations {
    {-suppress_http_port:boolean false}
    {-secure_conn:boolean false}
} {

    This function returns the configured locations.

    When the package parameter "SuppressHttpPort" of acs-tcl parameter
    is true, then an alternate location without a port is included.
    This proc also assumes hostnames from host_node_map table are
    accurate and legit.

    The term location refers to "protocol://domain:port" for website.

    @return list of locations

} {
    set locations [list]
    set portless_locations {}
    #
    # Get configuration information from the configured servers.
    #
    set driver_info [security::configured_driver_info]
    foreach d $driver_info {
        #
        # port == 0 means that the driver is just used for sending,
        # but not for receiving. In this case, this entry is not
        # regarded as a valid location.
        #
        if {[dict get $d port] != 0} {
            #
            # Add configured locations (deprecated, since this
            # conflicts with the concept of virtual servers).
            #
            set location [dict get $d location]
            if {$location ne "" && $location ni $locations} {
                lappend locations $location
            }

            set hosts [dict get $d host]
            if {[acs::icanuse "ns_set values"]} {
                set virtualservers \
                    [ns_configsection ns/module/[dict get $d driver]/servers]
                if {$virtualservers ne ""} {
                    lappend hosts {*}[ns_set values $virtualservers]
                }
            }
            foreach entry $hosts {
                #
                # The value of the "DRIVER/servers" section might
                # contain also a port.
                #
                set d1 [dict merge $d [ns_parsehostport $entry]]
                set proto [dict get $d proto]
                set host [dict get $d1 host]
                set port [dict get $d1 port]
                if {$host in {0.0.0.0 ::}} {
                    #
                    # Don't add INADDR_ANY to locations
                    #
                    continue
                }
                #
                # Add always a variant with the omitted default port.
                #
                if {($proto eq "https" && $port eq "443")
                    || ($proto eq "http" && $port eq "80")
                } {
                    set location [util::join_location -proto $proto -hostname $host]
                    if {$location ni $locations} {
                        lappend locations $location
                    }
                }
                #
                # Add a variant with the omitted port to
                # portless_locations.
                #
                set location [util::join_location -proto $proto -hostname $host]
                if {$location ni $portless_locations
                    && $location ni $locations
                } {
                    lappend portless_locations $location
                }
                #
                # Add always a variant with the port to locations.
                #
                set location [util::join_location -proto $proto -hostname $host -port $port]
                if {$location ni $locations} {
                    lappend locations $location
                }
            }
        }
    }

    #
    # Add locations from host_node_map
    #
    set host_node_map_hosts_list \
        [db_list get_node_host_names {select host from host_node_map}]

    if { [llength $host_node_map_hosts_list] > 0 } {
        if { $suppress_http_port_p } {
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

    if {$suppress_http_port_p} {
        lappend locations {*}$portless_locations
    }

    return $locations
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
    #
    # Is the current connection secure?
    #
    set secure_conn_p [expr {[ns_conn isconnected]
                             ? ([security::secure_conn_p] || [ad_conn behind_secure_proxy_p])
                             : 0}]
    #
    # Consider if we are behind a proxy and don't want to publish the
    # proxy's backend port. In this cases, SuppressHttpPort can be used
    #
    set suppress_http_port_p [parameter::get -parameter SuppressHttpPort \
                                -boolean \
                                -package_id [apm_package_id_from_key acs-tcl] \
                                -default 0]
    #
    # Get Information from configured servers
    #
    set locations [acs::misc_cache eval security-configure-locations-$suppress_http_port_p-$secure_conn_p {
        set locations [security::configured_locations -suppress_http_port=$suppress_http_port_p -secure_conn=$secure_conn_p]
        #
        # The configured values values do not change at runtime. Set
        # it also once in the nsv array when setting the cache value.
        #
        foreach location $locations {
            nsv_set validated_location $location 1
        }
        set locations
    }]

    #
    # Add the previously validated locations
    #
    foreach location [nsv_array names validated_location] {
        if {$location ni $locations} {
            lappend locations $location
        }
    }


    #
    # When we are connected, add the current location if is not there
    # already, also potentially in a secure fashion.
    #
    # This is probably not needed, but is kept here for backwards
    # compatibility. For the time being, add log statements when this
    # happens.
    #
    if {[ns_conn isconnected]} {

        set current_location [util_current_location]
        if {$current_location ni $locations} {
            ns_log notice "security::locations add connected location <$current_location>"
            lappend locations $current_location
            nsv_set validated_location $current_location 1
        }

        #
        # When we are on a secure connection, the command above added
        # already a secure connection. When we are on a nonsecure
        # connection, but HTTPS is available, allow as well the
        # current host via the secure connection.
        #
        if {!$secure_conn_p && [https_available_p]} {
            set secure_current_location [security::get_secure_location]
            if {$secure_current_location ni $locations} {
                ns_log notice "security::locations add connected secure location <$secure_current_location>"
                lappend locations $secure_current_location
                nsv_set validated_location $secure_current_location 1
            }
        }
    }

    #ns_log notice "security::locations <$locations>"
    return $locations
}

ad_proc -private security::provided_host_valid {host} {
    Check, if the provided host contains just valid characters.
    Spit warning message out only once per request.
    @param host host from host header field.
} {
    #
    # The per-request cache takes care of outputting error message only
    # once per request.
    #
    return [acs::per_request_cache eval -key acs-tcl.security_provided_host_validated-$host {
        set result 1
        if {$host ne ""} {
            if {![regexp {^[\w.:@+/=$%!*~\[\]-]+$} $host]} {
                #
                # Don't use "ad_log", since this might leed to a recursive loop.
                #
                binary scan [encoding convertto utf-8 $host] H* hex
                ns_log warning "provided host <$host> (hex $hex) contains invalid characters\n\
                       URL: [ns_conn url]\npeer addr:[ad_conn peeraddr]"
                set result 0
            }
        }
        set result
    }]
}

ad_proc security::secure_hostname_p {host} {

    Check, if the content of host is a "secure" value, which means, it
    is either white-listed or belongs to a non-public IP address,
    such it cannot harm in redirect operations.

    @return boolean value
} {
    #
    # If the host has an non-public IP address (such as
    # e.g. "localhost") it is regarded as "secure". The first test is
    # the most simple case, working for all versions of NaviServer or
    # AOLserver.
    #
    if {$host in {localhost 127.0.0.1 ::1}} {
        return 1
    }

    set validationOk 0
    if {[acs::icanuse "ns_ip"]} {
        #
        # Check, if the address is not public. It resolves the
        # $hostName and checks the properties of the first IP address
        # returned.
        #
        try {
            ns_addrbyhost $host
        } on ok {result} {
            set validationOk [expr {![ns_ip public $result]}]
        } on error {errorMsg} {
            ad_log warning "provided value in host header field '$host' could not be resolved"
        }
    }

    return 0
}

ad_proc -public security::validated_host_header {} {
    @return validated host header field or empty
    @author Gustaf Neumann

    Protect against faked or invalid host header fields. Host header
    attacks can lead to web-cache poisoning and password reset attacks
    (for more details, see e.g.
     http://www.skeletonscribe.net/2013/05/practical-http-host-header-attacks.html)
    or to unintended redirects to different sites.

    The validated host header most be syntactically correct, and it
    must be either configured/white-listed or it must be from a
    non-routable IP address. White-listed hosts are taken from the
    alternate host names specified in the "ns/module/DRIVER/servers"
    section, or via the configuration variable "hostname" (e.g.,
    "openacs.org www.openacs.org") which is added the the "/server"
    section during startup.

} {
    #
    # Check, if we have a host header field
    #
    set hostHeaderValue [ns_set iget [ns_conn headers] Host]
    if {$hostHeaderValue eq ""} {
        return ""
    }
    #
    # Domain names are case insensitive. So convert it to lower to
    # avoid surprises.
    #
    set hostHeaderValue [string tolower $hostHeaderValue]

    #
    # Check, if we have validated it before, or it belongs to the
    # predefined accepted host header fields.
    #
    set key ::acs::validated_host_header($hostHeaderValue)
    if {[info exists $key]} {
        return $hostHeaderValue
    }

    try {
        set hostHeaderDict [ns_parsehostport $hostHeaderValue]
    } on error {errorMsg} {
        ns_log [expr {[acs::icanuse "ns_log security"] ? "security" : "warning"}] "security::validated_host_header: $errorMsg"
        return ""
    }
    #
    # Remove trailing dot, as this is allowed in fully qualified DNS
    # names (see e.g. §3.2.2 of RFC 3976).
    #
    set hostName [string trimright [dict get $hostHeaderDict host] .]
    set hostPort [expr {[dict exists $hostHeaderDict port] ? [dict get $hostHeaderDict port] : ""}]

    set normalizedHostHeaderValue [util::join_location -host $hostName -port $hostPort]
    set validationOk 0

    #
    # Check if the value in "hostName" can be regarded as safe.
    #
    # The host header value is one of the names registered for
    # this server.
    #
    if {[acs::icanuse "ns_server hosts"]} {
        if {$normalizedHostHeaderValue in [ns_server hosts]} {
            #
            # New Style host validation, available in new NaviServer 5
            # versions after June 10, 2024
            #
            set validationOk 1
        }
    } elseif {[ns_info name] eq "NaviServer"} {
        #
        # As a replacement for "ns_server hosts" check against the
        # virtual server configuration of NaviServer.
        #
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
                if {$normalizedHostHeaderValue in $names} {
                    ns_log notice "security::validated_host_header: found $hostHeaderValue" \
                        "in global virtual server configuration for $driver"
                    return $normalizedHostHeaderValue
                }
            }
        }
    }

    if {$validationOk == 0} {
        set validationOk [security::secure_hostname_p $hostName]
    }

    if {$validationOk == 0} {
        #
        # Check against the white-listed hosts from
        #
        #     ns_section ns/server/$server/acs {
        #         ns_param whitelistedHosts {...}
        #     }
        #
        # of the configuration file.
        #
        if {$hostHeaderValue in [ns_config "ns/server/[ns_info server]/acs" whitelistedHosts {}]} {
            set validationOk 1
        }
    }

    if {$validationOk == 0} {
        #
        # Check against host node map. Here we need as well protection
        # against invalid utf-8 characters.
        #
        if {![security::provided_host_valid $hostName]} {
            return ""
        }

        set validationOk [db_0or1row host_header_field_mapped {
            select 1 from host_node_map where host = :hostName
        }]
    }

    if {$validationOk == 0} {
        #
        # Validation is OK, when the hostName is either the same as
        # configured hostname. This is a legacy branch for very old
        # versions of NaviServer or AOLserver.
        #
        set driverInfo [util_driver_info]
        set driverHostName [dict get $driverInfo hostname]
        if {$hostName eq $driverHostName} {
            set validationOk 1
        }
    }
    if {$validationOk == 0 && [info exists driverHostName]} {
        #
        # Validation is OK, when the hostName is one of the IP
        # addresses of the configured host name.
        #
        try {
            ns_addrbyhost -all $driverHostName
        } on error {errorMsg} {
            #
            # Name resolution of the hostname configured for this
            # driver failed, we cannot validate incoming IP addresses.
            #
            ns_log error "security::validated_host_header: configuration error:" \
                "name resolution for configured hostname '$driverHostName'" \
                "of driver '[ad_conn driver]' failed"
        } on ok {result} {
            set validationOk [expr {$hostName in $result}]
        }
    }

    #
    # Check, if the provided host is the same in [ns_conn location]
    # (will be used as default, but we do not want a warning in such
    # cases). This is also a legacy case.
    #
    if {$validationOk == 0
        && [util::split_location [ns_conn location] proto locationHost locationPort]} {
        set validationOk [expr {$hostName eq $locationHost}]
    }

    #
    # Check, if the provided host is the same as in the configured
    # SystemURL. Legacy case.
    #
    if {$validationOk == 0 && [util::split_location [ad_url] .proto systemHost systemPort]} {
        set validationOk [expr {$hostName eq $systemHost
                                && ($hostPort eq $systemPort || $hostPort eq "") }]
    }


    #
    # When any of the validation attempts above were successful, we
    # are done. We keep the logic for successful lookups
    # centralized. Performance of the individual tests are not
    # critical, since the lookups are cache per thread.
    #
    if {$validationOk} {
        set $key 1
        return $hostHeaderValue
    }


    #
    # Now we give up
    #
    ns_log warning "ignore untrusted host header field: '$hostHeaderValue'." \
        "Consider adding this value to 'whitelistedHosts' in the" \
        "section 'ns/server/\$server/acs' of your configuration file"

    return ""
}

namespace eval ::security::csp {

    #
    # Generate a nonce token as described in W3C Content Security Policy
    # https://www.w3.org/TR/CSP/
    #
    ad_proc -public ::security::csp::nonce { {-tokenname __csp_nonce} } {

        Generate a nonce token and return it. The nonce token can be used
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
            set secret [ns_config "ns/server/[ns_info server]/acs" parameterSecret ""]

            if {[namespace which ::crypto::hmac] ne ""} {
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
            set var ::__csp__directive_forced($directive)
            if {![info exists $var] || $value ni [set $var]} {
                ns_log notice "CSP: forcing $directive $value"
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
        set nonce [::security::csp::nonce]

        #
        # Add 'self' rules
        #
        security::csp::require default-src 'self'
        security::csp::require script-src 'self'
        #security::csp::require script-src 'strict-dynamic'
        security::csp::require style-src 'self'
        security::csp::require img-src 'self'
        security::csp::require font-src 'self'
        security::csp::require base-uri 'self'
        security::csp::require connect-src 'self'
        #
        # Some browser (safari, chrome) need "font-src data:", maybe
        # for plugins or different font settings. Seems safe enough.
        #
        security::csp::require font-src data:

        #
        # Always add the nonce token to script-src. Note that nonce
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
        # it (e.g. ckeditor4), we have a problem. Therefore, an
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
        # Use newer "report-to" will be preferred and "report-uri"
        # deprecated.  As of May 2020: no support for "report-to" for
        # FF (75, or forthcoming 66 and 77) or Safari.
        # https://caniuse.com/#search=report-to
        #
        security::csp::require report-uri /SYSTEM/csp-collector.tcl
        #ns_set [ns_conn outputheaders] Report-To "{'url':'/SYSTEM/csp-collector.tcl','group':'csp-endpoint','max-age':10886400}"
        #security::csp::require report-to csp-endpoint

        #
        # We do not need object-src
        #
        security::csp::require object-src 'none'

        security::csp::require form-action 'self'
        security::csp::require frame-ancestors 'self'

        #security::csp::require require-trusted-types-for 'script'

        set policy ""
        foreach directive {
            base-uri
            child-src
            connect-src
            default-src
            font-src
            form-action
            frame-ancestors
            frame-src
            img-src
            media-src
            object-src
            plugin-types
            report-uri
            require-trusted-types-for
            sandbox
            script-src
            style-src
            trusted-types
        } {
            set var ::__csp__directive($directive)
            if {[info exists $var]} {
                append policy "$directive [join [set $var] { }];"
            }
        }
        return $policy
    }

    ad_proc -public ::security::csp::add_static_resource_header {
        {-mime_type:required}
    } {

        Set the CSP rule on the current connection for a static
        resource depending on the MIME type.

        @param mime_type MIME type of the resource to be delivered
    } {
        if {![ns_conn isconnected]} {
            error "Content-Security-Policy headers can be only set for active connections"
        }
        if {[dict exists $::security::csp::static_csp $mime_type]} {
            ns_set iupdate [ns_conn outputheaders] \
                "Content-Security-Policy" [dict get $::security::csp::static_csp $mime_type]
            ns_log notice "STATIC $mime_type: Content-Security-Policy [dict get $::security::csp::static_csp $mime_type]"
        } else {
            #ns_log notice "STATIC $mime_type: no Content-Security-Policy defined for this MIME type"
        }
    }
}

namespace eval ::security::parameter {

    ad_proc -public signed {{-max_age ""} value} {

        Compute a compact single-token signed value based on the
        parameterSecret.

        @see ::security::parameter::validated
    } {
        set token_id [sec_get_random_cached_token_id]
        set secret [ns_config "ns/server/[ns_info server]/acs" parameterSecret ""]
        set signature [ad_sign -max_age $max_age -secret $secret -token_id $token_id $value]
        return [ns_base64urlencode [list $value $signature]]
    }

    ad_proc -public validated {input} {

        Validate the single-token signed value and return its content value.
        Raise an exception, when the signature is broken.

        @see ::security::parameter::signed

    } {
        set success 0
        set pair [ns_base64urldecode $input]
        if {[string is list -strict $pair] && [llength $pair] == 2} {
            lassign $pair value signature
            set secret [ns_config "ns/server/[ns_info server]/acs" parameterSecret ""]
            set success [ad_verify_signature -secret $secret $value $signature]
        }
        if {$success} {
            return $value
        } else {
            ad_raise invalid_signature
        }
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

    ad_proc -public ::security::csrf::new {
        {-tokenname __csrf_token}
        -user_id
    } {

        Create a security token to protect against CSRF (Cross-Site
        Request Forgery).  The token is set (and cached) in a global
        per-thread variable and can be included in forms e.g. via the
        following command.
        <p>
        <pre>
        &lt;if @::__csrf_token@ defined&gt;
            &lt;input type="hidden" name="__csrf_token" value="@::__csrf_token;literal@"&gt;
        &lt;/if&gt;
</pre><p>
        The token is automatically cleared together with other global
        variables at the end of the processing of every request.
<p>
        The optional argument user_id is currently ignored, but it is
        there, since there are algorithms published to calculate the
        CSRF token based on a user_id. So far, i found no evidence
        that these should be used, but the argument is there as a
        reminder, such the interface does not have to be used, when we
        switch to such an algorithm.

        @return CSRF token

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
    ad_proc -public ::security::csrf::validate {
        {-tokenname __csrf_token}
        {-allowempty false}
    } {

        Validate a CSRF token and call security::csrf::fail the
        request if invalid.

        @return nothing
    } {
        if {![info exists ::$tokenname] || ![ns_conn isconnected]} {
            #
            # If there is no global CSRF token, or we are not in a
            # connection thread, we accept everything.  If there is
            # no CSRF token, we assume, that its generation is
            # deactivated,
            #
            return
        }

        set oldToken [ns_queryget $tokenname]
        if {$oldToken eq ""} {
            #
            # There is no token in the query/form parameters, we
            # can't validate, since there is no token.
            #
            if {$allowempty} {
                return
            }
            fail
        }

        set token [token -tokenname $tokenname]

        if {$oldToken ne $token} {
            ::security::log session_id "CSRF old token <$oldToken> new token <$token> peeraddr [ad_conn peeraddr]"
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
            ::security::log session_id "GET CSRF token: Anonymous request -> $session_id"
        } else {
            #
            # User is logged-in, use a session token.
            #
            set session_id [ad_conn session_id]
            ::security::log session_id "GET CSRF token: authenticated request -> $session_id"
        }
        return $session_id
    }

    #
    # Generate CSRF token
    #
    ad_proc -private ::security::csrf::token {
        {-tokenname __csrf_token}
    } {

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
            set secret [ns_config "ns/server/[ns_info server]/acs" parameterSecret ""]
            ::security::log session_id "CSRF token: create token based on [session_id]"

            if {[namespace which ::crypto::hmac] ne ""} {
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

        This function is called, when a CSRF validation fails. Unless the
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

nsv_set validated_location http://localhost 1

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
