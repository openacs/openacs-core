ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    {authority_id:naturalnum ""}
    {username ""}
    {email ""}
    {return_url:localurl ""}
    {host_node_id:naturalnum ""}
} -validate {
    valid_email -requires email {
        if {![regexp {^[\w.@+/=$%!*~-]+$} $email]} {
            ad_complain "invalid email address"
        }
    }
}

set subsite_id [ad_conn subsite_id]
set login_template [parameter::get -parameter "LoginTemplate" -package_id $subsite_id]

if {$login_template eq ""} {
    set login_template "/packages/acs-subsite/lib/login"
}

ns_log notice "register/index.tcl: login_template <$login_template> host_node_id <$host_node_id>"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
