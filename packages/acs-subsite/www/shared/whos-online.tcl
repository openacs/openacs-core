ad_page_contract {
    Displays who's currently online

    @cvs-id $Id$
} -properties {
    title:onevalue
    context_bar:onevalue
    last_visit_interval:onevalue
    chat_system_name:onevalue
    connected_user_id:onevalue
    users:multirow
}

set connected_user_id [ad_verify_and_get_user_id]

db_multirow users grab_users "select user_id, first_names, last_name, email
from cc_users
where last_visit > sysdate - [ad_parameter LastVisitUpdateInterval "" 600]/86400
order by upper(last_name), upper(first_names), email" 

db_release_unused_handles

set title "Who's Online?"
set context_bar [ad_context_bar_ws_or_index "Who's Online"]

set last_visit_interval [ad_parameter LastVisitUpdateInterval ""]

#if ![ad_parameter EnabledP chat 0] {
    set chat_system_name ""
#} else {
#    set chat_system_name [chat_system_name]
#}

ad_return_template
