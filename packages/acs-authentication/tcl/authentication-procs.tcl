ad_library {
    Tcl API for authentication, account management, and account registration.

    @author Lars Pind (lars@collaobraid.biz)
    @creation-date 2003-05-13
    @cvs-id $Id$
}

namespace eval auth {}
namespace eval auth::authentication {}
namespace eval auth::registration {}
namespace eval auth::user_info {}


#####
#
# auth namespace public procs
#
#####

ad_proc -public auth::require_login {
    {-level ok}
    {-account_status ok}
} {
    If the current session is not authenticated, redirect to the
    login page, and aborts the current page script.
    Otherwise, returns the user_id of the user logged in.
    Use this in a page script to ensure that only registered and authenticated
    users can execute the page, for example for posting to a forum.

    @return user_id of user, if the user is logged in.
    Otherwise will issue a returnredirect and abort the current page.

    @see ad_script_abort
} {
    set user_id [auth::get_user_id \
                     -level $level \
                     -account_status $account_status]

    if { $user_id != 0 } {
        # user is in fact logged in, return user_id
        return $user_id
    }

    set message {}
    if {[ad_conn auth_level] eq "expired"} {
        set message [_ acs-subsite.lt_Your_login_has_expire]
    }

    set return_url [ad_get_login_url -return]

    # Long URLs (slightly above 4000 bytes) can kill aolserver-4.0.10, causing
    # a restart. They lead to empty Browser-windows with AOLserver 4.5 (but no
    # crash so far). May browsers have length limitations for URLs. E.g.
    # 2083 is the documented maximal length of MSIE.
    #
    # Long URLs will be generated e.g. when
    #   a) a user edits a form with text entries
    #   b) before submitting the form logs out of OpenACS from a different browser window
    #   c) submits the form.
    # When submitting needs authentication, OpenACS generates the redirect to
    # /register with the form-data coded into the URL to continue there.....

    # set user_agent [string tolower [ns_set get [ns_conn headers] User-Agent]]
    # ns_log notice "URL have url, len=[string length $return_url] $user_agent"

    if {[string length $return_url] > 2083} {
        set message "Your login expired and the computed URL for automated continuation is too long. "
        append message "If you were editing a from, please use the back button after logging in and resubmit the form."
        set return_url [ad_get_login_url]
    }

    # The -return switch causes the URL to return to the current page
    ad_returnredirect -message $message -- $return_url
    ad_script_abort
}

ad_proc -public auth::refresh_login {} {
    If there currently is a user associated with this session,
    but the user's authentication is expired, redirect the
    user to refresh his/her login. This allows for users to not be logged in,
    but if the user is logged in, then we require that the authentication is not expired.

    @return user_id of user, if the user is logged in and auth_status is not expired, or 0 if the user is not logged in.
    If user's auth_status is expired, this proc will issue a returnredirect and abort the current page.

    @see ad_script_abort
} {
    if { [ad_conn auth_level] ne "expired" } {
        return [ad_conn user_id]
    }

    # The -return switch causes the URL to return to the current page
    ad_returnredirect [ad_get_login_url -return]
    ad_script_abort
}

ad_proc -public auth::self_registration {} {
    Check AllowSelfRegister parameter and set user message if
    self registration not allowed.
} {
    if { [string is false [parameter::get_from_package_key \
                               -package_key acs-authentication \
                               -parameter AllowSelfRegister]] } {
        util_user_message -message "Self registration is not allowed"
        auth::require_login
    }
}

ad_proc -public auth::get_user_id {
    {-level ok}
    {-account_status ok}
} {
    Get the current user_id with at least the level of security specified.
    If no user is logged in, or the user is not logged in at a sufficiently
    high security level, return 0.

    @return user_id of user, if the user is logged in, 0 otherwise.

    @see ad_script_abort
} {
    set untrusted_user_id [ad_conn untrusted_user_id]

    # Do we have any user_id at all?
    if { $untrusted_user_id == 0 } {
        return 0
    }

    # Check account status
    if { $account_status eq "ok" && [ad_conn account_status] ne "ok" } {
        return 0
    }

    array set levelv {
        none 0
        expired 1
        ok 2
        secure 3
    }

    # If HTTPS isn't available, we can't require secure authentication
    if { ![security::https_available_p] } {
        set levelv(secure) 2
    }

    # Check if auth_level is sufficiently high
    if { $levelv([ad_conn auth_level]) < $levelv($level) } {
        return 0
    }

    return $untrusted_user_id
}

ad_proc -public auth::UseEmailForLoginP {} {
    Do we use email address for login? code wrapped in a catch, so the
    proc will not break regardless of what the parameter value is.
} {
    return [parameter::get -boolean -parameter UseEmailForLoginP -package_id [ad_acs_kernel_id] -default 1]
}

ad_proc -public auth::authenticate {
    {-return_url ""}
    {-authority_id ""}
    {-username ""}
    {-email ""}
    {-password:required}
    {-persistent:boolean}
    {-no_cookie:boolean}
    {-first_names ""}
    {-last_name ""}
    {-host_node_id ""}
} {
    Try to authenticate and login the user forever by validating the username/password combination,
    and return authentication and account status codes.

    @param return_url   If specified, this can be included in account status messages.
    @param authority_id The ID of the authority to ask to verify the user. Defaults to local authority.
    @param username     Authority specific username of the user.
    @param email        User's email address. You must supply either username or email.
    @param password     The password as the user entered it.
    @param persistent   Set this if you want a permanent login cookie
    @param no_cookie    Set this if you don't want to issue a login cookie
    @param host_node_id Optional parameter used to determine the cookie domain from the host_node_map

    @return Array list with the following entries:

    <ul>
    <li> auth_status:     Whether authentication succeeded.
    ok, no_account, bad_password, auth_error, failed_to_connect
    <li> auth_message:    Human-readable message about what went wrong. Guaranteed to be set if auth_status is not ok.
    Should be ignored if auth_status is ok. May contain HTML.

    <li> account_status:  Account status from authentication server.
    ok, closed.
    <li> account_url:     A URL to redirect the user to. Could e.g. ask the user to update his password.
    <li> account_message: Human-readable message about account status. Guaranteed to be set if auth_status is not ok
    and account_url is empty.
    If non-empty, must be relayed to the user regardless of account_status. May contain HTML.
    This proc is responsible for concatenating any remote and/or local account messages into
    one single message which can be displayed to the user.

    <li> user_id:         Set to local user_id if auth_status is ok.
    </ul>

} {
    if { $username eq "" } {
        if { $email eq "" } {
            set result(auth_status) "auth_error"
            if { [auth::UseEmailForLoginP] } {
                set result(auth_message) [_ acs-subsite.Email_required]
            } else {
                set result(auth_message) [_ acs-subsite.Username_required]
            }
            return [array get result]
        }
        set user_id [party::get_by_email -email $email]
        if { $user_id eq "" || ![acs_user::registered_user_p -user_id $user_id] } {            
            set result(auth_status) "no_account"
            set result(auth_message) [_ acs-subsite.Unknown_email]
            return [array get result]
        }
        acs_user::get -user_id $user_id -array user
        set authority_id $user(authority_id)
        set username $user(username)
    } else {
        # Default to local authority
        if { $authority_id eq "" } {
            set authority_id [auth::authority::local]
        }
    }

    with_catch errmsg {
        array set result [auth::authentication::Authenticate \
                              -username $username \
                              -authority_id $authority_id \
                              -password $password]

        # We do this so that if there aren't even the auth_status and account_status that need be
        # in the array, that gets caught below
        if {$result(auth_status) eq "ok"} {
            set dummy $result(account_status)
        }
    } {
        set result(auth_status) failed_to_connect
        set result(auth_message) $errmsg
        ns_log Error "auth::authenticate: error invoking authentication driver for authority_id = $authority_id: $::errorInfo"
    }

    # Returns:
    #   result(auth_status)
    #   result(auth_message)
    #   result(account_status)
    #   result(account_message)

    # Verify result/auth_message return codes
    switch $result(auth_status) {
        ok {
            # Continue below
        }
        no_account -
        bad_password -
        auth_error -
        failed_to_connect {
            if { ![info exists result(auth_message)] || $result(auth_message) eq "" } {
                array set default_auth_message {
                    no_account {Unknown username}
                    bad_password {Bad password}
                    auth_error {Invalid username/password}
                    failed_to_connect {Error communicating with authentication server}
                }
                set result(auth_message) $default_auth_message($result(auth_status))
            }
            return [array get result]
        }
        default {
            ns_log Error "auth::authenticate: Illegal auth_status code '$result(auth_status)' returned from authentication driver for authority_id $authority_id ([auth::authority::get_element -authority_id $authority_id -element pretty_name])"

            set result(auth_status) "failed_to_connect"
            set result(auth_message) [_ acs-subsite.Auth_internal_error]
            return [array get result]
        }
    }

    # Verify remote account_info/account_message return codes
    switch $result(account_status) {
        ok {
            # Continue below
            if { ![info exists result(account_message)] } {
                set result(account_message) {}
            }
        }
        closed {
            if { ![info exists result(account_message)] || $result(account_message) eq "" } {
                set result(account_message) [_ acs-subsite.Account_not_avail_now]
            }
        }
        default {
            ns_log Error "auth::authenticate: Illegal account_status code '$result(account_status)' returned from authentication driver for authority_id $authority_id ([auth::authority::get_element -authority_id $authority_id -element pretty_name])"

            set result(account_status) "closed"
            set result(account_message) [_ acs-subsite.Auth_internal_error]
        }
    }

    # Save the remote account information for later
    set remote_account_status $result(account_status)
    set remote_account_message $result(account_message)

    # Clear out remote account_status and account_message
    array unset result account_status
    array unset result account_message
    set result(account_url) {}

    # Map to row in local users table
    array set result [auth::get_local_account \
                          -return_url $return_url \
                          -username $username \
                          -authority_id $authority_id \
                          -email $email \
                          -first_names $first_names \
                          -last_name $last_name]
    # Returns:
    #   result(account_status)
    #   result(account_message)
    #   result(account_url)
    #   result(user_id)

    # Verify local account_info/account_message return codes
    switch $result(account_status) {
        ok {
            # Continue below
            if { ![info exists result(account_message)] } {
                set result(account_message) {}
            }
        }
        closed {
            if { ![info exists result(account_message)] || $result(account_message) eq "" } {
                set result(account_message) [_ acs-subsite.Account_not_avail_now]
            }
        }
        default {
            ns_log Error "auth::authenticate: Illegal account_status code '$result(account_status)' returned from auth::get_local_account for authority_id $authority_id ([auth::authority::get_element -authority_id $authority_id -element pretty_name])"

            set result(account_status) "closed"
            set result(account_message) [_ acs-subsite.Auth_internal_error]
        }
    }

    # If the remote account was closed, the whole account is closed, regardless of local account status
    if {$remote_account_status eq "closed"} {
        set result(account_status) closed
    }

    if { $remote_account_message ne "" } {
        if { [info exists result(account_message)] && $result(account_message) ne "" } {
            # Concatenate local and remote account messages
            set local_account_message [auth::authority::get_element \
                                           -authority_id $authority_id \
                                           -element pretty_name]
            set result(account_message) [subst {
                <p>$local_account_message: $remote_account_message</p>
                <p>[ad_system_name]: $result(account_message)</p>
            }]
        } else {
            set result(account_message) $remote_account_message
        }
    }

    # Issue login cookie if login was successful
    if { $result(auth_status) eq "ok"
         && !$no_cookie_p
         && [info exists result(user_id)] && $result(user_id) ne ""
     } {
        if {$host_node_id ne ""} {
            set cookie_domain [db_string get_mapped_host {
                select host from host_node_map where node_id = :host_node_id
            } -default ""]
            if {$cookie_domain eq ""} {
                ns_log warning "auth::authenticate: host_node_id $host_node_id was provided but is apparently not mapped"
            }
        } else {
            set cookie_domain ""
        }
        ns_log notice "auth::authenticate receives host_node_id $host_node_id domain <$cookie_domain>"
        auth::issue_login \
            -user_id $result(user_id) \
            -persistent=$persistent_p \
            -account_status $result(account_status) \
            -cookie_domain $cookie_domain
    }

    return [array get result]
}

ad_proc -private auth::issue_login {
    {-user_id:required}
    {-account_status "ok"}
    {-cookie_domain ""}
    {-persistent:boolean}
} {
    Issue the login cookie.
} {
    ad_user_login \
        -account_status $account_status \
        -cookie_domain $cookie_domain \
        -forever=$persistent_p \
        $user_id
}

ad_proc -private auth::get_register_authority {
} {
    Get the ID of the authority in which accounts get created. Is based on the RegisterAuthority parameter
    but will default to the local authority if that parameter has an invalid value.
} {
    set parameter_value [parameter::get_from_package_key -parameter RegisterAuthority -package_key "acs-authentication"]

    # Catch the case where somebody has set the parameter to some non-existent authority
    if {$parameter_value in [auth::authority::get_short_names]} {
        # The authority exists
        set authority_id [auth::authority::get_id -short_name $parameter_value]

        # Check that the authority has a register implementation
        auth::authority::get -authority_id $authority_id -array authority

        if { $authority(register_impl_id) eq "" } {
            ns_log Error "auth::get_register_authority: parameter value for RegisterAuthority is an authority without registration driver, defaulting to local authority"
            set authority_id [auth::authority::local]
        }
    } else {
        # The authority doesn't exist - use the local authority
        ns_log Error "auth::get_register_authority: parameter RegisterAuthority has the invalid value $parameter_value. Defaulting to local authority"
        set authority_id [auth::authority::local]
    }

    return $authority_id
}

ad_proc -public auth::create_user {
    {-verify_password_confirm:boolean}
    {-user_id ""}
    {-username ""}
    {-email:required}
    {-first_names ""}
    {-last_name ""}
    {-screen_name ""}
    {-password ""}
    {-password_confirm ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
    {-email_verified_p ""}
    {-nologin:boolean}
} {
    Create a user, and return creation status and account status.

    @param email_verified_p Whether the local account considers the email to be verified or not.

    @param verify_password_confirm
    Set this flag if you want the proc to verify that password and password_confirm match for you.

    @return Array list containing the following entries:

    <ul>
    <li> creation_status:  ok, data_error, reg_error, failed_to_connect. Says whether user creation succeeded.
    <li> creation_message: Information about the problem, to be relayed to the user. If creation_status is not ok, then either
    creation_message or element_messages is guaranteed to be non-empty, and both are
    guaranteed to be in the array list.  May contain HTML.
    <li> element_messages: list of (element_name, message, element_name, message, ...) of
    errors on the individual registration elements.
    to be relayed on to the user. If creation_status is not ok, then either
    creation_message or element_messages is guaranteed to be non-empty, and both are
    guaranteed to be in the array list. Cannot contain HTML.
    <li> account_status:   ok, closed. Only set if creation_status was ok, this says whether the newly created account
    is ready for use or not. For example, we may require approval, in which case the account
    would be created but closed.
    <li> account_message:  A human-readable explanation of why the account was closed. May include HTML, and thus shouldn't
    be quoted. Guaranteed to be non-empty if account_status is not ok.
    <li> user_id:          The user_id of the created user. Only when creation_status is ok.
    </ul>

    @see auth::get_all_registration_elements
} {
    set authority_id [auth::get_register_authority]

    # This holds element error messages
    array set element_messages [list]

    #####
    #
    # Create local account
    #
    #####

    if { $verify_password_confirm_p } {
        if { $password ne $password_confirm } {
            return [list \
                        creation_status data_error \
                        creation_message [_ acs-subsite.Passwords_dont_match] \
                        element_messages [list \
                                              password_confirm [_ acs-subsite.Passwords_dont_match] ]]
        }
    }

    set email [string trim $email]
    set username [string trim $username]

    foreach elm [get_all_registration_elements] {
        if { [info exists $elm] } {
            set user_info($elm) [set $elm]
        }
    }

    # email_verified_p
    set user_info(email_verified_p) $email_verified_p

    db_transaction {
        array set creation_info [auth::create_local_account \
                                     -user_id $user_id \
                                     -authority_id $authority_id \
                                     -username $username \
                                     -array user_info]

        # Returns:
        #   creation_info(creation_status)
        #   creation_info(creation_message)
        #   creation_info(element_messages)
        #   creation_info(account_status)
        #   creation_info(account_message)
        #   creation_info(user_id)

        # We don't do any fancy error checking here, because create_local_account is not a service contract
        # so we control it 100%

        # Local account creation ok?
        if {$creation_info(creation_status) eq "ok"} {
            # Need to find out which username was set
            set username $creation_info(username)

            # Save the local account information for later
            set local_account_status $creation_info(account_status)
            set local_account_message $creation_info(account_message)

            # Clear out remote creation_info array for reuse
            array set creation_info {
                creation_status {}
                creation_message {}
                element_messages {}
                account_status {}
                account_message {}
            }


            #####
            #
            # Create remote account
            #
            #####

            array set creation_info [auth::registration::Register \
                                         -authority_id $authority_id \
                                         -username $username \
                                         -password $password \
                                         -first_names $first_names \
                                         -last_name $last_name \
                                         -screen_name $screen_name \
                                         -email $email \
                                         -url $url \
                                         -secret_question $secret_question \
                                         -secret_answer $secret_answer]

            # Returns:
            #   creation_info(creation_status)
            #   creation_info(creation_message)
            #   creation_info(element_messages)
            #   creation_info(account_status)
            #   creation_info(account_message)

            # Verify creation_info/creation_message return codes
            array set default_creation_message {
                data_error {Problem with user data}
                reg_error {Unknown registration error}
                failed_to_connect {Error communicating with account server}
            }

            switch $creation_info(creation_status) {
                ok {
                    # Continue below
                }
                data_error -
                reg_error -
                failed_to_connect {
                    if { $creation_info(creation_message) eq "" } {
                        set creation_info(creation_message) $default_creation_message($creation_info(creation_status))
                    }
                    if { ![info exists creation_info(element_messages)] } {
                        set creation_info(element_messages) {}
                    }
                    return [array get creation_info]
                }
                default {
                    set creation_info(creation_status) "failed_to_connect"
                    set creation_info(creation_message) "Illegal error code returned from account creation driver"
                    return [array get creation_info]
                }
            }

            # Verify remote account_info/account_message return codes
            switch $creation_info(account_status) {
                ok {
                    # Continue below
                    set creation_info(account_message) {}
                }
                closed {
                    if { $creation_info(account_message) eq "" } {
                        set creation_info(account_message) [_ acs-subsite.Account_not_avail_now]
                    }
                }
                default {
                    set creation_info(account_status) "closed"
                    set creation_info(account_message) "Illegal error code returned from creationentication driver"
                }
            }
        }

    } on_error {
        set creation_info(creation_status) failed_to_connect
        set creation_info(creation_message) $errmsg
        ns_log Error "auth::create_user: Error invoking account registration driver for authority_id = $authority_id: $::errorInfo"
    }

    if { $creation_info(creation_status) ne "ok" } {
        return [array get creation_info]
    }

    #####
    #
    # Clean up, concat account messages, issue login cookie
    #
    #####

    # If the local account was closed, the whole account is closed, regardless of remote account status
    if {$local_account_status eq "closed"} {
        set creation_info(account_status) closed
    }

    if { [info exists local_account_message] && $local_account_message ne "" } {
        if { [info exists creation_info(account_message)] && $creation_info(account_message) ne "" } {
            # Concatenate local and remote account messages
            set creation_info(account_message) "<p>[auth::authority::get_element -authority_id $authority_id -element pretty_name]: $creation_info(account_message)</p> <p>[ad_system_name]: $local_account_message</p>"
        } else {
            set creation_info(account_message) $local_account_message
        }
    }

    # Unless nologin was specified, issue login cookie if login was successful
    if { !$nologin_p && $creation_info(creation_status) eq "ok" && $creation_info(account_status) eq "ok" && [ad_conn user_id] == 0 } {
        auth::issue_login -user_id $creation_info(user_id)
    }

    return [array get creation_info]
}

ad_proc -public auth::get_registration_elements {
} {
    Get the list of required/optional elements for user registration.

    @return Array-list with two entries

    <ul>
    <li> required: a list of required elements
    <li> optional: a list of optional elements
    </ul>

    @see auth::get_all_registration_elements
} {
    set authority_id [auth::get_register_authority]

    array set element_info [auth::registration::GetElements -authority_id $authority_id]

    if { ![info exists element_info(required)] } {
        set element_info(required) {}
    }
    if { ![info exists element_info(optional)] } {
        set element_info(optional) {}
    }

    set local_required_elms { first_names last_name email }
    set local_optional_elms {}

    switch [acs_user::ScreenName] {
        require {
            lappend local_required_elms "screen_name"
        }
        solicit {
            lappend local_optional_elms "screen_name"
        }
    }

    # Handle required elements for local account
    foreach elm $local_required_elms {
        # Add to required
        if { [lsearch $element_info(required) $elm] == -1 } {
            lappend element_info(required) $elm
        }

        # Remove from optional
        set index [lsearch $element_info(optional) $elm]
        if { $index != -1 } {
            set element_info(optional) [lreplace $element_info(optional) $index $index]
        }
    }

    foreach elm $local_optional_elms {
        # Add to required
        if { [lsearch $element_info(required) $elm] == -1 && [lsearch $element_info(optional) $elm] == -1 } {
            lappend element_info(optional) $elm
        }
    }

    return [array get element_info]
}

ad_proc -public auth::get_all_registration_elements {
    {-include_password_confirm:boolean}
} {
    Get the list of possible registration elements.
} {
    if { $include_password_confirm_p } {
        return { email username first_names last_name password password_confirm screen_name url secret_question secret_answer }
    } else {
        return { email username first_names last_name password screen_name url secret_question secret_answer }
    }
}

ad_proc -public auth::get_registration_form_elements {
} {
    Returns a list of elements to be included in the -form chunk of an ad_form form.
    All possible elements will always be present, but those that shouldn't be displayed
    will be hidden and have a hard-coded empty string value.
} {
    array set data_types {
        username text
        email text
        first_names text
        last_name text
        screen_name text
        url text
        password text
        password_confirm text
        secret_question text
        secret_answer text
    }

    array set widgets {
        username text
        email text
        first_names text
        last_name text
        screen_name text
        url text
        password password
        password_confirm password
        secret_question text
        secret_answer text
    }

    array set labels [list \
                          username [_ acs-subsite.Username] \
                          email [_ acs-subsite.Email] \
                          first_names [_ acs-subsite.First_names] \
                          last_name [_ acs-subsite.Last_name] \
                          screen_name [_ acs-subsite.Screen_name] \
                          url [_ acs-subsite.lt_Personal_Home_Page_UR] \
                          password [_ acs-subsite.Password] \
                          password_confirm [_ acs-subsite.lt_Password_Confirmation] \
                          secret_question [_ acs-subsite.Question] \
                          secret_answer [_ acs-subsite.Answer]]

    array set html {
        username {size 30}
        email {size 30}
        first_names {size 30}
        last_name {size 30}
        screen_name {size 30}
        url {size 80 value ""}
        password {size 20}
        password_confirm {size 20}
        secret_question {size 30}
        secret_answer {size 30}
    }

    array set element_info [auth::get_registration_elements]

    # provide default help texts, might be refined later.
    array set help_text {
        username {}
        email {}
        first_names {}
        last_name {}
        screen_name {}
        url {}
        password {}
        password_confirm {}
        secret_question {}
        secret_answer {}
    }

    if {"password" in $element_info(required)} {
        lappend element_info(required) password_confirm
    }
    if {"password" in $element_info(optional)} {
        lappend element_info(optional) password_confirm
    }

    # required_p will have 1 if required, 0 if optional, and unset if not in the form
    array set required_p [list]
    foreach element $element_info(required) {
        set required_p($element) 1
    }
    foreach element $element_info(optional) {
        set required_p($element) 0
    }

    set form_elements [list]
    foreach element [auth::get_all_registration_elements -include_password_confirm] {
        if { [info exists required_p($element)] } {
            set form_element [list]

            # The header with name, datatype, and widget
            set form_element_header "${element}:$data_types($element)($widgets($element))"

            if { !$required_p($element) } {
                append form_element_header ",optional"
            }
            lappend form_element $form_element_header

            # The label
            lappend form_element [list label $labels($element)]

            # HTML
            lappend form_element [list html $html($element)]

            # Help Text
            lappend form_element [list help_text $help_text($element)]
            
            # The form element is finished - add it to the list
            lappend form_elements $form_element
        } else {
            lappend form_elements "${element}:text(hidden),optional [list value {}]"
        }
    }

    return $form_elements
}

ad_proc -public auth::create_local_account {
    {-user_id ""}
    {-authority_id:required}
    {-username ""}
    {-array:required}
} {
    Create the local account for a user.

    @param array Name of an array containing the registration elements to update.

    @return Array list containing the following entries:

    <ul>
    <li> creation_status:  ok, data_error, reg_error, failed_to_connect. Says whether user creation succeeded.
    <li> creation_message: Information about the problem, to be relayed to the user. If creation_status is not ok, then either
    creation_message or element_messages is guaranteed to be non-empty, and both are
    guaranteed to be in the array list.  May contain HTML.
    <li> element_messages: list of (element_name, message, element_name, message, ...) of
    errors on the individual registration elements.
    to be relayed on to the user. If creation_status is not ok, then either
    creation_message or element_messages is guaranteed to be non-empty, and both are
    guaranteed to be in the array list. Cannot contain HTML.
    <li> account_status:   ok, closed. Only set if creation_status was ok, this says whether the newly created account
    is ready for use or not. For example, we may require approval, in which case the account
    would be created but closed.
    <li> account_message:  A human-readable explanation of why the account was closed. May include HTML, and thus shouldn't
    be quoted. Guaranteed to be non-empty if account_status is not ok.
    </ul>

    All entries are guaranteed to always be set, but may be empty.
} {
    upvar 1 $array user_info

    array set result {
        creation_status reg_error
        creation_message {}
        element_messages {}
        account_status ok
        account_message {}
        user_id {}
    }

    # Default all elements to the empty string
    foreach elm [get_all_registration_elements] {
        if { ![info exists user_info($elm)] } {
            set user_info($elm) {}
        }
    }

    # Validate data
    auth::validate_account_info \
        -authority_id $authority_id \
        -username $username \
        -user_array user_info \
        -message_array element_messages

    # Handle validation errors
    if { [array size element_messages] > 0 } {
        return [list \
                    creation_status "data_error" \
                    creation_message {} \
                    element_messages [array get element_messages] \
                   ]
    }

    # Admin approval
    set system_name [ad_system_name]
    if { [parameter::get -parameter RegistrationRequiresApprovalP -default 0] } {
        set member_state "needs approval"
        set result(account_status) "closed"
        set result(account_message) [_ acs-subsite.Registration_Approval_Notice]
    } else {
        set member_state "approved"
    }

    if { ![info exists user_info(email_verified_p)] || $user_info(email_verified_p) eq "" } {
        if { [parameter::get -parameter RegistrationRequiresEmailVerificationP -default 0] } {
            set user_info(email_verified_p) "f"
        } else {
            set user_info(email_verified_p) "t"
        }
    }

    # Default a local account username
    if { $user_info(authority_id) == [auth::authority::local] \
             && [auth::UseEmailForLoginP] \
             && $username eq "" } {

        # Generate a username that's guaranteed to be unique
        # Rather much work, but that's the best I could think of

        # Default to email
        set username [string tolower $user_info(email)]

        # Check if it already exists
        set existing_user_id [acs_user::get_by_username -authority_id $authority_id -username $username]

        # If so, add -2 or -3 or ... to make it unique
        if { $existing_user_id ne "" } {
            set match "${username}-%"
            set existing_usernames [db_list select_existing_usernames {
                select username
                from   users
                where  authority_id = :authority_id
                and    username like :match
            }]

            set number 2
            foreach existing_username $existing_usernames {
                if { [regexp "^${username}-(\\d+)\$" $existing_username match existing_number] } {
                    # matches the foo-123 pattern
                    if { $existing_number >= $number } { set number [expr {$existing_number + 1}] }
                }
            }
            set username "$username-$number"
            ns_log Notice "auth::create_local_account: user's email was already used as someone else's username, setting username to $username"
        }
    }

    set error_p 0
    with_catch errmsg {
        # We create the user without a password
        # If it's a local account, that'll get set later
        set user_id [auth::create_local_account_helper \
                         $user_info(email) \
                         $user_info(first_names) \
                         $user_info(last_name) \
                         {} \
                         $user_info(secret_question) \
                         $user_info(secret_answer) \
                         $user_info(url) \
                         $user_info(email_verified_p) \
                         $member_state \
                         $user_id \
                         $username \
                         $user_info(authority_id) \
                         $user_info(screen_name)]

        # Update person.bio
        if { [info exists user_info(bio)] } {
            person::update_bio \
                -person_id $user_id \
                -bio $user_info(bio)
        }
    } {
        set error_p 1
    }

    if { $error_p || $user_id == 0 } {
        set result(creation_status) "failed_to_connect"
        set result(creation_message) [_ acs-subsite.Error_trying_to_register]
        ns_log Error "auth::create_local_account: Error creating local account.\n$::errorInfo"
        return [array get result]
    }

    set result(user_id) $user_id

    if { $username eq "" } {
        set username [acs_user::get_element -user_id $user_id -element username]
    }
    set result(username) $username

    # Creation succeeded
    set result(creation_status) "ok"

    if { [parameter::get -parameter RegistrationRequiresEmailVerificationP -default 0] } {
        set email $user_info(email)
        set result(account_status) "closed"
        set result(account_message) "<p>[_ acs-subsite.lt_Registration_informat_1]</p><p>[_ acs-subsite.lt_Please_read_and_follo]</p>"

        with_catch errmsg {
            auth::send_email_verification_email -user_id $user_id
        } {
            ns_log Error "auth::create_local_account: Error sending out email verification email to email $email:\n$::errorInfo"
            set auth_info(account_message) [_ acs_subsite.Error_sending_verification_mail]
        }
    }

    return [array get result]
}

ad_proc -private auth::create_local_account_helper {
    email
    first_names
    last_name
    password
    password_question
    password_answer
    {url ""}
    {email_verified_p "t"}
    {member_state "approved"}
    {user_id ""}
    {username ""}
    {authority_id ""}
    {screen_name ""}
} {
    Creates a new user in the system.  The user_id can be specified as an argument to enable double click protection.
    If this procedure succeeds, returns the new user_id.  Otherwise, returns 0.

    @see auth::create_user
    @see auth::create_local_account
} {
    if { $user_id eq "" } {
        set user_id [db_nextval acs_object_id_seq]
    }

    if { $password_question eq "" } {
        set password_question [db_null]
    }

    if { $password_answer eq "" } {
        set password_answer [db_null]
    }

    if { $url eq "" } {
        set url [db_null]
    }

    set creation_user ""
    set peeraddr ""

    # This may fail, either because there's no connection, or because
    # we're in the bootstrap-installer, at which point [ad_conn user_id] is undefined.
    catch {
        set creation_user [ad_conn user_id]
        set peeraddr [ad_conn peeraddr]
    }

    set salt [sec_random_token]
    set hashed_password [ns_sha1 "$password$salt"]

    set error_p 0
    db_transaction {

        set user_id [db_exec_plsql user_insert {}]

        # set password_question, password_answer
        db_dml update_question_answer {}

        if {[catch {
            # Call the extension
            acs_user_extension::user_new -user_id $user_id
        } errmsg]} {
            # At this point, we don't want the user addition to fail
            # if some extension is screwing things up
        }

    } on_error {
        # we got an error.  log it and signal failure.
        ns_log Error "Problem creating a new user: $::errorInfo"
        set error_p 1
    }

    if { $error_p } {
        return 0
    }
    # success.
    return $user_id
}



ad_proc -public auth::update_local_account {
    {-authority_id:required}
    {-username:required}
    {-array:required}
} {
    Update the local account for a user.

    @param array Name of an array containing the registration elements to update.

    @return Array list containing the following entries:

    <ul>
    <li> update_status:    ok, data_error, update_error, failed_to_connect. Says whether user update succeeded.
    <li> update_message:   Information about the problem, to be relayed to the user. If update_status is not ok, then either
    update_message or element_messages is guaranteed to be non-empty, and both are
    guaranteed to be in the array list.  May contain HTML.
    <li> element_messages: list of (element_name, message, element_name, message, ...) of
    errors on the individual registration elements.
    to be relayed on to the user. If update_status is not ok, then either
    udpate_message or element_messages is guaranteed to be non-empty, and both are
    guaranteed to be in the array list. Cannot contain HTML.
    </ul>

    All entries are guaranteed to always be set, but may be empty.
} {
    upvar 1 $array user_info

    array set result {
        update_status update_error
        update_message {}
        element_messages {}
        user_id {}
    }

    # Validate data
    auth::validate_account_info \
        -update \
        -authority_id $authority_id \
        -username $username \
        -user_array user_info \
        -message_array element_messages

    # Handle validation errors
    if { [array size element_messages] > 0 } {
        return [list \
                    update_status "data_error" \
                    update_message {} \
                    element_messages [array get element_messages] \
                   ]
    }

    # We get user_id from validate_account_info above, and set it in the result array so our caller can get it
    set user_id $user_info(user_id)
    set result(user_id) $user_id

    set error_p 0
    with_catch errmsg {

        db_transaction {
            # Update persons: first_names, last_name
            if { [info exists user_info(first_names)] } {
                # We know that validate_account_info will not let us update only one of the two
                person::update \
                    -person_id $user_id \
                    -first_names $user_info(first_names) \
                    -last_name $user_info(last_name)
            }

            # Update person.bio
            if { [info exists user_info(bio)] } {
                person::update_bio \
                    -person_id $user_id \
                    -bio $user_info(bio)
            }

            # Update parties: email, url
            if { [info exists user_info(email)] } {
                party::update \
                    -party_id $user_id \
                    -email $user_info(email)
            }
            if { [info exists user_info(url)] } {
                party::update \
                    -party_id $user_id \
                    -url $user_info(url)
            }

            # Update users: email_verified_p
            if { [info exists user_info(email_verified_p)] } {
                acs_user::update \
                    -user_id $user_id \
                    -email_verified_p $user_info(email_verified_p)
            }

            # Update users: screen_name
            if { [info exists user_info(screen_name)] } {
                acs_user::update \
                    -user_id $user_id \
                    -screen_name $user_info(screen_name)
            }

            if { [info exists user_info(username)] } {
                acs_user::update \
                    -user_id $user_id \
                    -username $user_info(username)
            }

            if { [info exists user_info(authority_id)] } {
                acs_user::update \
                    -user_id $user_id \
                    -authority_id $user_info(authority_id)
            }

            # TODO: Portrait
        }
    } {
        set error_p 1
    }

    if { $error_p } {
        set result(update_status) "failed_to_connect"
        set result(update_message) [_ acs-subsite.Error_update_account_info]
        ns_log Error "Error updating local account.\n$::errorInfo"
        return [array get result]
    }

    # Update succeeded
    set result(update_status) "ok"

    return [array get result]
}


ad_proc -public auth::delete_local_account {
    {-authority_id:required}
    {-username:required}
} {
    Delete the local account for a user.

    @return Array list containing the following entries:

    <ul>
    <li> delete_status:  ok, delete_error, failed_to_connect. Says whether user deletion succeeded.
    <li> delete_message: Information about the problem, to be relayed to the user. If delete_status is not ok, then
    delete_message is guaranteed to be non-empty. May contain HTML.
    </ul>

    All entries are guaranteed to always be set, but may be empty.
} {
    array set result {
        delete_status ok
        delete_message {}
        user_id {}
    }

    set user_id [acs_user::get_by_username \
                     -authority_id $authority_id \
                     -username $username]

    if { $user_id eq "" } {
        set result(delete_status) "delete_error"
        set result(delete_message) [_ acs-subsite.No_user_with_this_username]
        return [array get result]
    }

    # Mark the account banned
    acs_user::ban -user_id $user_id

    set result(user_id) $user_id

    return [array get result]
}


ad_proc -public auth::set_email_verified {
    {-user_id:required}
} {
    Update an OpenACS record with the fact that the email address on
    record was verified.
} {
    acs_user::update \
        -user_id $user_id \
        -email_verified_p "t"
}

ad_proc -private auth::verify_account_status {} {
    Verify the account status of the current user,
    and set [ad_conn account_status] appropriately.
} {
    # Just recheck the authentication cookie, and it'll do the verification for us
    sec_login_handler
}




#####
#
# auth namespace private procs
#
#####

ad_proc -private auth::get_local_account {
    {-return_url ""}
    {-username:required}
    {-authority_id ""}
    {-email ""}
    {-first_names ""}
    {-last_name ""}
} {
    Get the user_id of the local account for the given
    username and domain combination.

    @param username The username to find

    @param authority_id The ID of the authority to ask to verify the user. Leave blank for local authority.
} {
    array set auth_info [list]

    # Will return:
    #   auth_info(account_status)
    #   auth_info(account_message)
    #   auth_info(user_id)

    if { $authority_id eq "" } {
        set authority_id [auth::authority::local]
    }
    #ns_log notice "auth::get_local_account authority_id = '${authority_id}' local = [auth::authority::local]"
    with_catch errmsg {
        acs_user::get -authority_id $authority_id -username $username -array user
        set account_found_p 1
    } {
        set account_found_p 0
    }
    if { !$account_found_p } {

        # Try for an on-demand sync
        array set info_result [auth::user_info::GetUserInfo \
                                   -authority_id $authority_id \
                                   -username $username]

        if {$info_result(info_status) eq "ok"} {

            array set user $info_result(user_info)

            if {$email ne ""
                && (![info exists user(email)] || $user(email) eq "")
            } {
                set user(email) $email
            }
            if {$first_names ne ""
                && (![info exists user(first_names)] || $user(first_names) eq "")
            } {
                set user(first_names) $first_names
            }
            if {$last_name ne ""
                && (![info exists user(last_name)] || $user(last_name) eq "")
            } {
                set user(last_name) $last_name
            }
            array set creation_info [auth::create_local_account \
                                         -authority_id $authority_id \
                                         -username $username \
                                         -array user]

            if {$creation_info(creation_status) eq "ok"} {
                acs_user::get -authority_id $authority_id -username $username -array user
            } else {
                set auth_info(account_status) "closed"
                # Used to get help contact info
                auth::authority::get -authority_id $authority_id -array authority
                set system_name [ad_system_name]
                set auth_info(account_message) "You have successfully authenticated, but we were unable to create an account for you on $system_name. "
                set auth_info(element_messages) $creation_info(element_messages)
                append auth_info(account_message) "The error was: $creation_info(element_messages). Please contact the system administrator."

                if { $authority(help_contact_text) ne "" } {
                    append auth_info(account_message) "<p><h3>Help Information</h3>"
                    append auth_info(account_message) [ad_html_text_convert \
                                                           -from $authority(help_contact_text_format) \
                                                           -to "text/html" -- $authority(help_contact_text)]
                }
                return [array get auth_info]
            }

        } else {

            # Local user account doesn't exist
            set auth_info(account_status) "closed"

            # Used to get help contact info
            auth::authority::get -authority_id $authority_id -array authority
            set system_name [ad_system_name]
            set auth_info(account_message) [_ acs-subsite.Success_but_no_account_yet]

            if { $authority(help_contact_text) ne "" } {
                append auth_info(account_message) [_ acs-subsite.Help_information]
                append auth_info(account_message) [ad_html_text_convert \
                                                       -from $authority(help_contact_text_format) \
                                                       -to "text/html" -- $authority(help_contact_text)]
            }

            return [array get auth_info]
        }
    }

    # Check local account status
    array set auth_info [auth::check_local_account_status \
                             -user_id $user(user_id) \
                             -return_url $return_url \
                             -member_state $user(member_state) \
                             -email_verified_p $user(email_verified_p) \
                             -screen_name $user(screen_name) \
                             -password_age_days $user(password_age_days)]

    # Return user_id
    set auth_info(user_id) $user(user_id)

    return [array get auth_info]
}

ad_proc -private auth::check_local_account_status {
    {-return_url ""}
    {-no_dialogue:boolean}
    {-user_id:required}
    {-member_state:required}
    {-email_verified_p:required}
    {-screen_name:required}
    {-password_age_days:required}
} {
    Check the account status of a user with the given parameters.

    @param no_dialogue If specified, will not send out email or in other ways converse with the user

    @return An array-list with account_status, account_url and account_message

} {
    # Initialize to 'closed', because most cases below mean the account is closed
    set result(account_status) "closed"

    # system_name and email is used in some of the I18N messages
    set system_name [ad_system_name]
    acs_user::get -user_id $user_id -array user
    set authority_id $user(authority_id)
    set email $user(email)

    switch $member_state {
        approved {
            set PasswordExpirationDays [parameter::get \
                                            -parameter PasswordExpirationDays \
                                            -package_id [ad_acs_kernel_id] \
                                            -default 0]

            if { $email_verified_p == "f" } {
                if { !$no_dialogue_p } {
                    set result(account_message) "<p>[_ acs-subsite.lt_Registration_informat]</p><p>[_ acs-subsite.lt_Please_read_and_follo]</p>"

                    with_catch errmsg {
                        auth::send_email_verification_email -user_id $user_id
                    } {
                        ns_log Error "auth::check_local_account_status: Error sending out email verification email to email $email:\n$::errorInfo"
                        set result(account_message) [_ acs-subsite.Error_sending_verification_mail]
                    }
                }

            } elseif { [acs_user::ScreenName] eq "require"
                       && $screen_name eq ""
                   } {
                set message "Please enter a screen name now."
                set result(account_url) [export_vars -no_empty \
                                             -base "[subsite::get_element -element url]user/basic-info-update" {
                                                 message return_url {edit_p 1}
                                             }]

            } elseif { $PasswordExpirationDays > 0
                       && ($password_age_days eq "" || $password_age_days > $PasswordExpirationDays)
                   } {
                set message [_ acs-subsite.Password_regular_change_now]
                set result(account_url) [export_vars -base "[subsite::get_element -element url]user/password-update" { return_url message }]
            } else {
                set result(account_status) "ok"
            }
        }
        banned {
            set result(account_message) [_ acs-subsite.lt_Sorry_but_it_seems_th]
        }
        deleted {
            set restore_url [export_vars -base "restore-user" { return_url }]
            set result(account_message) [_ acs-subsite.Account_closed]
        }
        rejected - "needs approval" {
            set result(account_message) \
                "<p>[_ acs-subsite.lt_registration_request_submitted]</p><p>[_ acs-subsite.Thank_you]</p>"
        }
        default {
            set result(account_message) [_ acs-subsite.Problem_auth_no_memb]
            ns_log Error "auth::check_local_account_status: problem with registration state machine: user_id $user_id has member_state '$member_state'"
        }
    }

    return [array get result]
}

ad_proc -public auth::get_local_account_status {
    {-user_id:required}
} {
    Return 'ok', 'closed', or 'no_account'
} {
    set result no_account
    catch {
        acs_user::get -user_id $user_id -array user
        array set check_result [auth::check_local_account_status \
                                    -user_id $user_id \
                                    -member_state $user(member_state) \
                                    -email_verified_p $user(email_verified_p) \
                                    -screen_name $user(screen_name) \
                                    -password_age_days $user(password_age_days)]

        set result $check_result(account_status)
    }
    return $result
}

ad_proc -private auth::get_user_secret_token {
    -user_id:required
} {
    Get a secret token for the user. Can be used for email verification purposes.
} {
    return [ns_sha1 "${user_id}[sec_get_token 1]"]
}

ad_proc -private auth::send_email_verification_email {
    -user_id:required
} {
    Sends out an email to the user that lets them verify their email.
    Throws an error if we couldn't send out the email.
} {
    # These are used in the messages below
    set token [auth::get_user_secret_token -user_id $user_id]
    acs_user::get -user_id $user_id -array user
    set confirmation_url [export_vars -base "[ad_url]/register/email-confirm" { token user_id }]
    set system_name [ad_system_name]

    acs_mail_lite::send -send_immediately \
        -to_addr $user(email) \
        -from_addr "\"$system_name\" <[parameter::get -parameter NewRegistrationEmailAddress -default [ad_system_owner]]>" \
        -subject [_ acs-subsite.lt_Welcome_to_system_nam] \
        -body [_ acs-subsite.lt_To_confirm_your_regis]
}

ad_proc -private auth::validate_account_info {
    {-update:boolean}
    {-authority_id:required}
    {-username:required}
    {-user_array:required}
    {-message_array:required}
} {
    Validates user info and returns errors, if any.

    @param update        Set this flag if you're updating an existing record, meaning we shouldn't check for duplicates.

    @param user_array    Name of an array in the caller's namespace which contains the registration elements.

    @param message_array Name of an array where you want the validation errors stored, keyed by element name.
} {
    upvar 1 $user_array user
    upvar 1 $message_array element_messages

    set required_elms { }
    if { !$update_p } {
        set required_elms [concat $required_elms { first_names last_name email }]
    }

    foreach elm $required_elms {
        if { ![info exists user($elm)] || $user($elm) eq "" } {
            set element_messages($elm) "Required"
        }
    }

    if { [info exists user(email)] } {
        set user(email) [string trim $user(email)]
    }

    if { [info exists user(username)] } {
        set user(username) [string trim $user(username)]
    }

    if { $update_p } {
        set user(user_id) [acs_user::get_by_username \
                               -authority_id $authority_id \
                               -username $username]

        if { $user(user_id) eq "" } {
            set this_authority [auth::authority::get_element -authority_id $authority_id -element pretty_name]
            set element_messages(username) [_ acs-subsite.Username_not_found_for_authority]
        }
    } else {
        set user(username) $username
        set user(authority_id) $authority_id
    }

    # TODO: When doing RBM's parameter, make sure that we still require both first_names and last_names, or none of them
    if { ([info exists user(first_names)] && $user(first_names) ne "")
         && [string first "<" $user(first_names)] != -1
     } {
        set element_messages(first_names) [_ acs-subsite.lt_You_cant_have_a_lt_in]
    }

    if { ([info exists user(last_name)] && $user(last_name) ne "")
         && [string first "<" $user(last_name)] != -1
     } {
        set element_messages(last_name) [_ acs-subsite.lt_You_cant_have_a_lt_in_1]
    }

    if { [info exists user(email)] && $user(email) ne "" } {
        if { ![util_email_valid_p $user(email)] } {
            set element_messages(email) [_ acs-subsite.Not_valid_email_addr]
        } else {
            set user(email) [string tolower $user(email)]
        }
    }

    if { [info exists user(url)] } {
        if { $user(url) eq "" || $user(url) eq "http://" } {
            # The user left the default hint for the url
            set user(url) {}
        } elseif { ![util_url_valid_p $user(url)] } {
            set valid_url_example "http://openacs.org/"
            set element_messages(url) [_ acs-subsite.lt_Your_URL_doesnt_have_]
        }
    }

    if { [info exists user(screen_name)] } {
        set screen_name_user_id [acs_user::get_user_id_by_screen_name -screen_name $user(screen_name)]
        if { $screen_name_user_id ne "" && (!$update_p || $screen_name_user_id != $user(user_id)) } {
            set element_messages(screen_name) [_ acs-subsite.screen_name_already_taken]

            # We could do the same logic as below with 'stealing' the screen_name of an old, banned user.
        }
    }

    if { [info exists user(email)] && $user(email) ne "" } {
        # Check that email is unique
        set email $user(email)
        set email_party_id [party::get_by_email -email $user(email)]

        if { $email_party_id ne "" && (!$update_p || $email_party_id != $user(user_id)) } {
            # We found a user with this email, and either we're not updating,
            # or it's not the same user_id as the one we're updating

            if { [acs_object_type $email_party_id] ne "user" } {
                set element_messages(email) [_ acs-subsite.Have_group_mail]
            } else {
                acs_user::get \
                    -user_id $email_party_id \
                    -array email_user
                switch $email_user(member_state) {
                    banned {
                        set element_messages(email) [_ acs-subsite.lt_This_user_is_deleted]
                    }
                    default {
                        set element_messages(email) [_ acs-subsite.Have_user_mail]
                    }
                }
            }
        }
    }

    # They're trying to set the username
    if { [info exists user(username)] && $user(username) ne "" } {
        # Check that username is unique
        set username_user_id [acs_user::get_by_username -authority_id $authority_id -username $user(username)]

        if { $username_user_id ne ""
             && (!$update_p || $username_user_id != $user(user_id)) } {
            # We already have a user with this username, and either
            # we're not updating, or it's not the same user_id as the
            # one we're updating

            set username_member_state [acs_user::get_element -user_id $username_user_id -element member_state]
            switch $username_member_state {
                banned {
                    set element_messages(username) [_ acs-subsite.lt_This_user_is_deleted]
                }
                default {
                    set element_messages(username) [_ acs-subsite.Have_user_name]
                }
            }
        }
    }
}

ad_proc -private auth::can_admin_system_without_authority_p {
    {-authority_id:required}
} {
    Before disabling or deleting an authority we need to check
    that there is at least one site-wide admin in a different
    authority that can administer the system. This proc returns
    1 if there is such an admin and 0 otherwise.

    @author Peter Marklund
} {
    #
    # Count all users from other authorities having swa admins (having
    # admin rights on the magic object 'security_context_root').
    #
    set number_of_admins_left [db_string count_admins_left {
        select count(*)
        from acs_permissions p,
             party_approved_member_map m,
             acs_magic_objects amo,
             cc_users u
        where amo.name = 'security_context_root'
        and p.object_id = amo.object_id
        and p.grantee_id = m.party_id
        and u.user_id = m.member_id
        and u.member_state = 'approved'
        and u.authority_id <> :authority_id
        and acs_permission.permission_p(amo.object_id, u.user_id, 'admin')
    }]

    return [ad_decode $number_of_admins_left "0" "0" "1"]
}

#####
#
# auth::authentication
#
#####

ad_proc -private auth::authentication::Authenticate {
    {-authority_id:required}
    {-username:required}
    {-password:required}
} {
    Invoke the Authenticate service contract operation for the given authority.

    @param authority_id The ID of the authority to ask to verify the user.
    @param username Username of the user.
    @param passowrd The password as the user entered it.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "auth_impl_id"]

    if { $impl_id eq "" } {
        # No implementation of authentication
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support authentication"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    # See http://openacs.org/bugtracker/openacs/bug?format=table&f%5fstate=8&bug%5fnumber=2200
    # Basically, we want upgrades to work, so we have to check for
    # version number -jfr

    set authentication_version [util_memoize [list apm_highest_version_name acs-authentication]]
    set old_version_p [util_memoize [list apm_version_names_compare 5.1.3 $authentication_version]]

    if {[string is true $old_version_p]} {
        return [acs_sc::invoke \
                    -error \
                    -impl_id $impl_id \
                    -operation Authenticate \
                    -call_args [list $username $password $parameters]]

    } else {
        return [acs_sc::invoke \
                    -error \
                    -impl_id $impl_id \
                    -operation Authenticate \
                    -call_args [list $username $password $parameters $authority_id]]
    }
}

#####
#
# auth::registration
#
#####

ad_proc -private auth::registration::Register {
    {-authority_id:required}
    {-username ""}
    {-password ""}
    {-first_names ""}
    {-last_name ""}
    {-screen_name ""}
    {-email ""}
    {-url ""}
    {-secret_question ""}
    {-secret_answer ""}
} {
    Invoke the Register service contract operation for the given authority.

    @authority_id Id of the authority.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "register_impl_id"]

    if { $impl_id eq "" } {
        # No implementation of authentication
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support account registration"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation Register \
                -call_args [list $parameters \
                                $username \
                                $authority_id \
                                $first_names \
                                $last_name \
                                $screen_name \
                                $email \
                                $url \
                                $password \
                                $secret_question \
                                $secret_answer]]
}

ad_proc -private auth::registration::GetElements {
    {-authority_id:required}
} {
    @author Peter Marklund
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "register_impl_id"]

    if { $impl_id eq "" } {
        # No implementation of authentication
        set authority_pretty_name [auth::authority::get_element -authority_id $authority_id -element "pretty_name"]
        error "The authority '$authority_pretty_name' doesn't support account registration"
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation GetElements \
                -call_args [list $parameters]]
}



#####
#
# auth::user_info
#
#####

ad_proc -private auth::user_info::GetUserInfo {
    {-authority_id:required}
    {-username:required}
} {
    Invoke the Register service contract operation for the given authority.

    @authority_id Id of the authority.
} {
    set impl_id [auth::authority::get_element -authority_id $authority_id -element "user_info_impl_id"]

    if { $impl_id eq "" } {
        # No implementation of authentication
        return { info_status no_account }
    }

    set parameters [auth::driver::get_parameter_values \
                        -authority_id $authority_id \
                        -impl_id $impl_id]

    return [acs_sc::invoke \
                -error \
                -impl_id $impl_id \
                -operation GetUserInfo \
                -call_args [list $username $parameters]]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
