ad_page_contract {
    Uploading user portraits

    @cvs-id $Id$
} {
    {user_id ""}
    {return_url ""}
} -properties {
    first_names:onevalue
    last_name:onevalue
    context:onevalue
    export_vars:onevalue
    
}

set current_user_id [ad_conn user_id]

set portrait_p [db_0or1row "checkportrait" {SELECT live_revision as revision_id, item_id
          FROM acs_rels a, cr_items c
          WHERE a.object_id_two = c.item_id
          AND a.rel_type = 'user_portrait_rel'
          AND a.object_id_one = :current_user_id
          AND c.live_revision is not NULL
} ]


if { $portrait_p } {
	set story [db_string "getstory" "select description from cr_revisions where revision_id = :revision_id"]
} else {
	set story ""
	set revision_id ""
}

if {$user_id eq ""} {
    subsite::upload_allowed
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

ad_require_permission $user_id "write"

if {![db_0or1row name "select 
  first_names, last_name
from persons 
where person_id=:user_id"]} {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

if {$admin_p} {
    set context [list [list "./?user_id=$user_id" "User's Portrait"] "Upload Portrait"]
} else {
    set context [list [list "./?return_url=$return_url" "Your Portrait"] "Upload Portrait"]
}

set export_vars [export_form_vars user_id return_url]

ad_return_template
