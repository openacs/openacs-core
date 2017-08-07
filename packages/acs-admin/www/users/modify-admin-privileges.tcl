ad_page_contract {

    Grants or revokes site-wide admin privileges.
    @author Andrew Spencer (andrew@fallingblue.com)
    @cvs-id $Id$

} {
    user_id:naturalnum,notnull,verify
    action:notnull,verify
    {confirmed_p:boolean 0}
}

set confirmed_url [export_vars -base /acs-admin/users/modify-admin-privileges {
    user_id:sign(max_age=60) action:sign {confirmed_p 1}
}]
set return_url [export_vars -base /acs-admin/users/one {user_id}]

set context [list [list "./" "Users"] "Modify privileges"]

if {$confirmed_p} {
    if {"grant" eq $action} {
        permission::grant -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
    } else {
        permission::revoke -object_id [acs_magic_object "security_context_root"] -party_id $user_id -privilege "admin"
    }

    ad_returnredirect $return_url

    # We need to flush all permission checks pertaining to this user.
    # this is expensive so maybe we should check if we in fact are cacheing.
    util_memoize_flush_regexp "^permission::.*-party_id $user_id"
}

acs_user::get -user_id $user_id -array user_info


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
