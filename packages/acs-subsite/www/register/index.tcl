ad_page_contract {
    Prompt the user for email and password.
    @cvs-id $Id$
} {
    {authority_id ""}
    {username ""}
    {email ""}
    {message ""}
    {return_url ""}
}

set expired_p 0
if { [string equal [ad_conn auth_level] "expired"] } {
    set expired_p 1
}
