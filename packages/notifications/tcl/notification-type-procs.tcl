ad_library {

    Notification Types

    @creation-date 2002-05-24
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::type {

    ad_proc -public get_impl_key {
        {-type_id:required}
    } {
        return [db_string select_impl_key {}]        
    }

    ad_proc -public new {
        {-type_id ""}
        {-sc_impl_id:required}
        {-short_name:required}
        {-pretty_name:required}
        {-description ""}
    } {
        create a new notification type
    } {
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {type_id sc_impl_id short_name pretty_name description}

        set type_id [package_instantiate_object -extra_vars $extra_vars notification_type]

        return $type_id
    }

    ad_proc -public get_type_id {
        {-short_name:required}
    } {
        return [db_string select_type_id {} -default {}]
    }
    
    ad_proc -public delete {
        {-short_name:required}
    } {
        set type_id [get_type_id -short_name $short_name]
        
        # do the delete
        # FIXME: implement
    }
    
    ad_proc -public get {
        {-short_name:required}
        {-column_array:required}
    } {
        # Select the data into the upvar'ed array
        upvar $column_array row
        db_1row select_notification_type {} -column_array row
    }
    
    ad_proc -public interval_enable {
        {-type_id:required}
        {-interval_id:required}
    } {
        # Perform the insert if necessary
        db_dml insert_interval_map {}
    }

    ad_proc -public interval_disable {
        {-type_id:required}
        {-interval_id:required}
    } {
        # perform the delete if necessary
        db_dml delete_interval_map {}
    }
    
    ad_proc -public delivery_method_enable {
        {-type_id:required}
        {-delivery_method_id:required}
    } {
        # perform the insert if necessary
        db_dml insert_delivery_method_map {}
    }
    
    ad_proc -public delivery_method_disable {
        {-type_id:required}
        {-delivery_method_id:required}
    } { 
        # perform the delete if necessary
        db_dml delete_delivery_method_map {}
    }

    ad_proc -public process_reply {
        {-type_id:required}
        {-reply_id:required}
    } {
        # Get the impl key
        set impl_key [get_impl_key -type_id $type_id]

        # Dispatch to the notification type specific reply processing
        acs_sc_call NotificationType ProcessReply [list $reply_id] $impl_key
    }
    
}
