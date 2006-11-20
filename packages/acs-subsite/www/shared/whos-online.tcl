ad_page_contract {
    Displays who's currently online

    @author Peter Marklund

    @cvs-id $Id$
} -properties {
    title:onevalue
    context:onevalue
}

#unima2-kk "Who's online" - acs-subsite.shared_whos_online
set title [_ acs-subsite.shared_whos_online]
set context [list "Who's Online"]

set whos_online_interval [whos_online::interval]

template::list::create \
    -name online_users \
    -multirow online_users \
    -no_data [_ acs-subsite.shared_no_user_online] \
    -elements {
        name {
            label "#acs-subsite.shared_user_name#"
            link_url_col url
        }
        online_time_pretty {
            label "#acs-subsite.shared_online_time#"
            html { align right }
        }
    }

set users [list]

foreach user_id [whos_online::user_ids] {
    acs_user::get -user_id $user_id -array user

    set first_request_minutes [expr [whos_online::seconds_since_first_request $user_id] / 60]

    lappend users [list \
                       "$user(first_names) $user(last_name)" \
                       [acs_community_member_url -user_id $user_id] \
                       "$first_request_minutes #acs-subsite.shared_minutes#"]

}

set users [lsort -index 0 $users]

multirow create online_users name url online_time_pretty

foreach elm $users {
    multirow append online_users \
        [lindex $elm 0] \
        [lindex $elm 1] \
        [lindex $elm 2]
}

