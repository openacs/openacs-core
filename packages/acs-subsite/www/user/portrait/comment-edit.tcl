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

set current_user_id [ad_verify_and_get_user_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

ad_require_permission $user_id "write"

if ![db_0or1row user_info "select 
  first_names, 
  last_name
from persons
where person_id = :user_id"] {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

if ![db_0or1row portrait_info "
select description
from cr_revisions
where revision_id = (select live_revision
                     from cr_items c, acs_rels a
                     where c.item_id = a.object_id_two
                     and a.object_id_one = :user_id
                     and a.rel_type = 'user_portrait_rel')"] {
    ad_return_complaint 1 "<li>You shouldn't have gotten here; we don't have a portrait on file for you."
    return
}

db_release_unused_handles

set context [list [list "./" "Your Portrait"] "Edit comment"]
set export_vars [export_form_vars user_id return_url]
