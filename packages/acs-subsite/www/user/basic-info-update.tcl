ad_page_contract {
    Displays form for currently logged in user to update his/her
 personal information

    @author Unknown
    @creation-date Unknown
    @cvs-id $Id$
} {
    {return_url ""}
    {user_id ""}
}

set page_title "Update Basic Information"

if { [empty_string_p $user_id] || ($user_id == [ad_conn user_id]) } {
    set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]
} else {
    set context [list $page_title]
}

set focus {}
