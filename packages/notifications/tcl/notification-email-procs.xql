<?xml version="1.0"?>
<queryset>

  <fullquery name="notification::email::send.get_person">
    <querytext>
       select first_names, last_name
       from persons
       where person_id = :from_user_id
    </querytext>
  </fullquery>

    <fullquery name="notification::email::load_qmail_mail_queue.holdinsert">
      <querytext>
        insert into notification_email_hold
        (reply_id,to_addr,headers,body)
        values
        (:reply_id,:to_addr,:headers,:body)
      </querytext>
    </fullquery>

</queryset>

