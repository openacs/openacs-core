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

#
# Avoid page caching, across all browsers, no matter how the other
# site wide caching parameters are set. For discussion and deatils,
# see:
#
# https://stackoverflow.com/questions/49547/how-to-control-web-page-caching-across-all-browsers
#
template::head::add_meta -http_equiv Cache-Control -content "no-cache, no-store, must-revalidate" ;# HTTP/1.1
template::head::add_meta -http_equiv Pragma -content "no-cache" ;# HTTP/1.0
template::head::add_meta -http_equiv Expires -content "0" ;# Proxies

set subsite_id [ad_conn subsite_id]
set login_template [parameter::get -parameter "LoginTemplate" -package_id $subsite_id]

if {$login_template eq ""} {
    set login_template "/packages/acs-subsite/lib/login"
}

#ns_log notice "register/index.tcl: login_template <$login_template> host_node_id <$host_node_id>"

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
