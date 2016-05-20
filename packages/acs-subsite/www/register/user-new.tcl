ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
} {
    {email ""}
    {return_url:return_url [ad_pvt_home]}
} -validate {
    valid_return_url {
        if {[string first {$} $return_url] > -1} {
            ad_complain "return_url contains invalid character"
        }
    }
}

set registration_url [parameter::get -parameter RegistrationRedirectUrl]
if {$registration_url ne ""} {
    ad_returnredirect [export_vars -base "$registration_url" -url {return_url email}]
}

set subsite_id [ad_conn subsite_id]
set user_new_template [parameter::get -parameter "UserNewTemplate" -package_id $subsite_id]

if {$user_new_template eq ""} {
    set user_new_template "/packages/acs-subsite/lib/user-new"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
