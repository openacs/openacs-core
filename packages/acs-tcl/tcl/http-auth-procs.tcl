# packages/acs-tcl/tcl/http-auth-procs.tcl
ad_library {
   Use OpenACS user logins for HTTP authentication
}

namespace eval http_auth {}

ad_proc -public http_auth::basic_authentication_decode {
    authorization
} {
    Implements decoding of authorization header as defined in RFC 7617
    "username" containing a colon character is invalid (see RFC 7617,
    Section 2). 

    @param authorization content of "Authorization:" reply header field,
                         such as e.g. "Basic 29234k3j49a"
    @result dict containing password and user
} {
    set decoded [ns_uudecode [lindex [split $authorization " "] 1]]
    #
    # $decoded should be of the form "user:password".
    #
    # The pair is invalid at least in the following situations:
    # - the username contains a colon
    # - the username is empty
    # - $decoded contains no colon
    #
    set delimiterPos [string first : $decoded]
    if {$delimiterPos > 0} {
        set user [string range $decoded 0 $delimiterPos-1]
        set password [string range $decoded $delimiterPos+1 end]
    } else {
        ns_log warning "protocol-handler: invalid user/password pair provided: $decoded"
        set password ""
        set user ""
    }
    return [list password $password user $user]
}

ad_proc http_auth::set_user_id {} {
    Get the user_id from HTTP authentication headers.
    NOTE: This should be handled through SSL since plain
    HTTP auth is easy to decode
} {

    # should be something like "Basic 29234k3j49a"
    set authorization [ns_set iget [ns_conn headers] Authorization]
    if {[string length $authorization] > 0} {
        set credentials [http_auth::basic_authentication_decode $authorization]
        foreach authority [auth::authority::get_authority_options] {
            set authority_id [lindex $authority 1]
            array set auth [auth::authenticate \
                                -username [dict get $credentials user] \
                                -password [dict get $credentials password] \
                                -authority_id $authority_id \
                                -no_cookie]
            if {$auth(auth_status) ne "ok" } {
                array set auth [auth::authenticate \
                                    -email [dict get $credentials user] \
                                    -password [dict get $credentials password] \
                                    -authority_id $authority_id \
                                    -no_cookie]
            }
            if {$auth(auth_status) eq "ok"} {
                # we can stop checking
                break
            }
        }
        if {$auth(auth_status) ne "ok" } {
            ns_log debug "\nTDAV 5.0 auth status $auth(auth_status)"
            ns_returnunauthorized
            return 0
        }
        ns_log debug "\nTDAV: auth_check OpenACS 5.0 user_id= $auth(user_id)"
        ad_conn -set user_id $auth(user_id)

    } else {
        # no authenticate header, anonymous visitor
        ad_conn -set user_id 0
        ad_conn -set untrusted_user_id 0
    }
}

ad_proc http_auth::register_filter {
    -url_pattern
    {-proc ""}
} {
    Setup HTTP authentication for a URL pattern

    @param url_pattern Follows ns_register_filter rules for defining the
                       pattern to match.
    @param proc Name of Tcl procedure to call to check permissions. Use this to
                figure out what object the URL pattern matches to. This proc should accept
                two named parameters user_id and url. Should return a valid Tcl
                true or false value. If empty the site_node matching the URL will be checked.

    @return Tcl true or false

    @author Dave Bauer (dave@solutiongrove.com)
    @creation-date 2007-03-08

} {

    ad_register_filter preauth GET $url_pattern http_auth::authorize $proc
    ad_register_filter preauth POST $url_pattern http_auth::authorize $proc
    ad_register_filter preauth HEAD $url_pattern http_auth::authorize $proc

}

ad_proc http_auth::authorize {
    conn
    args
    why
} {
    Check HTTP authentication for an OpenACS user account and
    call the registered procedure to handle the URL to check
    permissions
} {
    set user_id [http_auth::set_user_id]
    set proc [lindex $args 0]
    if {$proc eq {}} {
        set proc http_auth::site_node_authorize
    }
    return [$proc -user_id $user_id -url [ns_conn url]]
}

ad_proc http_auth::site_node_authorize {
    -user_id
    -url
} {
    Procedure to take HTTP authenticated user_id and check site_node
    permissions. Default if http auth is proc is not specified.
} {
    set node_id [site_node::get_element -element node_id -url $url]
    if {[permission::permission_p \
                -party_id $user_id \
                -privilege read \
             -object_id $node_id]} {
        return filter_ok
    }
    ns_returnunauthorized
    return filter_return
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
