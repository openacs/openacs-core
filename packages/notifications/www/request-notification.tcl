ad_page_contract {

    Subscribe a person or a group to a notification of an object and a type.

    @author Natalia Pérez (nperper@it.uc3m.es)
    @create-date 2005-03-28

} {
  object_id:naturalnum,notnull
  type_id:naturalnum,notnull
  {group_id:naturalnum ""}
}

set package_id [ad_conn package_id]
permission::require_permission -object_id $package_id -privilege create

set title "[_ notifications.Subscribe_notification]"
set context "[_ notifications.Subscribe_notification]"

db_0or1row get_type_object {}
db_0or1row get_name_notification {}

set return_url "request-notification?object_id=$object_id&type_id=$type_id"

form create notify
set intervals [notification::get_intervals -type_id $type_id]
set delivery_methods [notification::get_delivery_methods -type_id $type_id]

#if group_id parameter exists then all users of this community are subscribed if they're not already subscribed
if {$group_id ne ""} {        
    set interval_id [notification::get_interval_id -name instant]
    set delivery_method_id [notification::get_delivery_method_id -name email]
        
    db_foreach get_member_id {} {
        # Add notification for this user if they're not already subscribed for an instant alert        
        if {[notification::request::get_request_id -user_id $user_id -type_id $type_id -object_id $object_id] eq ""} {
            notification::request::new -type_id $type_id -user_id $user_id -object_id $object_id -interval_id $interval_id \
                -delivery_method_id $delivery_method_id
        }        
    }            
}


element create notify type_id\
    -widget hidden\
    -value $type_id
element create notify object_id\
    -widget hidden\
    -value $object_id
element create notify party_id \
    -widget party_search \
    -datatype party_search \
    -label "[_ notifications.User]"
element create notify interval_id\
    -widget select\
    -datatype text\
    -label  "[_ notifications.lt_Notification_Interval]"\
    -options $intervals
element create notify delivery_method_id\
    -datatype integer \
    -widget select\
    -label  "[_ notifications.Delivery_Method]"\
    -options $delivery_methods\
    -value [lindex $delivery_methods 0 1]


set username ""        
if {[template::form is_valid notify]} {
    template::form get_values notify party_id interval_id type_id delivery_method_id
    
    db_foreach get_user {} {
        if {[notification::request::get_request_id -user_id $user_id -type_id $type_id -object_id $object_id] eq ""} {
                notification::request::new -type_id $type_id -user_id $user_id -object_id $object_id -interval_id $interval_id \
                -delivery_method_id $delivery_method_id
            }
    }
        
    #if party_id is a group of users then returnredirect, else we get an error
    db_0or1row get_user_name {}
    if {$username eq ""} {
        ad_returnredirect $return_url
    }
    
    
    # Add the subscribe
    notification::request::new \
            -type_id $type_id \
            -user_id $party_id \
            -object_id $object_id \
            -interval_id $interval_id \
            -delivery_method_id $delivery_method_id


    ad_returnredirect $return_url
}

#delete subscribed users
template::list::create \
    -name notify_users\
    -multirow notify_users\
    -key request_id\
    -bulk_actions\
    {
        "\#notifications.Unsubscribe\#" "unsubscribe" "\#notifications.unsubscribe_user\#"	
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
	    label "[_ notifications.Subscribed_User_ID]"
	}
	interval_name {
	    label "[_ notifications.lt_Notification_Interval]"
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
