# /www/register/logout.tcl

ad_page_contract {
    Logs a user out

    @cvs-id $Id$

} {
	{return_url "/"}
    
}

ad_user_logout 
db_release_unused_handles

ad_returnredirect $return_url

