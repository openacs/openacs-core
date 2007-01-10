ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
} {
    {email ""}
    {return_url [ad_pvt_home]}
}

set registration_url [parameter::get -parameter RegistrationRedirectUrl]
if {$registration_url ne ""} {
    ad_returnredirect $registration_url
}