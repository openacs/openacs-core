<?xml version="1.0"?>

<queryset>

<fullquery name="notification::reply::sweep::scan_all_replies.select_deliv_methods">
<querytext>
select delivery_method_id from notification_delivery_methods
</querytext>
</fullquery>

<fullquery name="notification::reply::sweep::process_all_replies.select_replies">
<querytext>
select reply_id, type_id from notification_replies order by reply_date
</querytext>
</fullquery>

<fullquery name="notification::reply::sweep::process_all_replies.deletehold">
  <querytext>
    delete from notification_email_hold
    where reply_id = :reply_id
  </querytext>
</fullquery>

</queryset>
