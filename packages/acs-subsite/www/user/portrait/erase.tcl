ad_page_contract {
    Erases a portrait

    @cvs-id $Id$
} {
    {return_url "" }
    {user_id ""}
} -properties {
    context_bar:onevalue
    export_vars:onevalue
    admin_p:onevalue
}

set current_user_id [ad_verify_and_get_user_id]

if [empty_string_p $user_id] {
    set user_id $current_user_id
    set admin_p 0
} else {
    set admin_p 1
}

ad_require_permission $user_id "write"

if {$admin_p} {
    set context_bar [ad_context_bar_ws [list "index?user_id=$user_id" "User's Portrait"] "Erase"]
} else {
    set context_bar [ad_context_bar_ws [list "index" "Your Portrait"] "Erase"]
}

set export_vars [export_form_vars user_id return_url]


ad_return_template
