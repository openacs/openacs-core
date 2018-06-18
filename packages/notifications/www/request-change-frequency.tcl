ad_page_contract {

    Request a new notification - Ask for more stuff

    @author Tracy Adams (teadams@alum.mit.edu))
    @creation-date 2002-09-03
    @cvs-id $Id$
} {
    request_id:naturalnum,notnull
    return_url:localurl
}

set user_id [ad_conn user_id]

# get the notification information

db_1row select_notification_request {
    select type_id, interval_id, object_id
    from notification_requests
    where request_id = :request_id    
}

set object_name [acs_object_name $object_id]

set doc(title) [_ notifications.Change_frequency]
set context [list $doc(title)]

set intervals [notification::get_intervals -localized -type_id $type_id]

ad_form -name change_frequency -export {request_id return_url} -form {
    {interval_id:integer(select)   
        {label "[_ notifications.Frequency]"}
        {options $intervals}
        {value $interval_id}}
} -on_submit {

    db_dml update_notification_frequency {
        update notification_requests
        set interval_id = :interval_id
        where request_id = :request_id        
    }

    ad_returnredirect $return_url
    ad_script_abort

}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
