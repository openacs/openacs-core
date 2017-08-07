ad_library {

    Notification Types

    Notifications are categorized by type. These procs manage the types.
    Notification types are a service contract in order to handle notification replies appropriately
    (handling a forum reply is not the same as handling a calendar reply).

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::type {

    ad_proc -public get_impl_key {
        {-type_id:required}
    } {
	return the service contract implementation key for a given notification type.
    } {
        return [db_string select_impl_key {}]        
    }

    ad_proc -public new {
        {-all_intervals:boolean 0}
        {-all_delivery_methods:boolean 0}
        {-type_id ""}
        {-sc_impl_id:required}
        {-short_name:required}
        {-pretty_name:required}
        {-description ""}
    } {
        create a new notification type. Must provide a service contract implementation ID.
    } {
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {type_id sc_impl_id short_name pretty_name description}

        set type_id [package_instantiate_object -extra_vars $extra_vars notification_type]

        if { $all_intervals_p } {
            db_dml enable_all_intervals {}
        }

        if { $all_delivery_methods_p } {
            db_dml enable_all_delivery_methods {}
        }
        
        return $type_id
    }

    ad_proc -public get_type_id {
        {-short_name:required}
    } {
	return the notification type ID given a short name. Short names are unique but not primary keys.
    } {
        return [util_memoize [list notification::type::get_type_id_not_cached $short_name]]
    }
    
    ad_proc -public get_type_id_not_cached {
        short_name
    } {
	return the notification type ID given a short name. Short names are unique but not primary keys.
    } {
        return [db_string select_type_id {} -default {}]
    }
    
    ad_proc -public delete {
        {-short_name:required}
    } {
	Remove a notification type. This is very rare.
    } {
        set type_id [get_type_id -short_name $short_name]

        db_exec_plsql delete_notification_type {}

        util_memoize_flush [list notification::type::get_type_id_not_cached $short_name]
    }
    
    ad_proc -public get {
        {-short_name:required}
        {-column_array:required}
    } {
	select information about the notification type into the given Tcl Array
    } {
        # Select the data into the upvar'ed array
        upvar $column_array row
        db_1row select_notification_type {} -column_array row
    }
    
    ad_proc -public interval_enable {
        {-type_id:required}
        {-interval_id:required}
    } {
	Intervals must be enabled on a per notification type basis. For example, weekly notifications
	may not be enabled for full forum posts, as that might be too much email (system choice)
	This enables a given interval for a given notification type.
    } {
        # Perform the insert if necessary
        db_dml insert_interval_map {}
    }

    ad_proc -public interval_disable {
        {-type_id:required}
        {-interval_id:required}
    } {
	Intervals must be enabled on a per notification type basis. For example, weekly notifications
	may not be enabled for full forum posts, as that might be too much email (system choice)
	This disables a given interval for a given notification type.	
    } {
        # perform the delete if necessary
        db_dml delete_interval_map {}
    }
    
    ad_proc -public delivery_method_enable {
        {-type_id:required}
        {-delivery_method_id:required}
    } {
	Delivery methods must be enabled on a per notification type basis. For example, full forum posts
	may not be enabled for SMS delivery, as that would be too long.
	This enables a given delivery method for a given notification type.
    } {
        # perform the insert if necessary
        db_dml insert_delivery_method_map {}
    }
    
    ad_proc -public delivery_method_disable {
        {-type_id:required}
        {-delivery_method_id:required}
    } { 
	Delivery methods must be enabled on a per notification type basis. For example, full forum posts
	may not be enabled for SMS delivery, as that would be too long.
	This disables a given delivery method for a given notification type.
    } {
        # perform the delete if necessary
        db_dml delete_delivery_method_map {}
    }

    ad_proc -public process_reply {
        {-type_id:required}
        {-reply_id:required}
    } {
	The wrapper procedure for processing a given reply. This calls down to the service contract
	implementation to specifically handle a reply.
    } {
        # Get the impl key
        set impl_key [get_impl_key -type_id $type_id]

        # Dispatch to the notification type specific reply processing
        set r [acs_sc::invoke -contract NotificationType -operation ProcessReply -call_args [list $reply_id] -impl $impl_key]
    }
    
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
