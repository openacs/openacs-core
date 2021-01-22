ad_page_contract {
    
    Unsubscribe users.    

    @author Natalia Pérez (nperper@it.uc3m.es)
    @create-date 2005-03-28
    
} {
    object_id:naturalnum,notnull
    type_id:naturalnum,notnull
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set title "[_ notifications.Unsubscribe_Notifications]"

set context "[_ notifications.Unsubscribe_Notifications]"

db_0or1row get_name_notification {}
set return_url "request-unsubscribe-notification?object_id=$object_id&type_id=$type_id"

#get all users subscribed to notification of type_id
template::list::create -name notify_users\
-multirow notify_users\
-key request_id\
-bulk_actions\
    {
        "\#notifications.unsubscribe\#" "unsubscribe" "\#notifications.unsubscribe_user\#"
    }\
    -bulk_action_method post -bulk_action_export_vars {
        object_id
	type_id
	return_url
    }\
    -no_data "\#notifications.there_are_no_users\#"\
    -row_pretty_plural "notify_users"\
    -elements {
        name {
	    label "[_ notifications.User]"
	}
	interval_name {
	    label "[_ notifications.lt_Notifications_Interval]"
	}
	delivery_name {
	    label "[_ notifications.Delivery_Method]"
	}
    }
    
    db_multirow notify_users notify_users {}
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
