<?xml version="1.0"?>
<queryset>

<fullquery name="notification::mark_sent.insert_notification_user_map">
<querytext>
insert into notification_user_map
(notification_id, user_id, sent_date) values
(:notification_id, :user_id, sysdate())
</querytext>
</fullquery>

</queryset>
