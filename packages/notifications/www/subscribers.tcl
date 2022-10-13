ad_page_contract {

    List notification subscribers to an object

    Malte actually wrote this but I had to rewrite it due to his calling the contacts
    package and using inline, PG-specific queries.

    @author dhogaza@pacifier.com
    @creation-date 2008-01-13
    @cvs-id $Id$
} {
    object_id:naturalnum,notnull
}

permission::require_permission -object_id $object_id -privilege "admin"

# first we verify that this object receives notifications
if { ![db_0or1row select_name {
    select acs_object.name(object_id) as name, type_id
    from notification_requests
    where dynamic_p = 'f'
      and object_id = :object_id
    order by type_id
    fetch first 1 rows only
}] } {
    # there are no notifications for this object
    ad_return_exception_page 200 [_ notifications.No_Notifications] [_ notifications.No_Notifications_text]
    ad_script_abort
}

# the link to the object picks up the first type_id it gets
# if objects have multiple types we may need to separate them
# with different links to their respective objects.

set url [export_vars -base object-goto -url {object_id type_id}]
set notice "<a href=\"[ns_quotehtml $url]\">$name</a> - [_ notifications.Notifications]"



set return_url [ad_conn url]
set package_admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"]

db_multirow -extend {subscriber_url subscriber_name } notifications select_notifications {} {
    set subscriber_name [person::name -person_id $user_id]
    if { [string is true $package_admin_p] } {
        set subscriber_url [export_vars -base "manage" -url {user_id}]
    } else {
        set subscriber_url [acs_community_member_url -user_id $user_id]
    }
}

template::list::create \
    -name notifications \
    -no_data [_ notifications.lt_You_have_no_notificat] \
    -elements {
        subscriber_name {
            label {[_ notifications.Subscriber] }
            link_url_eval $subscriber_url
        }
        type {
            label {[_ notifications.Notification_type]}
        }
        interval {
            label {[_ notifications.Frequency]}
        }
    }

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
