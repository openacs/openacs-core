ad_page_contract {
    Displays who's currently online

    @author Peter Marklund

    @cvs-id $Id$
} -properties {
    title:onevalue
    context:onevalue
}

set doc(title) [_ acs-subsite.Whos_Online_title]
set context [list $doc(title)]

set whos_online_interval [whos_online::interval]

template::list::create \
    -name online_users \
    -multirow online_users \
    -no_data [_ acs-subsite.Nobody_is_online] \
    -elements {
        name {
            label "[_ acs-subsite.User_name]"
            link_url_col url
        }
        online_time_pretty {
            label "[_ acs-subsite.Online_time]"
            html { align right }
        }
    }

set users [list]
foreach user_id [whos_online::user_ids] {
    set user [acs_user::get -user_id $user_id]
    if {$user eq ""} {
        #
        # This user was online but now does not exist anymore. This
        # can happen e.g. when a test user has issued requests to the
        # system and was then deleted.
        #
        continue
    }

    set first_request_minutes [expr {[whos_online::seconds_since_first_request $user_id] / 60}]

    lappend users [list \
                       "[dict get $user first_names] [dict get $user last_name]" \
                       [acs_community_member_url -user_id $user_id] \
                       "$first_request_minutes minutes"]

}

set users [lsort -index 0 $users]

multirow create online_users name url online_time_pretty

foreach elm $users {
    multirow append online_users \
        [lindex $elm 0] \
        [lindex $elm 1] \
        [lindex $elm 2]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
