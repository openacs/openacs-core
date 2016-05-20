ad_page_contract {
    Displays form for currently logged in user to update his/her personal information

    @author Unknown
    @creation-date Unknown
    @cvs-id $Id$
} {
    {return_url:localurl ""}
    {user_id:naturalnum ""}
    {edit_p:boolean 0}
    {message ""}
}

set page_title [_ acs-subsite.Your_Account]

if { $user_id eq "" || ($user_id == [ad_conn untrusted_user_id]) } {
    set context [list [list [ad_pvt_home] [ad_pvt_home_name]] $page_title]
} else {
    set context [list $page_title]
}

set focus {}

set subsite_id [ad_conn subsite_id]
set user_info_template [parameter::get -parameter "UserInfoTemplate" -package_id $subsite_id]
ns_log Debug "user:: $user_info_template"
if {$user_info_template eq ""} {
    set user_info_template "/packages/acs-subsite/lib/user-info"
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
