<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="notification::delete.delete_notification">
        <querytext>
            select notification__delete(:notification_id)
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
