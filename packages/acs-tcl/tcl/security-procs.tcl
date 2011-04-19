ad_library {

    Provides methods for authorizing and identifying ACS users
    (both logged in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @author Richard Li (richardl@arsdigita.com)
    @author Archit Shah (ashah@arsdigita.com)
    @cvs-id $Id$
}

namespace eval security {}

# cookies (all are signed cookies):
#   cookie                value                          max-age         secure
#   ad_session_id         session_id,user_id,login_level SessionTimeout  no
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
    # tcl_sec_seed is used to maintain a small subset of the previously
    # generated random token to use as the seed for the next
    # token. this makes finding a pattern in sec_random_token harder
    # to guess when it is called multiple times in the same thread.
    global tcl_sec_seed

    if { [ad_conn -connected_p] } {
        set request [ad_conn request]
	set start_clicks [ad_conn start_clicks]
    } else {
	set request "yoursponsoredadvertisementhere"
	set start_clicks "cvs.openacs.org"
    }
    
    if { ![info exists tcl_sec_seed] } {
	set tcl_sec_seed "listentowmbr89.1"
    }

    set random_base [ns_sha1 "[ns_time][ns_rand]$start_clicks$request$tcl_sec_seed"]
    set tcl_sec_seed [string range $random_base 0 10]
    
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

ad_proc -private sec_handler {} {

    Reads the security cookies, setting fields in ad_conn accordingly.

} {
    ns_log debug "OACS= sec_handler: enter"

    #foreach c [list ad_session_id ad_secure_token ad_user_login ad_user_login_secure] {
    #    lappend msg "$c [ad_get_cookie $c]"
    #}
    #ns_log notice "OACS cookies: $msg"

    if { [catch { 
	set cookie_list [ad_get_signed_cookie "ad_session_id"]
    } errmsg ] } {
	# Cookie is invalid because either:
	# -> it was never set
	# -> it failed the cryptographic check
	# -> it expired.

        # Now check for login cookie
        ns_log Debug "OACS: Not a valid session cookie, looking for login cookie '$errmsg'"
        ad_user_logout
        sec_login_handler
    } else {
	# The session cookie already exists and is valid.
	set cookie_data [split [lindex $cookie_list 0] {,}]
	set session_last_renew_time [lindex $cookie_data 3]
    if {![string is integer -strict $session_last_renew_time]} {
        # This only happens if the session cookie is old style
        # previous to openacs 5.7 and does not have session review time
        # embedded.
        # Assume cookie expired and force login handler
        set session_last_renew_time 0
    }
    
    set session_expr [expr {$session_last_renew_time + [sec_session_timeout]}]
    
    if {$session_expr < [ns_time]} {
        sec_login_handler
    }
               
	set session_id [lindex $cookie_data 0]
	set untrusted_user_id [lindex $cookie_data 1]
	set login_level [lindex $cookie_data 2]
        set user_id 0
        set account_status closed
        
        switch $login_level {
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

        ns_log Debug "Security: Insecure session OK: session_id = $session_id, untrusted_user_id = $untrusted_user_id, auth_level = $auth_level, user_id = $user_id"

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
            ns_log Debug "Security: Secure session checked: session_id = $session_id, untrusted_user_id = $untrusted_user_id, auth_level = $auth_level, user_id = $user_id"
        }

        # Setup ad_conn
	ad_conn -set session_id $session_id
        ad_conn -set untrusted_user_id $untrusted_user_id
        ad_conn -set user_id $user_id
        ad_conn -set auth_level $auth_level
        ad_conn -set account_status $account_status

	# reissue session cookie so session doesn't expire if the
	# renewal period has passed. this is a little tricky because
	# the cookie doesn't know about sec_session_renew; it only
	# knows about sec_session_timeout.
	# [sec_session_renew] = SessionTimeout - SessionRenew (see security-init.tcl)
	# $session_expr = PreviousSessionIssue + SessionTimeout
	if { $session_expr - [sec_session_renew] < [ns_time] } {
            
            # LARS: We abandoned the use of sec_login_handler here. This lets people stay logged in forever
	    # if only the keep requesting pages frequently enough, but the alternative was that 
	    # the situation where LoginTimeout = 0 (infinte) and the user unchecks the "Remember me" checkbox
	    # would cause users' sessions to expire as soon as the session needed to be renewed
	    sec_generate_session_id_cookie
	}
    }
}

ad_proc -private sec_login_read_cookie {} {

    Fetches values either from ad_user_login_secure or ad_user_login,
    depending whether we are in a secured connection or not.
    
    @author Victor Guerra 

    @return List of values read from cookie ad_user_login_secure or ad_user_login
} {
    # If over HTTPS, we look for a secure cookie, otherwise we look for the normal one
    set login_list [list]
    if { [security::secure_conn_p] } {
	catch {
	    set login_list [split [ad_get_signed_cookie "ad_user_login_secure"] ","]
	}
    } 
    if { $login_list eq "" } {
	set login_list [split [ad_get_signed_cookie "ad_user_login"] ","]
    }
    return $login_list
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
	set login_list [sec_login_read_cookie]
        
        set untrusted_user_id [lindex $login_list 0]
        set login_expr [lindex $login_list 1]
        set auth_token [lindex $login_list 2]
        
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

    set domain [parameter::get -parameter CookieDomain -package_id [ad_acs_kernel_id]]

    # If you're logged in over a secure connection, you're secure
    if { [security::secure_conn_p] } {
        ad_set_signed_cookie \
            -max_age $max_age \
            -secure t \
	    -domain $domain \
            ad_user_login_secure \
            "$user_id,[ns_time],[sec_get_user_auth_token $user_id],[ns_time],$forever_p"

        # We're secure
        set auth_level "secure"
    } elseif { $prev_user_id != $user_id } {
        # Hose the secure login token if this user is different 
        # from the previous one.
        ad_set_cookie -max_age 0 ad_user_login_secure ""
    }
    
    ns_log Debug "ad_user_login: Setting new ad_user_login cookie with max_age $max_age"
    ad_set_signed_cookie \
        -max_age $max_age \
	-domain $domain \
        -secure f \
        ad_user_login \
        "$user_id,[ns_time],[sec_get_user_auth_token $user_id],$forever_p"

    # deal with the current session
    sec_setup_session $user_id $auth_level $account_status
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
    Change the user's auth_token, which invalidates all existing login cookies, ie. forces user logout at the server.
} {
    set auth_token [ad_generate_random_string]

    ns_log Debug "Security: Changing user $user_id's auth_token to '$auth_token'"
    db_dml update_auth_token {
        update users set auth_token = :auth_token where user_id = :user_id
    }
    db_release_unused_handles

    return $auth_token
}


ad_proc -public ad_user_logout {} { 
    Logs the user out. 
} {
    set domain [parameter::get -parameter CookieDomain -package_id [ad_acs_kernel_id]]

    ad_set_cookie -replace t -max_age 0 -domain $domain ad_session_id ""
    ad_set_cookie -replace t -max_age 0 -domain $domain ad_secure_token ""
    ad_set_cookie -replace t -max_age 0 -domain $domain ad_user_login ""
    ad_set_cookie -replace t -max_age 0 -domain $domain ad_user_login_secure ""
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

        if { $prev_user_id != 0 && $prev_user_id != $new_user_id } {
            # this is a change in identity so we should create
            # a new session so session-level data is not shared
            set session_id [sec_allocate_session]
        }

        if { $prev_user_id != $new_user_id } {
            # a change of user_id on an active session
            # demands an update of the users table
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

    sec_generate_session_id_cookie

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
    db_dml update_last_visit {
        update users
        set second_to_last_visit = last_visit,
            last_visit = sysdate,
            n_sessions = n_sessions + 1
        where user_id = :user_id
    }
    db_release_unused_handles
}

ad_proc -private sec_generate_session_id_cookie {} { 
    Sets the ad_session_id cookie based on global variables. 
} {
    set user_id [ad_conn untrusted_user_id]
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

    set domain [parameter::get -parameter CookieDomain -package_id [ad_acs_kernel_id]]

    # we fetch the last value element of ad_user_login cookie (or ad_user_login_secure) that indicates
    # if user wanted to be remembered when loggin in
    set discard t
    set max_age [sec_session_timeout]
    catch { 
	    set login_list [sec_login_read_cookie]
      	if {[lindex $login_list end] == 1} {
	        set discard f
            set max_age inf
	    }
    }
    ad_set_signed_cookie -discard $discard -replace t -max_age $max_age -domain $domain \
	    "ad_session_id" "$session_id,$user_id,$login_level,[ns_time]"
}

ad_proc -private sec_generate_secure_token_cookie { } { 
    Sets the ad_secure_token cookie.
} {
    ad_set_signed_cookie -secure t "ad_secure_token" "[ad_conn session_id],[ns_time],[ad_conn peeraddr]"
}

ad_proc -public -deprecated -warn ad_secure_conn_p {} { 
    Use security::secure_conn_p instead.
    
    @see security::secure_conn_p
} {
    return [security::secure_conn_p]
}

ad_proc -private sec_allocate_session {} {

    Returns a new session id

} {
    
    global tcl_max_value
    global tcl_current_sequence_id

    if { ![info exists tcl_max_value] || ![info exists tcl_current_sequence_id] || $tcl_current_sequence_id > $tcl_max_value } {
	# Thread just spawned or we exceeded preallocated count.
	set tcl_current_sequence_id [db_nextval sec_id_seq]
	db_release_unused_handles
	set tcl_max_value [expr {$tcl_current_sequence_id + 100}]
    } 

    set session_id $tcl_current_sequence_id
    incr tcl_current_sequence_id

    return $session_id
}

ad_proc -private ad_login_page {} {
    
    Returns 1 if the page is used for logging in, 0 otherwise. 

} {

    set url [ad_conn url]
    if { [string match "*register/*" $url] || [string match "/index*" $url] || \
            [string match "/index*" $url] || \
            "/" eq $url || \
            [string match "*password-update*" $url] } {
	return 1
    }

    return 0
}






#####
#
# Login/logout URLs, redirecting, etc.
#
#####

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
}

ad_proc -public ad_get_login_url {
    -authority_id
    -username
    -return:boolean
} {
    
    Returns a URL to the login page of the closest subsite, or the main site, if there's no current connection.
    
    @option return      If set, will export the current form, so when the registration is complete, 
                        the user will be returned to the current location.  All variables in 
                        ns_getform (both posts and gets) will be maintained.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [ad_conn isconnected] } {
        set url [subsite::get_element -element url]

        # Check to see that the user (most likely "The Public" party, since there's probably no user logged in)
        # actually have permission to view that subsite, otherwise we'll get into an infinite redirect loop
        array set site_node [site_node::get_from_url -url $url]
        set package_id $site_node(object_id)
        if { ![permission::permission_p -no_login -object_id $site_node(object_id) -privilege read -party_id 0] } {
            set url /
        }
    } else {
        set url /
    }

    set UseHostnameDomainforReg [parameter::get -package_id [apm_package_id_from_key acs-tcl] -parameter UseHostnameDomainforReg -default 0]
    if { $UseHostnameDomainforReg } {

        # get config.tcl's hostname
        set nssock [ns_config ns/server/[ns_info server]/modules nssock]
        set nsunix [ns_config ns/server/[ns_info server]/modules nsunix]
        if {$nsunix ne ""} {
            set driver nsunix
        } else {
            set driver nssock
        }
        set config_hostname [ns_config ns/server/[ns_info server]/module/$driver Hostname]
        set current_location [util_current_location]
        # if current domain and hostdomain are different (and UseHostnameDomain), revise url
        if { ![string match -nocase "*${config_hostname}*" $current_location] } {

            if { [string range $url 0 0] eq "/" } {
                # Make the url fully qualified
                if { [security::secure_conn_p] } {
                    set url_decoded [security::get_secure_qualified_url $url]
                } else {
                    set url_decoded [security::get_insecure_qualified_url $url]
                }
            } else {
                set url_decoded $url
            }

            # revise url to use hostname's domain
            # if url points to a non / host_node, redirect to main hostname
            set host_node_map_hosts_list [db_list -cache_key security-locations-host-names get_node_host_names "select host from host_node_map"]
            if { [llength $host_node_map_hosts_list] > 0 } {
                foreach hostname $host_node_map_hosts_list {
                    if { [string match -nocase "http://${hostname}*" $url_decoded] || [string match -nocase "https://${hostname}*" $url_decoded] } {
                        db_1row get_node_id_from_host_name "select node_id as host_node_id from host_node_map where host = :hostname"
                        # site node already in url, so just switching domain.
                        if { ![regsub -- "${hostname}" $url_decoded "${config_hostname}" url_decoded] } {
                            ns_log Warning "ad_get_login_url(ref619): regsub was unable to modify url to hostname's domain. User may not appear to be logged-in after login. url_decoded: ${url_decoded} url: ${url}"
                        } 
                    }
                }
            }
            set url $url_decoded
        }
    }


    append url "register/"

    set export_vars [list]
    if { [exists_and_not_null authority_id] } {
        lappend export_vars authority_id
        
    }
    if { [exists_and_not_null username] } {
        lappend export_vars username
        
    }

    # We don't add a return_url if you're currently under /register, because that will frequently
    # interfere with normal login procedure
    if { [ad_conn isconnected] && $return_p && ![string match "register/*" [ad_conn extra_url]] } {
        if { [security::secure_conn_p] || ![security::RestrictLoginToSSLP] } {
            set return_url [ad_return_url]
        } else {
            set return_url [ad_return_url -qualified]
        }

        if { $UseHostnameDomainforReg } {
            # if current domain and hostdomain are different (and UseHostnameDomainforReg), revise return_url
            if { ![string match -nocase "*${config_hostname}*" $current_location] } {
                
                if { [string range $return_url 0 0] eq "/" } {
                    # Make the return_url fully qualified
                    if { [security::secure_conn_p] } {
                        set return_url_decoded [security::get_secure_qualified_url $return_url]
                    } else {
                        set return_url_decoded [security::get_insecure_qualified_url $return_url]
                    }
                } else {
                    set return_url_decoded $return_url
                }
                # revise return_url to use hostname's domain
                # if return_url points to a non / host_node, redirect to main hostname
                set host_node_map_hosts_list [db_list -cache_key security-locations-host-names get_node_host_names "select host from host_node_map"]
                if { [llength $host_node_map_hosts_list] > 0 } {
                    foreach hostname $host_node_map_hosts_list {
                        if { [string match -nocase "http://${hostname}*" $return_url_decoded] || [string match -nocase "https://${hostname}*" $return_url_decoded] } {
                            db_1row get_node_id_from_host_name "select node_id as host_node_id from host_node_map where host = :hostname"
                            if { ![regsub -- "${hostname}" $return_url_decoded "${config_hostname}[site_node::get_url -node_id ${host_node_id} -notrailing]" return_url_decoded] } {
                                ns_log Warning "ad_get_login_url(ref672): regsub was unable to modify return_url to hostname's domain. User may not appear to be logged-in after login. return_url_decoded: ${return_url_decoded} return_url: ${return_url}"
                            } 
                        }
                    }
                }
                set return_url $return_url_decoded
            }
        }


        lappend export_vars { return_url }
    }

    if { [llength $export_vars] > 0 } {
        set url [export_vars -base $url $export_vars]
    }

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
    if { [ad_conn isconnected] } {
        set url [subsite::get_element -element url]
    } else {
        set url /
    }

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
    if {"/favicon.ico" ne [ad_conn url] && "/index.tcl" ne [ad_conn url] && "/" ne [ad_conn url] && ![string match "/global/*" [ad_conn url]] && ![string match "*/register/*" [ad_conn url]] && ![string match "*/SYSTEM/*" [ad_conn url]] && ![string match "*/user_please_login.tcl" [ad_conn url]]} {
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

    if { $secret eq "" } {
        if {$token_id eq ""} { 
            # pick a random token_id
            set token_id [sec_get_random_cached_token_id]
        }
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
    set token_id [lindex $signature 0]
    set expire_time [lindex $signature 1]
    set hash [lindex $signature 2]

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
    set token_id [lindex $signature 0]
    set expire_time [lindex $signature 1]
    set hash [lindex $signature 2]

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
    cryptographic signature and insures that the cookie has not
    expired. Throws an exception if validation fails.

} {

    if { $include_set_cookies eq "t" } {
	set cookie_value [ns_urldecode [ad_get_cookie $name]]
    } else {
	set cookie_value [ns_urldecode [ad_get_cookie -include_set_cookies f $name]]
    }

    if { $cookie_value eq "" } {
	error "Cookie does not exist."
    }

    set value [lindex $cookie_value 0]
    set signature [lindex $cookie_value 1]

    ns_log Debug "ad_get_signed_cookie: Got signed cookie $name with value $value, signature $signature."

    if { [ad_verify_signature $value $signature] } {
	ns_log Debug "ad_get_signed_cookie: Verification of cookie $name OK"
	return $value
    }

    ns_log Debug "ad_get_signed_cookie: Verification of cookie $name FAILED"
    error "Cookie could not be authenticated."
}

ad_proc -public ad_get_signed_cookie_with_expr {
    {-include_set_cookies t}
    {-secret ""}
    name
} { 

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and insures that the cookie has not
    expired. Returns a two-element list, the first element of which is
    the cookie data, and the second element of which is the expiration
    time. Throws an exception if validation fails.

} {

    if { $include_set_cookies eq "t" } {
	set cookie_value [ns_urldecode [ad_get_cookie $name]]
    } else {
	set cookie_value [ns_urldecode [ad_get_cookie -include_set_cookies f $name]]
    }

    if { $cookie_value eq "" } {
	error "Cookie does not exist."
    }

    set value [lindex $cookie_value 0]
    set signature [lindex $cookie_value 1]

    set expr_time [ad_verify_signature_with_expr $value $signature]

    ns_log Debug "Security: Done calling get_cookie $cookie_value for $name; received $expr_time expiration, getting $value and $signature."

    if { $expr_time } {
	return [list $value $expr_time]
    }

    error "Cookie could not be authenticated."
}

ad_proc -public ad_set_signed_cookie {
    {-replace f}
    {-secure f}
    {-discard f}
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

    set data [ns_urlencode [list $value $cookie_value]]

    ad_set_cookie -replace $replace -secure $secure -discard $discard -max_age $max_age -domain $domain -path $path $name $data
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
    the thread-persistent TCL cache, then checks the server
    size-limited cache before finally hitting the db in the worst case
    if the secret_token value is not in either cache. The procedure
    also updates the caches.

    Cache eviction is handled by the ns_cache API for the size-limited
    cache and is handled by AOLserver (via thread termination) for the
    thread-persistent TCL cache.

} {
    
    global tcl_secret_tokens

    if { [info exists tcl_secret_tokens($token_id)] } {
	return $tcl_secret_tokens($token_id)
    } else {
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

	set tcl_secret_tokens($token_id) $token
	return $token
	
    }

}

ad_proc -private sec_get_random_cached_token_id {} {
    
    Randomly returns a token_id from the ns_cache.

} {
 
    set list_of_names [ns_cache names secret_tokens]
    set random_seed [ns_rand [llength $list_of_names]]

    return [lindex $list_of_names $random_seed]
    
}

ad_proc -private populate_secret_tokens_cache {} {
    
    Randomly populates the secret_tokens cache.

} {

    set num_tokens [parameter::get -package_id [ad_acs_kernel_id] -parameter NumberOfCachedSecretTokens -default 100]

    # this is called directly from security-init.tcl,
    # so it runs during the install before the data model has been loaded
    if { [db_table_exists secret_tokens] } {
	db_foreach get_secret_tokens {
	    select * from (
	    select token_id, token
	    from secret_tokens
	    sample(15)
	    ) where rownum < :num_tokens
	} {
	    ns_cache set secret_tokens $token_id $token
	}
    }
    db_release_unused_handles
}

ad_proc -private populate_secret_tokens_db {} {

    Populates the secret_tokens table. Note that this will take awhile
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
    particular property from the database. Returns
    [list $property_value $secure_p].

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
    Looks up a property for a session. If $cache is true, will use the
    cached value if available. If $cache_only is true, will never
    incur a database hit (i.e., will only return a value if
    cached). If the property is secure, we must be on a validated session
    over SSL.

    @param session_id controls which session is used

} {
    if { $session_id eq "" } {
        set id [ad_conn session_id]
        
        # if session_id is still undefined in the connection then we 
        # should just return the default
        if { $id eq "" } {
            return $default
        }
    } else {
        set id $session_id
    }

    set cmd [list sec_lookup_property $id $module $name]

    if { $cache_only eq "t" && ![util_memoize_cached_p $cmd] } {
	return ""
    }

    if { $cache ne "t" } {
	util_memoize_flush $cmd
    }

    set property [util_memoize $cmd [sec_session_timeout]]
    if { $property eq "" } {
	return $default
    }
    set value [lindex $property 0]
    set secure_p [lindex $property 1]
    
    if { $secure_p ne "f" && ![security::secure_conn_p] } {
	return ""
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
    Sets a client (session-level) property. If $persistent is true,
    the new value will be written through to the database. If
    $deferred is true, the database write will be delayed until
    connection close (although calls to ad_get_client_property will
    still return the correct value immediately). If $secure is true,
    the property will not be retrievable except via a validated,
    secure (HTTPS) connection.

    @param session_id controls which session is used
    @param clob tells us to use a large object to store the value

} {

    if { $secure ne "f" && ![security::secure_conn_p] } {
	error "Unable to set secure property in insecure or invalid session"
    }

    if { $session_id eq "" } {
        set session_id [ad_conn session_id]
    }

    if { $persistent eq "t" } {
        # Write to database - either defer, or write immediately. First delete the old
        # value if any; then insert the new one.
	
	set last_hit [ns_time]

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

            if { $clob eq "t" && $clob_update_dml ne "" } {
                db_dml prop_update_dml_clob "" -clobs [list $value]
            } else {
                db_dml prop_update_dml ""
	    }
	}
    }

    # Remember the new value, seeding the memoize cache with the proper value.
    util_memoize_seed [list sec_lookup_property $session_id $module $name] [list $value $secure]
}








#####
#
# Deprecated procs
#
#####

ad_proc -public -deprecated ad_get_user_id {} {
    Gets the user ID. 0 indicates the user is not logged in.

    Deprecated since user_id now provided via ad_conn user_id

    @see ad_conn
} {
    return [ad_conn user_id]
}

ad_proc -public -deprecated -warn ad_verify_and_get_user_id { 
    {-secure f}
} {
    Returns the current user's ID. 0 indicates user is not logged in

    Deprecated since user_id now provided via ad_conn user_id

    @see ad_conn
} {
    return [ad_conn user_id]
}

# handling privacy

ad_proc -public -deprecated ad_privacy_threshold {} {
    Pages that are consider whether to display a user's name or email
    address should test to make sure that a user's priv_ from the
    database is less than or equal to what ad_privacy_threshold returns.
    
    Now deprecated.

    @see  ad_conn
} {
    set session_user_id [ad_get_user_id]
    if {$session_user_id == 0} {
	# viewer of this page isn't logged in, only show stuff 
	# that is extremely unprivate
	set privacy_threshold 0
    } else {
	set privacy_threshold 5
    }
    return $privacy_threshold
}

ad_proc -deprecated ad_maybe_redirect_for_registration {} {

    Checks to see if a user is logged in.  If not, redirects to
    [subsite]/register/index to require the user to register.
    When registration is complete, the user will return to the current
    location. All variables in ns_getform (both posts and gets) will
    be maintained. Note that this will return out of its caller so that
    the caller need not explicitly call "return". Returns the user id
    if login was succesful.

    @see auth::require_login
} {
    auth::require_login
}



#####
#
# security namespace public procs
#
#####

ad_proc -public security::https_available_p {} {
    Return 1 if AOLserver is configured to support HTTPS and 0 otherwise.

    @author Peter Marklund
} {
    return [expr ![empty_string_p [get_https_port]]]
}

ad_proc -public security::secure_conn_p {} { 
    Returns true if the connection [ad_conn] is secure (HTTPS), or false otherwise. 
} {
    return [string match "https:*" [util_current_location]]
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
    if { ![https_available_p] } {
        return
    } 

    if { ![security::secure_conn_p] } {
        security::redirect_to_secure [ad_return_url -qualified]
    }
}

ad_proc -public security::redirect_to_secure {
    url 
} {
    Redirect to the given URL and enter secure (HTTPS) mode.    
    Does nothing if the server is not configured for HTTPS support.

    @author Peter Marklund
} {
    if { ![https_available_p] } {
        return
    } 

    set secure_url [get_secure_qualified_url $url]

    ad_returnredirect $secure_url
    ad_script_abort
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
    Return the HTTPS port specified in the AOLserver config file.
    
    @return The HTTPS port or the empty string if none is configured.

    @author Peter Marklund
} {
    set secure_port ""

   # decide if we are using nsssl or nsopenssl or nsssle, favor nsopenssl
    set nsssl [ns_config ns/server/[ns_info server]/modules nsssl]
    set nsopenssl [ns_config ns/server/[ns_info server]/modules nsopenssl]
    set nsssle [ns_config ns/server/[ns_info server]/modules nsssle]
    if { $nsopenssl ne "" } {
        set sdriver nsopenssl
    } elseif { $nsssl ne "" } {
        set sdriver nsssl
    } elseif { $nsssle ne "" } {
        set sdriver nsssle
    } else {
        return ""
    }
     # ec_secure_location
    # nsopenssl 3 has variable locations for the secure port, openacs standardized at:
    set secure_port [ns_config -int "ns/server/[ns_info server]/module/$sdriver/ssldriver/users" port 443]
    # nsssl, nsssle etc
    if {$secure_port eq ""} {
        set secure_port [ns_config -int "ns/server/[ns_info server]/module/$sdriver" port]
    }
    # checking nsopenssl 2.0 which has different names for the secure port etc, and is not supported with this version of OpenACS
    if {$secure_port eq "" || $secure_port eq "443"} {
        set secure_port [ns_config -int "ns/server/[ns_info server]/module/$sdriver" ServerPort 443]
    }

    return $secure_port
}

ad_proc -private security::get_secure_qualified_url { url } {
    Given a relative or qualified url, return the fully qualified
    HTTPS version.

    @author Peter Marklund
} {
    # Get part of URL after location
    set qualified_uri [get_qualified_uri $url]

    set secure_url [get_secure_location]${qualified_uri}

    return $secure_url
}

ad_proc -private security::get_insecure_qualified_url { url } {
    Given a relative or qualified url, return the fully qualified
    HTTP version.

    @author Peter Marklund
} {
    # Get part of URL after location
    set qualified_uri [get_qualified_uri $url]

    set insecure_url [get_insecure_location]${qualified_uri}

    return $insecure_url    
}

ad_proc -private security::get_uri_part { url } {
    Get the URI following the location of the given URL. Assumes
    the given URL has the http or https protocol or is a relative
    URL.

    @author Peter Marklund
} {
    regexp {^(?:http://[^/]+)?(.*)} $url match uri

    return $uri
}

ad_proc -private security::get_qualified_uri { url } {
    
} {
    set uri [get_uri_part $url]

    if { ![regexp {^/} $uri] } {
        # Make relative URI qualified
        set qualified_uri [ad_conn url]/$uri
    } else {
        set qualified_uri $uri
    }

    return $qualified_uri
}

ad_proc -private security::get_secure_location {} {
    Return the current location in secure (https) mode.
    
    @author Peter Marklund
} {
    set current_location [util_current_location]
    set https_prefix {https://}

    if { [regexp $https_prefix $current_location] } {
        # Current location is already secure - do nothing
        set secure_location $current_location
    } else {
        # Current location is insecure - get location from config file
	set secure_location [ad_conn location]
	# Prefix with https
        regsub {^(?:http://)?} $secure_location {https://} secure_location

	# remove port number if using nonstandard port
        regexp {^(.*:.*):([0-9]+)} $secure_location match secure_location port

        # Add port number if non-standard
        set https_port [get_https_port]
        if { $https_port ne "443" } {
            set secure_location ${secure_location}:$https_port
        }

    }

    return $secure_location
}

ad_proc -private security::get_insecure_location {} {
    Return the current location in insecure mode (http).

    @author Peter Marklund
} {
    set current_location [util_current_location]
    set http_prefix {http://}

    if { [regexp $http_prefix $current_location] } {
        # Current location is already insecure - do nothing
        set insecure_location $current_location
    } else {
        # Current location is secure - use location from config file
        set insecure_location [ad_conn location]
        regsub -all {https://} $insecure_location "" insecure_location
        if { ![regexp $http_prefix $insecure_location] } {
            # Prepend http://
            set insecure_location ${http_prefix}${insecure_location}
        }
    }

    return $insecure_location
}

ad_proc -public security::locations {} {
    @return insecure location and secure location followed possibly by alternate insecure location(s)  as a list.

    The location consists of protocol://domain:port for website. This proc is ported from ec_insecure_location and ec_secure_location for reliably getting locations.  If acs-tcl's SuppressHttpPort parameter is true, then the alternate ec_insecure_location without port is appended to the list, since it is a valid alternate.  This proc also assumes hostnames from host_node_map table are accurate and legit.
} {
    set locations [list]
    # following from ec_preferred_drivers
    set driver ""
    set sdriver ""
    if {[ns_conn isconnected]} {
        set hdrs [ns_conn headers]
        set host [ns_set iget $hdrs host]
        if {$host eq ""} {
            set driver nssock
        } 
    }
    #   Determine nssock or nsunix
    if {$driver eq ""} {
        # decide if we're using nssock or nsunix
        set nssock [ns_config ns/server/[ns_info server]/modules nssock]
        set nsunix [ns_config ns/server/[ns_info server]/modules nsunix]
        if {$nsunix ne ""} {
            set driver nsunix
        } else {
            set driver nssock
        }
    }
    
    # decide if we are using nsssl or nsopenssl, favor nsopenssl
    set nsssl [ns_config ns/server/[ns_info server]/modules nsssl]
    set nsopenssl [ns_config ns/server/[ns_info server]/modules nsopenssl]
    set nsssle [ns_config ns/server/[ns_info server]/modules nsssle]
    if { $nsopenssl ne ""} {
        set sdriver nsopenssl
    } elseif { $nsssl ne ""} {
        set sdriver nsssl
    } elseif { $nsssle ne "" } {
        set sdriver nsssle
    } else {
        set sdriver ""
    }

    # set the driver results
    array set drivers [list driver $driver sdriver $sdriver]
    set driver $drivers(driver)

    # check if port number is included here, we'll reattach it after
    # the request if its a non-standard port. Since we build the
    # secure url from this host name we need to replace the port with
    # the secure port
    set host_post ""

    # set host_name
    if {![regexp {(http://|https://)(.*?):(.*?)/?} [util_current_location] discard host_protocol host_name host_port]} {
        regexp {(http://|https://)(.*?)/?} [util_current_location] discard host_protocol host_name
    }
    # let's give a warning if util_current_location returns host_name
    # not same as from config.tcl, may help with proxy issues etc
    set config_hostname [ns_config ns/server/[ns_info server]/module/$driver Hostname]
    if { $config_hostname ne $host_name } {
        ns_log Warning "security::locations hostname '[ns_config ns/server/[ns_info server]/module/$driver Hostname]' from config.tcl does not match from util_current_location: $host_name"
    }

    # insecure locations
    set insecure_port [ns_config -int "ns/server/[ns_info server]/module/$driver" port 80]

    set insecure_location "http://${host_name}"
    set host_map_http_port ""
    if { $insecure_port ne "" && $insecure_port ne 80 } {
        set alt_insecure_location $insecure_location
        append insecure_location ":$insecure_port"
        set host_map_http_port ":$insecure_port"
    }

    # secure location, favoring nsopenssl
    # nsopenssl 3 has variable locations for the secure port, openacs standardized at:
    if { $sdriver eq "nsopenssl" } {
        set secure_port [ns_config -int "ns/server/[ns_info server]/module/$sdriver/ssldriver/users" port 443]
    } elseif { $sdriver ne "" } {
        # get secure port for all other cases of nsssl, nsssle etc
        set secure_port [ns_config -int "ns/server/[ns_info server]/module/$sdriver" port]
        # checking nsopenssl 2.0 which has different names for the secure port etc, and deprecated with this version of OpenACS
        if {$secure_port eq "" || $secure_port eq "443" } {
            set secure_port [ns_config -int "ns/server/[ns_info server]/module/$sdriver" ServerPort 443]
        }
    } else {
        set secure_port ""
    }

    lappend locations $insecure_location
    # if we have a secure location, add it
    set host_map_https_port ""

    if { $sdriver ne "" } {
        set secure_location "https://${host_name}"
        if {$secure_port ne "" && $secure_port ne "443"}  {
            append secure_location ":$secure_port"
            set host_map_https_port ":$secure_port"
        }
        lappend locations $secure_location
    }
    # consider if we are behind a proxy and don't want to publish the proxy's backend port
    set suppress_http_port [parameter::get -parameter SuppressHttpPort -package_id [apm_package_id_from_key acs-tcl] -default 0]
    if { [info exists alt_insecure_location] && $suppress_http_port } {
        lappend locations $alt_insecure_location
    }

    # add locations from host_node_map 
    set host_node_map_hosts_list [db_list -cache_key security-locations-host-names get_node_host_names "select host from host_node_map"]
    # fastest place for handling this special case:
    if { $config_hostname ne $host_name } {
        ns_log Notice "security::locations adding $config_hostname since utl_current_location different than config.tcl."
        lappend host_node_map_hosts_list $config_hostname
    }
    if { [llength $host_node_map_hosts_list] > 0 } {
        if { $suppress_http_port } {
            foreach hostname $host_node_map_hosts_list {
                lappend locations "http://${hostname}"
                lappend locations "https://${hostname}${host_map_https_port}"
            }
        } else {
            foreach hostname $host_node_map_hosts_list {
                lappend locations "http://${hostname}${host_map_http_port}"
                lappend locations "https://${hostname}${host_map_https_port}"
            }
        }
    }
    return  $locations
}
