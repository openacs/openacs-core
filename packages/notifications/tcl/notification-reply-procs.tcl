ad_library {

    Notification Replies

    @creation-date 2002-06-02
    @author Ben Adida <ben@openforce.biz>
    @cvs-id $Id$

}

namespace eval notification::reply {

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

    ad_proc -public get {
        {-reply_id:required}
        {-array:required}
    } {
        Get the information for the reply
    } {
        # Select the info into the upvar'ed Tcl Array
        upvar $array row
        db_1row select_reply {} -column_array row
    }

    ad_proc -public delete {
        {-reply_id:required}
    } {
        delete a reply
    } {
        db_exec_plsql delete_reply {}
    }
    
}
