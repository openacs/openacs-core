<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::delete.delete_notification">
        <querytext>
            select notification__delete(:notification_id)
        </querytext>
    </fullquery>

    <fullquery name="notification::mark_sent.insert_notification_user_map">
        <querytext>
            insert
            into notification_user_map
            (notification_id, user_id, sent_date)
            select :notification_id, :user_id, now()
            from dual where exists (select 1 from notifications
                                    where notification_id = :notification_id)
        </querytext>
    </fullquery>

    <fullquery name="notification::new.update_message">
        <querytext>
                update notifications
                set notif_html = :notif_html,
                notif_text = :notif_text
                where notification_id = :notification_id
        </querytext>
    </fullquery>

</queryset>
