ad_library {

    Provides methods for authorizing and identifying ACS users
    (both logged in and not) and tracking their sessions.

    @creation-date 16 Feb 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @author Richard Li (richardl@arsdigita.com)
    @author Archit Shah (ashah@arsdigita.com)
    @cvs-id security-procs.tcl,v 1.13.2.5 2003/06/06 08:48:50 lars Exp
}

# cookies (all are signed cookies):
#   cookie                value                          max-age         secure
#   ad_session_id         session_id,user_id             SessionTimeout  no
#   ad_user_login         user_id,                       never expires   no
#   ad_user_login_secure  user_id,random                 never expires   yes
#   ad_secure_token       session_id,user_id,random      SessionLifetime yes
#
#   the random data is used to hinder attack the secure hash. 
#   currently the random data is ns_time

ad_proc -private sec_random_token {} { Generates a random token. } {
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
	set start_clicks "developer.arsdigita.com"
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
    return [ad_parameter -package_id [ad_acs_kernel_id] SessionLifetime security 604800]
}

ad_proc -private sec_sweep_sessions {} {
    set expires [expr {[ns_time] - [sec_session_lifetime]}]

    db_dml sessions_sweep {} 
}

proc_doc sec_handler {} {

    Reads the security cookies, setting fields in ad_conn accordingly.

} {

    #  ns_log notice "OACS= sec_handler: enter"
    if { [catch { 
	set cookie_list [ad_get_signed_cookie_with_expr "ad_session_id"]
    } errmsg ] } {

	# ns_log notice "OACS= sec_handler:ad_get_signed_cookie failed $errmsg"

	# cookie is invalid because either:
	# -> it was never set
	# -> it failed the cryptographic check
	# -> it expired.

        set new_user_id 0
	# check for permanent login cookie
	if { ![ad_secure_conn_p] } {
            catch {
                set new_user_id [ad_get_signed_cookie "ad_user_login"]
            }
	    # ns_log notice "OACS= sec_handler:http, ad_user_login cookie user_id $new_user_id"
	} else {
            catch {
                set new_user_id [lindex [split [ad_get_signed_cookie "ad_user_login_secure"] {,}] 0]
            }
	    # ns_log notice "OACS= sec_handler:https, ad_user_login_secure cookie user_id $new_user_id"
	}
	# ns_log Notice "OACS= sec_handler:setting up session"
	sec_setup_session $new_user_id
	# ns_log Notice "OACS= sec_handler:done setting up session"
    } else {
	# The session already exists and is valid.
	set cookie_data [split [lindex $cookie_list 0] {,}]
	set session_expr [lindex $cookie_list 1]

	set session_id [lindex $cookie_data 0]
	set user_id [lindex $cookie_data 1]

	# ns_log notice "OACS= sec_handler:sess exists & is valid"
	# ns_log notice "OACS= sec_handler:cookie: $cookie_list, exp: $session_expr"
	# ns_log notice "OACS= sec_handler:sess_id: $session_id, user_id: $user_id"

	# If it's a secure page and not a login page, we check
	# secure token (can't check login page because they aren't
	# issued their secure tokens until after they pass through)
	# It is important to note that the entire secure login
	# system depends on these two functions
  	if { [ad_secure_conn_p] && ![ad_login_page] } {

	    # ns_log notice "OACS= sec_handler:secure but not login page"

  	    if { [catch { set sec_token [split [ad_get_signed_cookie "ad_secure_token"] {,}] } errmsg] } {
  		# token is incorrect or nonexistent, so we force relogin.

		# cro@ncacasi.org 2002-08-01
		# but wait--does user have an ad_user_login_secure cookie?
		# If so, just generate a secure token because he
		# can't have that cookie unless he had logged in securely
		# at some time in the past.
		# So just call sec_setup_session to generate a new token.
		# Otherwise, force a trip to /register
		if { [catch {
		    set new_user_id [lindex [split [ad_get_signed_cookie "ad_user_login_secure"] {,}] 0] }] } {
#		     ns_log notice "OACS= sec_handler:token invalid $errmsg"

		     ad_returnredirect "/register/index?return_url=[ns_urlencode [ad_conn url]?[ad_conn query]]"
		     return filter_break
		 } else {
		     sec_setup_session $new_user_id
		 }
  	    } else {
		# need to check only one of the user_id and session_id
		# if the cookie had been tampered.
#		ns_log notice "OACS= sec_handler:token ok, $sec_token $session_id"
		if { ![string match [lindex $sec_token 0] $session_id] } {
		    ad_returnredirect "/register/index?return_url=[ns_urlencode [ad_conn url]?[ad_conn query]]"
		    return filter_break
		}
	    }
	}

	ad_conn -set session_id $session_id
	ad_conn -set user_id $user_id

	# reissue session cookie so session doesn't expire if the
	# renewal period has passed. this is a little tricky because
	# the cookie doesn't know about sec_session_renew; it only
	# knows about sec_session_timeout.
	# [sec_session_renew] = SessionTimeout - SessionRenew (see security-init.tcl)
	# $session_expr = PreviousSessionIssue + SessionTimeout
	if { $session_expr - [sec_session_renew] < [ns_time] } {
	    sec_generate_session_id_cookie
	}
    }
}

ad_proc -public ad_user_login {
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
	# permanent login
	if { [ad_secure_conn_p] } {
	    ad_set_signed_cookie -max_age inf -secure t ad_user_login_secure "$user_id,[ns_time]"
	    ad_set_signed_cookie -max_age inf -secure f ad_user_login "$user_id"
	} else {
	    ad_set_signed_cookie -max_age inf -secure f ad_user_login "$user_id"
	    # Hose the secure permanent login token if this user is different 
	    # from the previous one.
	    if { $prev_user_id != $user_id } {
		ad_set_cookie -max_age 0 ad_user_login_secure ""
	    }
	}
    } elseif { $prev_user_id == $user_id && [ad_secure_conn_p] } {
	# nonpermanent secure login requested
	ad_set_cookie -max_age 0 ad_user_login_secure ""
    } else {
	ad_set_cookie -max_age 0 ad_user_login ""
	ad_set_cookie -max_age 0 ad_user_login_secure ""
    }

    # deal with the current session
    sec_setup_session $user_id
}

ad_proc -public ad_user_logout {} { Logs the user out. } {
    ad_set_cookie -replace t -max_age 0 ad_session_id ""
    ad_set_cookie -replace t -max_age 0 ad_secure_token ""
    ad_set_cookie -replace t -max_age 0 ad_user_login ""
    ad_set_cookie -replace t -max_age 0 ad_user_login_secure ""
}

ad_proc -public ad_check_password { user_id password_from_form } { Returns 1 if the password is correct for the given user ID. } {

    if { ![db_0or1row password_select {select password, salt from users where user_id = :user_id}] } {
	return 0
    }

    set salt [string trim $salt]

    if { [string compare $password [ns_sha1 "$password_from_form$salt"]] } {
	return 0
    }

    return 1
}

ad_proc -public ad_change_password { user_id new_password } { Changed the user's password } {

    # In case someone wants to change the salt from now on, you can do
    # this and still support old users by changing the salt below.
    set salt [sec_random_token]
    set new_password [ns_sha1 "$new_password$salt"]
    db_dml password_update {}
}

ad_proc -private sec_setup_session { new_user_id } {

    Set up the session, generating a new one if necessary,
    and generates the cookies necessary for the session

} {
    set session_id [ad_conn session_id]

    # figure out the session id, if we don't already have it
    if { [empty_string_p $session_id]} {

	# ns_log Notice "OACS= empty session_id"

	set session_id [sec_allocate_session]
        # if we have a user on an newly allocated session, update
        # users table

	# ns_log Notice "OACS= newly allocated session $session_id"

        if { $new_user_id != 0 } {
	    # ns_log Notice "OACS= about to update user session info, user_id NONZERO"
            sec_update_user_session_info $new_user_id
	    # ns_log Notice "OACS= done updating user session info, user_id NONZERO"
        }
    } else {
        # $session_id is an active verified session
        # this call to sec_setup_session is either a user logging in
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

    # su, set the session_id global var, and then generate the cookie
    ad_conn -set user_id $new_user_id
    ad_conn -set session_id $session_id
    
    # ns_log Notice "OACS= about to generate session id cookie"

    sec_generate_session_id_cookie

    # ns_log Notice "OACS= done generating session id cookie"

    if { [ad_secure_conn_p] && $new_user_id != 0 } {
        # this is a secure session, so the browser needs
        # a cookie marking it as such
	sec_generate_secure_token_cookie
    }
}

ad_proc -private sec_update_user_session_info { user_id } {
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
}

ad_proc -private sec_lookup_property { id module name } { 

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
    {
	-cache t
        -cache_only f
	-default ""
        -session_id ""
    }
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
    if { [empty_string_p $session_id] } {
        set id [ad_conn session_id]
    } else {
        set id $session_id
    }

    set cmd [list sec_lookup_property $id $module $name]

    if { $cache_only == "t" && ![util_memoize_cached_p $cmd] } {
	return ""
    }

    if { $cache != "t" } {
	util_memoize_flush $cmd
    }

    set property [util_memoize $cmd [sec_session_timeout]]
    if { $property == "" } {
	return $default
    }
    set value [lindex $property 0]
    set secure_p [lindex $property 1]
    
    if { $secure_p != "f" && ![ad_secure_conn_p] } {
	return ""
    }

    return $value
}

ad_proc -public ad_set_client_property {
    {-clob f}
    {-secure f}
    {-persistent t}
    {-session_id ""}
    module name value

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

    if { $secure != "f" && ![ad_secure_conn_p] } {
	error "Unable to set secure property in insecure or invalid session"
    }

    if { [empty_string_p $session_id] } {
        set session_id [ad_conn session_id]
    }

    if { $persistent == "t" } {
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

            if { $clob == "t" && ![empty_string_p $clob_update_dml] } {
                db_dml prop_update_dml_clob "" -clobs [list $value]
            } else {
                db_dml prop_update_dml ""
	    }
	}
    }

    # Remember the new value, seeding the memoize cache with the proper value.
    util_memoize_seed [list sec_lookup_property $session_id $module $name] [list $value $secure]
}

ad_proc -public ad_secure_conn_p {} { Returns true if the connection [ad_conn] is secure (HTTPS), or false otherwise. } {
    return [string match "https:*" [ad_conn location]]
}

ad_proc -private sec_generate_secure_token_cookie { } { 
    Sets the ad_secure_token cookie.
} {
    ad_set_signed_cookie -secure t "ad_secure_token" "[ad_conn session_id],[ad_conn user_id],[ns_time]"
}

ad_proc -private sec_generate_session_id_cookie {} { Sets the ad_session_id cookie based on global variables. } {
    set user_id [ad_conn user_id]
    set session_id [ad_conn session_id]
    ns_log Notice "Security: [ns_time] sec_generate_session_id_cookie setting $session_id, $user_id."
    ns_log Debug "Security: [ns_time] sec_generate_session_id_cookie setting $session_id, $user_id."
    ad_set_signed_cookie -replace t -max_age [sec_session_timeout] \
	    "ad_session_id" "$session_id,$user_id"
}

ad_proc -public -deprecated ad_get_user_id {} {
    Gets the user ID. 0 indicates the user is not logged in.

    Deprecated since user_id now provided via ad_conn user_id

    @see ad_conn
} {
    return [ad_conn user_id]
}

ad_proc -public -deprecated ad_verify_and_get_user_id { { -secure f } } {
    Returns the current user's ID. 0 indicates user is not logged in

    Deprecated since user_id now provided via ad_conn user_id

    @see ad_conn
} {
    return [ad_conn user_id]
}

ad_proc -public -deprecated ad_verify_and_get_session_id { { -secure f } } {
    Returns the current session's ID.

    Deprecated since session_id now provided via ad_conn session_id

    @param secure is ignored

    @see ad_conn
} {
    return [ad_conn session_id]
}

# handling privacy

ad_proc -public -deprecated ad_privacy_threshold {} {
    Pages that are consider whether to display a user's name or email
    address should test to make sure that a user's priv_ from the
    database is less than or equal to what ad_privacy_threshold returns.
    
    Now deprecated.
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

ad_proc -public ad_redirect_for_registration {} {
    
    Redirects user to /register/index of the closest subsite to require the user to
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
    -return:boolean
} {
    
    Returns a URL to the login page of the closest subsite, or the main site, if there's no current connection.
    
    @option return      If set, will export the current form, so when the registration is complete, 
                        the user will be returned to the current location.  All variables in 
                        ns_getform (both posts and gets) will be maintained.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [ad_conn isconnected] } {
        set url [site_node_closest_ancestor_package_url]

        # Check to see that the user (most likely "The Public" party, since there's probably no user logged in)
        # actually have permission to view that subsite, otherwise we'll get into an infinite redirect loop
        array set site_node [site_node::get_from_url -url $url]
        set package_id $site_node(object_id)
        if { ![permission::permission_p -object_id $site_node(object_id) -privilege read] } {
            set url /
        }
    } else {
        set url /
    }

    append url "register/"

    if { $return_p } {
        set url [export_vars -base $url { { return_url [ad_return_url] } }]
    }

    return $url
}

ad_proc -public ad_get_logout_url {
    -return:boolean
} {
    
    Returns a URL to the logout page of the closest subsite, or the main site, if there's no current connection.
    
    @option return      If set, will export the current form, so when the logout is complete
                        the user will be returned to the current location.  All variables in 
                        ns_getform (both posts and gets) will be maintained.

    @author Lars Pind (lars@collaboraid.biz)
} {
    if { [ad_conn isconnected] } {
        set url [site_node_closest_ancestor_package_url]
    } else {
        set url /
    }

    append url "register/logout"

    if { $return_p } {
        set url [export_vars -base $url { { return_url [ad_return_url] } }]
    }

    return $url
}

ad_proc -public ad_maybe_redirect_for_registration {} {

    Checks to see if a user is logged in.  If not, redirects to
    /register/index to require the user to register. When registration
    is complete, the user will return to the current location.  All
    variables in ns_getform (both posts and gets) will be maintained.
    Note that this will return out of its caller so that the caller need
    not explicitly call "return". Returns the user id if login was
    succesful.

    @see ad_redirect_for_registration
} {
    set user_id [ad_conn user_id]
    if { $user_id != 0 } {
	# user is in fact logged in, terminate
	return $user_id
    }
    ad_redirect_for_registration
    ad_script_abort
}

# JCD 20020915 I think this probably should not be deprecated since it is 
# far more reliable than permissioning esp for a development server 

ad_proc -public -deprecated ad_restrict_entire_server_to_registered_users {conn args why} {
    A preauth filter that will halt service of any page if the user is
    unregistered, except the site index page and stuff underneath
    /register. Use permissions on the site node map to control access.
} {
    if {![string match "/index.tcl" [ad_conn url]] && ![string match "/" [ad_conn url]] && ![string match "/register/*" [ad_conn url]] && ![string match "/SYSTEM/*" [ad_conn url]] && ![string match "/user_please_login.tcl" [ad_conn url]]} {
	# not one of the magic acceptable URLs
	set user_id [ad_conn user_id]
	if {$user_id == 0} {
	    ad_returnredirect "/register/?return_url=[ns_urlencode [ad_conn url]?[ad_conn query]]"
	    return filter_return
	}
    }
    return filter_ok
}

proc_doc ad_generate_random_string {{length 8}} {
    Generates a random string made of numbers and letters
} {
    return [string range [sec_random_token] 0 $length]
}

#
# The filter below will block requests containing character sequences that
# could be used to modify insecurely coded SQL queries in our Tcl scripts,
# like " or 1=1" or "1 union select ...".
#
# Written by branimir@arsdigita.com and carsten@arsdigita.com on July 2, 2000.
#

# michael@arsdigita.com: A better name for this proc would be
# "ad_block_sql_fragment_form_data", since "form data" is the
# official term for query string (URL) variables and form input
# variables.
#
ad_proc -public -deprecated ad_block_sql_urls {conn args why} {

    A filter that detect attempts to smuggle in SQL code through form data
    variables. The use of bind variables and ad_page_contract input 
    validation to prevent SQL smuggling is preferred.

    @see ad_page_contract
} {
    set form [ns_getform]
    if { [empty_string_p $form] } { return filter_ok }

    # Check each form data variable to see if it contains malicious
    # user input that we don't want to interpolate into our SQL
    # statements.
    #
    # We do this by scanning the variable for suspicious phrases; at
    # this time, the phrases we look for are: UNION, UNION ALL, and
    # OR.
    #
    # If one of these phrases is found, we construct a test SQL query
    # that incorporates the variable into its WHERE clause and ask
    # the database to parse it. If the query does parse successfully,
    # then we know that the suspicious user input would result in a
    # executing SQL that we didn't write, so we abort processing this
    # HTTP request.
    #
    set n_form_vars [ns_set size $form]
    for { set i 0 } { $i < $n_form_vars } { incr i } {
        set key [ns_set key $form $i]
        set value [ns_set value $form $i]

	# michael@arsdigita.com:
	#
	# Removed 4000-character length check, because that allowed
	# malicious users to smuggle SQL fragments greater than 4000
	# characters in length.
	#
        if {
	    [regexp -nocase {[^a-z_]or[^a-z0-9_]} $value] ||
	    [regexp -nocase {union([^a-z0-9_].*all)?[^a-z0-9_].*select} $value]
	} {
	    # Looks like the user has added "union [all] select" to
	    # the variable, # or is trying to modify the WHERE clause
	    # by adding "or ...".
	    #
            # Let's see if Oracle would accept this variables as part
	    # of a typical WHERE clause, either as string or integer.
	    #
	    # michael@arsdigita.com: Should we grab a handle once
	    # outside of the loop?
	    #
            set parse_result_integer [db_string sql_test_1 "select test_sql('select 1 from dual where 1=[DoubleApos $value]') from dual"]

            if { [string first "'" $value] != -1 } {
		#
		# The form variable contains at least one single
		# quote. This can be a problem in the case that
		# the programmer forgot to QQ the variable before
		# interpolation into SQL, because the variable
		# could contain a single quote to terminate the
		# criterion and then smuggled SQL after that, e.g.:
		#
		#   set foo "' or 'a' = 'a"
		#
		#   db_dml "delete from bar where foo = '$foo'"
		#
		# which would be processed as:
		#
		#   delete from bar where foo = '' or 'a' = 'a'
		#
		# resulting in the effective truncation of the bar
		# table.
		#
                set parse_result_string [db_string sql_test_2 "select test_sql('select 1 from dual where 1=[DoubleApos "'$value'"]') from dual"]
            } else {
                set parse_result_string 1
            }

            if {
		$parse_result_integer == 0 ||
		$parse_result_integer == -904  ||
		$parse_result_integer == -1789 ||
		$parse_result_string == 0 ||
		$parse_result_string == -904 ||
		$parse_result_string == -1789
	    } {
                # Code -904 means "invalid column", -1789 means
		# "incorrect number of result columns". We treat this
		# the same as 0 (no error) because the above statement
		# just selects from dual and 904 or 1789 only occur
		# after the parser has validated that the query syntax
		# is valid.

                ns_log Error "ad_block_sql_urls: Suspicious request from [ad_conn peeraddr]. Parameter $key contains code that looks like part of a valid SQL WHERE clause: [ad_conn url]?[ad_conn query]"

		# michael@arsdigita.com: Maybe we should just return a
		# 501 error.
		#
                ad_return_error "Suspicious Request" "Parameter $key looks like it contains SQL code. For security reasons, the system won't accept your request."

                return filter_return
            }
        }
    }

    return filter_ok
}

ad_proc -public -deprecated ad_set_typed_form_variable_filter {url_pattern args} {
    <pre>
    #
    # Register special rules for form variables.
    #
    # Example:
    #
    #    ad_set_typed_form_variable_filter /my_module/* {a_id number} {b_id word} {*_id integer}
    #
    # For all pages under /my_module, set_form_variables would set 
    # $a_id only if it was number, and $b_id only if it was a 'word' 
    # (a string that contains only letters, numbers, dashes, and 
    # underscores), and all other variables that match the pattern
    # *_id would be set only if they were integers.
    #
    # Variables not listed have no restrictions on them.
    #
    # By default, the three supported datatypes are 'integer', 'number',
    # and 'word', although you can add your own type by creating
    # functions named ad_var_type_check_${type_name}_p which should
    # return 1 if the value is a valid $type_name, or 0 otherwise.
    #
    # There's also a special datatype named 'nocheck', which will
    # return success regardless of the value. (See the docs for 
    # ad_var_type_check_${type_name}_p to see how this might be
    # useful.)
    #
    # The default data_type is 'integer', which allows you shorten the
    # command above to:
    #
    #    ad_set_typed_form_variable_filter /my_module/* a_id {b_id word}
    #

    ad_page_contract is the preferred mechanism to do automated
    validation of form variables.
    </pre>
    @see ad_page_contract
} {
    ad_register_filter postauth GET  $url_pattern ad_set_typed_form_variables $args
    ad_register_filter postauth POST $url_pattern ad_set_typed_form_variables $args
}

proc ad_set_typed_form_variables {conn args why} {

    global ad_typed_form_variables

    eval lappend ad_typed_form_variables [lindex $args 0]

    return filter_ok
}

#
# All the ad_var_type_check* procs get called from 
# check_for_form_variable_naughtiness. Read the documentation
# for ad_set_typed_form_variable_filter for more details.

proc_doc ad_var_type_check_integer_p {value} {
    <pre>
    #
    # return 1 if $value is an integer, 0 otherwise.
    #
    <pre>
} {

    if { [regexp {[^0-9]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_safefilename_p {value} {
    <pre>
    #
    # return 0 if the file contains ".."
    #
    <pre>
} {

    if { [string match *..* $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_dirname_p {value} {
    <pre>
    #
    # return 0 if $value contains a / or \, 1 otherwise.
    #
    <pre>
} {

    if { [regexp {[/\\]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_number_p {value} {
    <pre>
    #
    # return 1 if $value is a valid number
    #
    <pre>
} {
    if { [catch {expr 1.0 * $value}] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_word_p {value} {
    <pre>
    #
    # return 1 if $value contains only letters, numbers, dashes, 
    # and underscores, otherwise returns 0.
    #
    </pre>
} {

    if { [regexp {[^-A-Za-z0-9_]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_nocheck_p {{value ""}} {
    <pre>
    #
    # return 1 regardless of the value. This useful if you want to 
    # set a filter over the entire site, then create a few exceptions.
    #
    # For example:
    #
    #   ad_set_typed_form_variable_filter /my-dangerous-page.tcl {user_id nocheck}
    #   ad_set_typed_form_variable_filter /*.tcl user_id
    #
    </pre>
} {
    return 1
}

proc_doc ad_var_type_check_noquote_p {value} {
    <pre>
    #
    # return 1 if $value contains any single-quotes
    #
    <pre>
} {

    if { [string match *'* $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_integerlist_p {value} {
    <pre>
    #
    # return 1 if list contains only numbers, spaces, and commas.
    # Example '5, 3, 1'. Note: it doesn't allow negative numbers,
    # because that could let people sneak in numbers that get
    # treated like math expressions like '1, 5-2'
    #
    #
    <pre>
} {

    if { [regexp {[^ 0-9,]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_fail_p {value} {
    <pre>
    #
    # A check that always returns 0. Useful if you want to disable all access
    # to a page.
    #
    <pre>
} {
    return 0
}

proc_doc ad_var_type_check_third_urlv_integer_p {{args ""}} {
    <pre>
    #
    # Returns 1 if the third path element in the URL is integer.
    #
    <pre>
} {

    set third_url_element [lindex [ad_conn urlv] 3]

    if { [regexp {[^0-9]} $third_url_element] } {
        return 0
    } else {
        return 1
    }
}

ad_proc -private sec_allocate_session {} {

    Returns a new session id

} {
    
    global tcl_max_value
    global tcl_current_sequence_id

    if { ![info exists tcl_max_value] || ![info exists tcl_current_sequence_id] || $tcl_current_sequence_id > $tcl_max_value } {
	# Thread just spawned or we exceeded preallocated count.
	set tcl_current_sequence_id [db_nextval sec_id_seq]
	set tcl_max_value [expr $tcl_current_sequence_id + 100]
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
            [string match "/" $url] || \
            [string match "*password-update*" $url] } {
	return 1
    }

    return 0
}

# signed cookies 

ad_proc -public ad_sign {
    {
	-secret ""
	-token_id ""
	-max_age ""
    }
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

    if { [empty_string_p $secret] } {
        if {[empty_string_p $token_id]} { 
            # pick a random token_id
            set token_id [sec_get_random_cached_token_id]
        }
	set secret_token [sec_get_token $token_id]
    } else {
	set secret_token $secret
    }
    

    ns_log Debug "Security: Getting token_id $token_id, value $secret_token"

    if { $max_age == "" } {
	set expire_time 0
    } else {
	set expire_time [expr $max_age + [ns_time]]
    }

    set hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

    set signature [list $token_id $expire_time $hash]

    return $signature
}

ad_proc -public ad_verify_signature {
    {
	-secret ""
    }
    value signature
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
    {
	-secret ""
    }
    value signature
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

    if { [empty_string_p $secret] } {
	if { [empty_string_p $token_id] } {
	    return 0
	}
	set secret_token [sec_get_token $token_id]
    } else {
	set secret_token $secret
    }

    ns_log Debug "Security: Getting token_id $token_id, value $secret_token"
    ns_log Debug "Security: Expire_Time is $expire_time (compare to [ns_time]), hash is $hash"

    # validate cookie: verify hash and expire_time

    set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

    if { [string compare $computed_hash $hash] == 0 && ($expire_time > [ns_time] || $expire_time == 0) } {
	return 1
    }

    # check to see if IE is lame (and buggy!) and is expanding \n to \r\n
    # See: http://www.arsdigita.com/bboard/q-and-a-fetch-msg?msg_id=000bfF
    set value [string map [list \r ""] $value]
    set computed_hash [ns_sha1 "$value$token_id$expire_time$secret_token"]

    if { [string compare $computed_hash $hash] == 0 && ($expire_time > [ns_time] || $expire_time == 0) } {
	return 1
    }


    ns_log Debug "Security: The string compare is [string compare $computed_hash $hash]."
    # signature could not be authenticated
    return 0

}

# signed cookies 

ad_proc -public ad_get_signed_cookie {
    { 
	-include_set_cookies t 
	-secret ""
    }
    name
} { 

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and insures that the cookie has not
    expired. Throws an exception if validation fails.

} {

    if { $include_set_cookies == "t" } {
	set cookie_value [ns_urldecode [ad_get_cookie $name]]
    } else {
	set cookie_value [ns_urldecode [ad_get_cookie -include_set_cookies f $name]]
    }

    if { [empty_string_p $cookie_value] } {
	error "Cookie does not exist."
    }

    ns_log Debug "Security: Done calling get_cookie $cookie_value for $name."

    set value [lindex $cookie_value 0]
    set signature [lindex $cookie_value 1]

    if { [ad_verify_signature $value $signature] } {
	return $value
    }

    error "Cookie could not be authenticated."
}

ad_proc -public ad_get_signed_cookie_with_expr {
    { 
	-include_set_cookies t 
	-secret ""
    }
    name
} { 

    Retrieves a signed cookie. Validates a cookie against its
    cryptographic signature and insures that the cookie has not
    expired. Returns a two-element list, the first element of which is
    the cookie data, and the second element of which is the expiration
    time. Throws an exception if validation fails.

} {

    if { $include_set_cookies == "t" } {
	set cookie_value [ns_urldecode [ad_get_cookie $name]]
    } else {
	set cookie_value [ns_urldecode [ad_get_cookie -include_set_cookies f $name]]
    }

    if { [empty_string_p $cookie_value] } {
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
    {
	-replace f
	-secure f
	-max_age ""
	-domain ""
	-path "/"
	-secret ""
	-token_id ""
    }
    name value
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
    if { $max_age == "inf" } {
	set signature_max_age ""
    } elseif { $max_age != "" } {
	set signature_max_age $max_age
    } else {
	# this means we want a session level cookie,
	# but that is a user interface expiration, that does
	# not give us a security expiration. (from the
	# security perspective, we use SessionLifetime)
	ns_log Debug "Security: SetSignedCookie: Using sec_session_lifetime [sec_session_lifetime]"
	set signature_max_age [sec_session_lifetime]
    }

    set cookie_value [ad_sign -secret $secret -token_id $token_id -max_age $signature_max_age $value]

    set data [ns_urlencode [list $value $cookie_value]]

    ad_set_cookie -replace $replace -secure $secure -max_age $max_age -domain $domain -path $path $name $data
}



ad_proc -private sec_get_token { token_id } {

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

	    # Very important to throw the error here if $token == 0
	    # see: http://www.arsdigita.com/sdm/one-ticket?ticket_id=10760

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

    set num_tokens [ad_parameter -package_id [ad_acs_kernel_id] NumberOfCachedSecretTokens security 100]

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
}

ad_proc -private populate_secret_tokens_db {} {

    Populates the secret_tokens table. Note that this will take awhile
    to run.

} {

    set num_tokens [ad_parameter -package_id [ad_acs_kernel_id] NumberOfCachedSecretTokens security 100]
    # we assume sample size of 10%.
    set num_tokens [expr {$num_tokens * 10}]
    set counter 0
    set list_of_tokens [list]

    # the best thing to use here would be an array_dml, except
    # that an array_dml makes it hard to use sysdate and sequences.
    while { $counter < $num_tokens } {
	set random_token [sec_random_token]

	db_dml insert_random_token {
	    insert /*+ APPEND */ into secret_tokens(token_id, token, timestamp)
	    values(sec_security_token_id_seq.nextval, :random_token, sysdate)
	}
	incr counter
    }

    db_release_unused_handles

}
