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

if [empty_string_p $user_id] {
    subsite::upload_allowed
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

ad_require_permission $user_id "write"

if ![db_0or1row name "select 
  first_names, last_name
from persons 
where person_id=:user_id"] {
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
