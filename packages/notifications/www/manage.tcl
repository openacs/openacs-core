ad_page_contract {

    Manage notifications for one user

    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 2002-07-22
    @cvs-id $Id$
} {}

auth::require_login
set user_id [ad_conn user_id]
set return_url [ad_conn url]

db_multirow -extend { interval_url } notifications select_notifications {} {
    set interval_url [export_vars -base request-change-frequency { request_id {return_url [ad_return_url]} }]
}

template::list::create \
    -name notifications \
    -no_data [_ notifications.lt_You_have_no_notificat] \
    -elements {
        type {
            label {[_ notifications.Notification_type]}
        }
        object_name {
            label {[_ notifications.Item]}
            link_url_eval {[export_vars -base object-goto { object_id type_id }]}
        }
        interval {
            label {[_ notifications.Frequency]}
            display_template {
                @notifications.interval@ 
                (<a href="@notifications.interval_url@">\#notifications.Change\#</a>)
            }
        }
        action {
            label {[_ notifications.Action]}
            display_template {\#notifications.Unsubscribe\#}
            link_url_eval {[export_vars -base request-delete { request_id {return_url [ad_return_url]} }]}
        }
    }
