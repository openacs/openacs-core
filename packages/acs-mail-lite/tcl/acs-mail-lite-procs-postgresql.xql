<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="acs_mail_lite::send.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue 
            (message_id, to_addr, from_addr, subject, body, extra_headers, bcc, package_id, valid_email_p)
            values
            (nextval('acs_mail_lite_id_seq'), :to_addr, :from_addr, :subject, :body, :eh_list, :bcc, :package_id,
	    (case when :valid_email_p = '1' then TRUE else FALSE end))
        </querytext>
    </fullquery>


   <fullquery name="acs_mail_lite::log_mail_sending.record_mail_sent">
     <querytext>

       update acs_mail_lite_mail_log
       set last_mail_date = current_timestamp
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.insert_log_entry">
     <querytext>

       insert into acs_mail_lite_mail_log (party_id, last_mail_date)
       values (:user_id, current_timestamp)

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
		   (case when valid_email_p = TRUE then 1
		   	else 0
			end) as valid_email_p
            from acs_mail_lite_queue
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::send_immediately.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue 
            (message_id, to_addr, from_addr, subject, body, extra_headers, bcc,
             package_id, valid_email_p)
            values
            (nextval('acs_mail_lite_id_seq'), :to_addr, :from_addr, :subject, :body,
             :extraheaders, :bcc, :package_id, 
	     (case when :valid_email_p = '1' then TRUE
	     	   else FALSE end))
        </querytext>
    </fullquery>

</queryset>
