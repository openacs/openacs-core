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

if ![info exists confirmed_p] {
    set confirmed_p 0
}

if $confirmed_p {
    if [string equal grant $action] {
        db_exec_plsql grant_admin {
            select acs_permission__grant_permission(
                acs__magic_object_id('security_context_root'),
                :user_id,
                'admin')
        }
    } else {
        db_exec_plsql revoke_admin {
            select acs_permission__revoke_permission(
                acs__magic_object_id('security_context_root'),
                :user_id,
                'admin')
        }
    }

    ad_returnredirect $return_url
}
