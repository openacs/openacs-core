ad_page_contract {
    Displays form for currently logged in user to update his/her
 personal information

    @author Unknown
    @creation-date Unknown
    @cvs-id $Id$
} {
    {return_url ""}
    {user_id ""}
    {edit_p 0}
    {message ""}
}

set page_title [_ acs-subsite._Update_Basic_Information]

if { [empty_string_p $user_id] || ($user_id == [ad_conn untrusted_user_id]) } {
    set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]
} else {
    set context [list $page_title]
}

set focus {}

