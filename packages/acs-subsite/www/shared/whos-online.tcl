ad_page_contract {
    Displays who's currently online

    @author Peter Marklund

    @cvs-id $Id$
} -properties {
    title:onevalue
    context:onevalue
}

set title "Who's Online?"
set context [list "Who's Online"]

set whos_online_interval [util::whos_online::interval]

template::list::create \
    -name online_users \
    -multirow online_users \
    -elements {
        user_link {
            label "User name"
            display_template {
                @online_users.user_link;noquote@
            }
        }
        last_request_seconds {
            label "Seconds since last request"
        }
    }

multirow create online_users user_link last_request_seconds
foreach user_id [util::whos_online::user_ids] {
    acs_user::get -user_id $user_id -array user
    set user_name "$user(first_names) $user(last_name)"
    set user_link [acs_community_member_link -user_id $user_id -label $user_name]

    set last_request_seconds [util::whos_online::time_since_last_request $user_id]

    multirow append online_users $user_link $last_request_seconds
}

ad_return_template
