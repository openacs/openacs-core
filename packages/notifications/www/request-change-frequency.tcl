ad_page_contract {

    Request a new notification - Ask for more stuff

    @author Tracy Adams (teadams@alum.mit.edu))
    @creation-date 2002-09-03
    @cvs-id $Id$
} {
    request_id:integer,notnull
    return_url
}

set user_id [ad_conn user_id]

# get the notification information

db_1row select_notification_request {}

set page_title "Edit Frequency of $object_name Notification"
set context [list "Edit Frequency"]

set intervals [notification::get_intervals -type_id $type_id]

ad_form -name change_frequency -export {request_id return_url} -form {
    {interval_id:integer(select)   {label "Notification Interval"}
                                   {options $intervals}
                                   {value $interval_id}}
} -on_submit {

    db_dml update_notification_frequency {}

    ad_returnredirect $return_url
    ad_script_abort

}

ad_return_template
