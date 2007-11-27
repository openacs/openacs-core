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

set portrait_p [db_0or1row "checkportrait" {}]


if { $portrait_p } {
	set story [db_string "getstory" {}]
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

if {![db_0or1row get_name {}]} {
    ad_return_error "Account Unavailable" "We can't find you (user #$user_id) in the users table.  Probably your account was deleted for some reason."
    return
}

if {$admin_p} {
    set context [list [list "./?[export_vars user_id]" [_ acs-subsite.User_Portrait]] [_ acs-subsite.Upload_Portrait]]
} else {
    set context [list [list "./?[export_vars return_url]" [_ acs-subsite.Your_Portrait]] [_ acs-subsite.Upload_Portrait]]
}

set export_vars [export_form_vars user_id return_url]

ad_return_template
