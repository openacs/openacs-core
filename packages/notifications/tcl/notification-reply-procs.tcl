ad_library {

    Notification Replies

    @creation-date 2002-06-02
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::reply {

    ad_proc -public reply_address_domain {} {
        return "openforce.net"
    }

    ad_proc -public reply_address {
        {-object_id:required}
        {-type_id:required}
    } {
        return "notification-$object_id-$type_id@[reply_address_domain]"
    }

    ad_proc -public parse_reply_address {
        {-reply_address:required}
    } {
        This takes a reply address, checks it for consistency, and returns a list of object_id and type_id
    } {
        # Check the format and extract type_id and object_id at the same time
        if {![regexp {^notification-([0-9]*)-([0-9]*)@} $reply_address all object_id type_id]} {
            return ""
        }

        return [list $object_id $type_id]
    }

    ad_proc -public new {
        {-reply_id ""}
        {-object_id:required}
        {-type_id:required}
        {-from_user:required}
        {-subject:required}
        {-content:required}
        {-reply_date ""}
    } {
        create a new reply
    } {
        set extra_vars [ns_set create]
        oacs_util::vars_to_ns_set -ns_set $extra_vars -var_list {reply_id object_id type_id from_user subject content reply_date}
        
        set reply_id [package_instantiate_object -extra_vars $extra_vars notification_reply]
        
        return $reply_id
    }

    ad_proc -public delete {
        {-reply_id:required}
    } {
        delete a reply
    } {
        db_exec_plsql delete_reply {}
    }
    
}
