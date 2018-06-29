ad_page_contract {
    Flush login attempts

    @author Günter Ernst (guenter.ernst@wu.ac.at)
    @creation-date 2018-02-19
    @cvs-id $Id$
} {
    {attempt_key:notnull,token,multiple}
}


if {$attempt_key eq "all"} {
    ::auth::login_attempts::reset_all
} else {
    foreach k $attempt_key {
        ::auth::login_attempts::reset -login_attempt_key $attempt_key
    }
}

ad_returnredirect "login-attempts"
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
