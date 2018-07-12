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

acs_object::get -object_id $object_id -array obj
set object_name   $obj(object_name)
set creation_date $obj(creation_date_ansi)

set doc(title) [_ notifications.Change_frequency_of_object_name]
set context [list [_ notifications.Change_frequency]]

set intervals [notification::get_intervals -localized -type_id $type_id]

set object_name [lang::util::localize $object_name]
set creation_date [lc_time_fmt $creation_date "%d.%m.%Y %T"]

ad_form -name change_frequency -export {request_id return_url} -form {
    {object_name:text(text)
        {label "#notifications.Item#"}
        {mode "display"}
        {value $object_name}
    }
    {creation_date:text(text)
        {label "#acs-admin.Creation_date#"}
        {mode "display"}
        {value $creation_date}
    }
    {interval_id:integer(select)
        {label "#notifications.Frequency#"}
        {options $intervals}
        {value $interval_id}
    }
} -on_submit {

    db_dml update_notification_frequency {
        update notification_requests
        set interval_id = :interval_id
        where request_id = :request_id
    }

    ad_returnredirect $return_url
    ad_script_abort

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
