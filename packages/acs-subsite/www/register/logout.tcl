# /www/register/logout.tcl

ad_page_contract {
    Logs a user out

    @cvs-id $Id$

} {
    
}

ad_user_logout 
db_release_unused_handles

ad_returnredirect "/"

