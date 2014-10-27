ad_page_contract {
    Page for users to register themselves on the site.

    @cvs-id $Id$
} {
    token:notnull,trim
    user_id:naturalnum,notnull
    
    {return_url ""}
}

set subsite_id [ad_conn subsite_id]
set email_confirm_template [parameter::get -parameter "EmailConfirmTemplate" -package_id $subsite_id]

if {$email_confirm_template eq ""} {
    set email_confirm_template "/packages/acs-subsite/lib/email-confirm"
}
