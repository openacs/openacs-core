ad_page_contract {

    Grants or revokes site-wide admin privileges.
    @author Andrew Spencer (andrew@fallingblue.com)
    @cvs-id $Id$

} {
    user_id:naturalnum,notnull,verify
    action:notnull,verify
    {confirmed_p:boolean,notnull 0}
}

set confirmed_url [export_vars -base /acs-admin/users/modify-admin-privileges {
    user_id:sign(max_age=60) action:sign {confirmed_p 1}
}]

set return_url [acs_community_member_admin_url -user_id $user_id]

set context [list [list "./" "Users"] "Modify privileges"]

if {$confirmed_p} {
    if {"grant" eq $action} {
        permission::grant -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
    } else {
        permission::revoke -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
    }

    ad_returnredirect $return_url

    #
    # Flush all permission checks pertaining to this user.
    #
    permission::cache_flush -party_id $user_id
    
    ad_script_abort
}

acs_user::get -user_id $user_id -array user_info


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
