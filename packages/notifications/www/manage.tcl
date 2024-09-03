ad_page_contract {

    Manage notifications for one user

    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 2002-07-22
} {
    {user_id:naturalnum ""}
}

auth::require_login
if { $user_id ne "" && $user_id ne [ad_conn user_id] } {
    #
    # Manage notification of someone else.  We need to verify that
    # current user is an admin.
    #
    permission::require_permission -object_id [ad_conn package_id] -privilege "admin"

    set user_dict [acs_user::get -user_id $user_id]
    set doc(title) "Manage notifications of [dict get $user_dict email]"
    set elements {
        type {
            label {[_ notifications.Notification_type]}
        }
        object_name {
            label {[_ notifications.Item]}
            link_url_eval {[export_vars -base subscribers { object_id }]}
        }
        interval {
            label {[_ notifications.Frequency]}
        }
        action {
            label {[_ notifications.Action]}
            display_template {\#notifications.Unsubscribe\#}
            link_url_eval {[export_vars -base request-delete { request_id {return_url [ad_return_url]} }]}
            link_html {title "\#notifications.Unsubscribe_from_object_name\#"}
        }
    }
    set notice "[acs_community_member_link -user_id $user_id -label [person::name -person_id $user_id]] - [_ notifications.Notifications]"
} else {
    #
    # Manage own notifications.
    #
    set doc(title) #notifications.Manage_Notifications#

    set user_id [ad_conn user_id]
    set elements {
        type {
            label {[_ notifications.Notification_type]}
        }
        object_name {
            label {[_ notifications.Item]}
            link_url_eval {[export_vars -base object-goto { object_id type_id }]}
            link_html {title "\#notifications.goto_object_name\#"}
        }
        interval {
            label {[_ notifications.Frequency]}
            display_template {
                @notifications.interval@
                (<a href="@notifications.interval_url@" title="\#notifications.change_interval_object_name\#">\#notifications.Change\#</a>)
            }
        }
        action {
            label {[_ notifications.Action]}
            display_template {\#notifications.Unsubscribe\#}
            link_url_eval {[export_vars -base request-delete { request_id {return_url [ad_return_url]} }]}
            link_html {title "\#notifications.Unsubscribe_from_object_name\#"}
        }
    }
}

set return_url [ad_conn url]

db_multirow -extend { interval_url } notifications select_notifications {
     select nr.request_id,
            nr.type_id,
            nt.pretty_name as type,
            acs_object.name(nr.object_id) as object_name,
            ni.name as interval,
            nr.object_id
       from notification_requests nr,
            notification_intervals ni,
            notification_types nt
      where nr.user_id = :user_id
        and nr.interval_id = ni.interval_id
        and nr.type_id = nt.type_id
        and nr.user_id is not null
        and nr.dynamic_p = 'f'
      order by lower(nt.pretty_name), object_name
} {
    set interval_url [export_vars -base request-change-frequency { request_id {return_url [ad_return_url]} }]
    set interval [_ notifications.${interval}]
}



template::list::create \
    -name notifications \
    -no_data [_ notifications.lt_You_have_no_notificat] \
    -elements $elements


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
