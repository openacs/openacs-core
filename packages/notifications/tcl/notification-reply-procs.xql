<?xml version="1.0"?>

<queryset>

<fullquery name="notification::reply::get.select_reply">
<querytext>
select reply_id, object_id, type_id, from_user, subject, content, reply_date
from notification_replies
where reply_id= :reply_id
</querytext>
</fullquery>

</queryset>
