ad_page_contract {

    Manage notifications for one user

    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 2002-07-22
} {
    {user_id:naturalnum ""}
}

auth::require_login
set doc(title) [_ notifications.Manage_Notifications]
if { $user_id ne "" && $user_id ne [ad_conn user_id] } {
    # we need to verify that they are an admin
    permission::require_permission -object_id [ad_conn package_id] -privilege "admin"
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
    }
    set notice "[acs_community_member_link -user_id $user_id -label [person::name -person_id $user_id]] - [_ notifications.Notifications]"
} else {
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

db_multirow -extend { interval_url } notifications select_notifications {} {
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
