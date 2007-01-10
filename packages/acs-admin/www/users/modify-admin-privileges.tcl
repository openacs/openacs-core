ad_page_contract {

    Grants or revokes site-wide admin privileges.
    @author Andrew Spencer (andrew@fallingblue.com)
    @cvs-id $Id$

} {
    user_id:notnull
    action:notnull
    confirmed_p:optional
}

set confirmed_url "/acs-admin/users/modify-admin-privileges?user_id=$user_id&action=$action&confirmed_p=1"

set return_url "/acs-admin/users/one?user_id=$user_id"

set context [list [list "./" "Users"] "Modify privileges"]

if {![info exists confirmed_p]} {
    set confirmed_p 0
}

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
