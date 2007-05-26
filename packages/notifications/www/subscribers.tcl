ad_page_contract {

    Manage notifications for one user

    @author Tracy Adams (teadams@alum.mit.edu)
    @creation-date 2002-07-22
    @cvs-id $Id$
} {
    object_id:notnull
}

permission::require_permission -object_id $object_id -privilege "admin"

# first we verify that this object receives notifications
if { ![db_0or1row select_name { select acs_object__name(object_id) as name, type_id from notification_requests where dynamic_p = 'f' and object_id = :object_id order by type_id limit 1 }] } {
    # there are no notifications for this object
    ad_return_error "No Notifications" "This object does have anybody subscribed via notifications"
}

# the link to the object picks up the first type_id it gets
# if objects have multiple types we may need to separate them
# with different links to their respective objects.

set notice "<a href=\"[export_vars -base object-goto -url {object_id type_id}]\">$name</a> - [_ notifications.Notifications]"



set return_url [ad_conn url]
set package_admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege "admin"]

db_multirow -extend {subscriber_url subscriber_name } notifications select_notifications {
     select nr.user_id,
            ni.name as interval,
            nt.pretty_name as type
       from notification_requests nr,
            notification_intervals ni,
            notification_types nt,
            persons p
      where nr.object_id = :object_id
        and nr.interval_id = ni.interval_id
        and nr.type_id = nt.type_id
        and nr.user_id = p.person_id 
        and nr.dynamic_p = 'f'
      order by lower(p.last_name), lower(p.first_names)
} {
    set subscriber_name [contact::name -party_id $user_id]
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
        
