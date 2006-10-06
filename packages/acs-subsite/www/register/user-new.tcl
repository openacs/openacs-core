ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
} {
    {email ""}
    {return_url [ad_pvt_home]}
}

set registration_url [parameter::get -parameter RegistrationRedirectUrl]
if {![string eq "" $registration_url]} {
    ad_returnredirect $registration_url
}