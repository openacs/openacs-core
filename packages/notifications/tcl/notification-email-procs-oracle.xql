<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="notification::email::load_qmail_mail_queue.holdinsert">
      <querytext>
        insert into notification_email_hold
        (reply_id,to_addr,headers,body)
        values
        (:reply_id,empty_clob(),empty_clob(),empty_clob())
       returning to_addr, headers, body into :1, :2, :3
      </querytext>
    </fullquery>

</queryset>

