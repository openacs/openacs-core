<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="acs_mail_lite::send.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue 
            (message_id, to_addr, from_addr, subject, body, extra_headers, bcc,
             package_id, valid_email_p)
            values
            (acs_mail_lite_id_seq.nextval, :to_addr, :from_addr, :subject, :body,
             :eh_list, :bcc, :package_id, decode(:valid_email_p,'1','t','f'))
        </querytext>
    </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.record_mail_sent">
     <querytext>

       update acs_mail_lite_mail_log
       set last_mail_date = sysdate
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.insert_log_entry">
     <querytext>

       insert into acs_mail_lite_mail_log (party_id, last_mail_date)
       values (:user_id, sysdate)

     </querytext>
   </fullquery>


    <fullquery name="acs_mail_lite::sweeper.get_queued_messages">
        <querytext>
            select message_id,
                   to_addr,
                   from_addr,
                   subject,
                   body,
                   extra_headers,
                   bcc,
                   package_id,
                   decode(valid_email_p,'t',1,0) as valid_email_p
            from acs_mail_lite_queue
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::send_immediately.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue 
            (message_id, to_addr, from_addr, subject, body, extra_headers, bcc,
             package_id, valid_email_p)
            values
            (acs_mail_lite_id_seq.nextval, :to_addr, :from_addr, :subject, :body,
             :extraheaders, :bcc, :package_id, decode(:valid_email_p,'1','t','f'))
        </querytext>
    </fullquery>

</queryset>
