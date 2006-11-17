<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

   <fullquery name="acs_mail_lite::check_bounces.send_notification_to_bouncing_email">
     <querytext>

       insert into acs_mail_lite_bounce_notif (user_id, notification_count, notification_time)
       select party_id, 0 as notification_count,
           date_trunc('day', current_timestamp - to_interval(1 + :notification_interval, 'days'))
           as notification_time
        from acs_mail_lite_bounce
        where bounce_count >= :max_bounce_count

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.get_recent_bouncing_users">
     <querytext>

       select u.user_id, u.email, u.first_names || ' ' || u.last_name as name
       from cc_users u, acs_mail_lite_bounce_notif n
       where u.user_id = n.user_id
       and u.email_bouncing_p = 't'
       and n.notification_time < current_timestamp - to_interval(:notification_interval, 'days')
       and n.notification_count < :max_notification_count

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.log_notication_sending">
     <querytext>

       update acs_mail_lite_bounce_notif
       set notification_time = date_trunc('day',current_timestamp),
           notification_count = notification_count + 1
       where user_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.delete_log_if_no_recent_bounce">
     <querytext>

       delete from acs_mail_lite_bounce
       where party_id in (select party_id
                         from acs_mail_lite_mail_log
                         where last_mail_date < current_timestamp - to_interval(:max_days_to_bounce, 'days'))

     </querytext>
   </fullquery>


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

    <fullquery name="acs_mail_lite::complex_send.create_complex_queue_entry">
        <querytext>
            insert into acs_mail_lite_complex_queue
                  (creation_date,
                   locking_server,
                   to_party_ids,	
                   cc_party_ids,
                   bcc_party_ids,
                   to_group_ids,
                   cc_group_ids,
                   bcc_group_ids,
                   to_addr,
                   cc_addr,
                   bcc_addr,
                   from_addr,
                   subject,
                   body,
                   package_id,
                   files,
                   file_ids,
                   folder_ids,
                   mime_type,
                   object_id,
                   single_email_p,
                   no_callback_p,
                   extraheaders,
                   alternative_part_p,
                   use_sender_p     
                  )
            values
                  (:creation_date,
                   :locking_server,
                   :to_party_ids,
                   :cc_party_ids,
                   :bcc_party_ids,
                   :to_group_ids,
                   :cc_group_ids,
                   :bcc_group_ids,
                   :to_addr,
                   :cc_addr,
                   :bcc_addr,
                   :from_addr,
                   :subject,
                   :body,
                   :package_id,
                   :files,
                   :file_ids,
                   :folder_ids,
                   :mime_type,
                   :object_id,
                   (case when :single_email_p = '1' then TRUE else FALSE end),
                   (case when :no_callback_p = '1' then TRUE else FALSE end),
                   :extraheaders,
                   (case when :alternative_part_p = '1' then TRUE else FALSE end),
                   (case when :use_sender_p = '1' then TRUE else FALSE end)          
                  )
        </querytext>
    </fullquery>       

    <fullquery name="acs_mail_lite::complex_sweeper.get_complex_queued_messages">
        <querytext>
            select
                   id,
                   creation_date,
                   locking_server,
                   to_party_ids,
                   cc_party_ids,
                   bcc_party_ids,
                   to_group_ids,
                   cc_group_ids,
                   bcc_group_ids,
                   to_addr,
                   cc_addr,
                   bcc_addr,
                   from_addr,
                   subject,
                   body,
                   package_id,
                   files,
                   file_ids,
                   folder_ids,
                   mime_type,
                   object_id,
                   (case when single_email_p = TRUE then 1 else 0 end) as single_email_p,
                   (case when no_callback_p = TRUE then 1 else 0 end) as no_callback_p,
                   extraheaders,
                   (case when alternative_part_p = TRUE then 1 else 0 end) as alternative_part_p,
                   (case when use_sender_p = TRUE then 1 else 0 end) as use_sender_p
            from acs_mail_lite_complex_queue
            where locking_server = '' or locking_server is NULL
        </querytext>
    </fullquery>             

    <fullquery name="acs_mail_lite::complex_sweeper.get_complex_queued_message">
        <querytext>
            select id
            from acs_mail_lite_complex_queue
            where id=:id and (locking_server = '' or locking_server is NULL)
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::complex_sweeper.lock_queued_message">
        <querytext>
            update acs_mail_lite_complex_queue
               set locking_server = :locking_server
            where id=:id
        </querytext>
    </fullquery> 

    <fullquery name="acs_mail_lite::complex_sweeper.delete_complex_queue_entry">
        <querytext>
            delete from acs_mail_lite_complex_queue
            where id=:id
        </querytext>
    </fullquery>        

</queryset>
