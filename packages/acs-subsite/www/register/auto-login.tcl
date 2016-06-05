ad_page_contract {
    Log in a user without the timestamp protection of the /register/index page.
    Useful when you need to log in a user from a different server.

    @author Peter Marklund
} {
    email
    password
    {return_url:localurl "/"}
}

array set auth_info [auth::authenticate \
                         -return_url $return_url \
                         -email [string trim $email] \
                         -password $password]

if {$auth_info(auth_status) eq "ok"} {
    ad_returnredirect $return_url
    ad_script_abort
} else {
    # Login problem - redirect to login form
    ad_returnredirect [export_vars -base /register { email return_url }]    
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
