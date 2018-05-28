<?xml version="1.0"?>
<queryset>

    <fullquery name="notification::email::load_qmail_mail_queue.holdinsert">
      <querytext>
        insert into notification_email_hold
        (reply_id,to_addr,headers,body)
        values
        (:reply_id,:to_addr,:headers,:body)
      </querytext>
    </fullquery>

</queryset>

