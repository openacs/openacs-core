ad_page_contract {
    screen to edit the comment associated with a user's portrait

    @author mbryzek@arsdigita.com
    @creation-date 22 Jun 2000
    @cvs-id $Id$
} {
    {return_url "" }
    {user_id ""}
} -properties {
    context:onevalue
    export_vars:onevalue
    description:onevalue
    first_names:onevalue
    last_name:onevalue
}

set current_user_id [ad_conn user_id]

if {$user_id eq ""} {
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

ad_require_permission $user_id "write"

if {![db_0or1row user_info {}]} {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

if {![db_0or1row portrait_info {}]} {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

db_release_unused_handles

set context [list [list "./" [_ acs-subsite.Your_Portrait]] [_ acs-subsite.edit_comment]]
set export_vars [export_form_vars user_id return_url]

