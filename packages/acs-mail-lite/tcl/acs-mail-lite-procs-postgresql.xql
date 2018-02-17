<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

    <fullquery name="acs_mail_lite::send.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue
                  (message_id, 
                   creation_date,
                   locking_server,
                   to_addr,
                   cc_addr,
                   bcc_addr,
                   from_addr,
                   reply_to,
                   subject,
                   body,
                   package_id,
                   file_ids,
                   filesystem_files,
                   delete_filesystem_files_p,
                   mime_type,
                   no_callback_p,
                   extraheaders,
                   use_sender_p,
                   object_id
                  )
            values
                  (nextval('acs_mail_lite_id_seq'),
                   :creation_date,
                   :locking_server,
                   :to_addr,
                   :cc_addr,
                   :bcc_addr,
                   :from_addr,
                   :reply_to,
                   :subject,
                   :body,
                   :package_id,
                   :file_ids,
                   :filesystem_files,
                   (case when :delete_filesystem_files_p = '1' then TRUE else FALSE end),
                   :mime_type,
                   (case when :no_callback_p = '1' then TRUE else FALSE end),
                   :extraheaders,
                   (case when :use_sender_p = '1' then TRUE else FALSE end),
                   :object_id
                  )
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
            select
                   message_id as id,
                   creation_date,
                   locking_server,
                   to_addr,
                   cc_addr,
                   bcc_addr,
                   from_addr,
                   reply_to,
                   subject,
                   body,
                   package_id,
                   file_ids,
                   (case when delete_filesystem_files_p = TRUE then 1 else 0 end) as delete_filesystem_files_p,
		   filesystem_files,
                   mime_type,
                   (case when no_callback_p = TRUE then 1 else 0 end) as no_callback_p,
                   extraheaders,
                   (case when use_sender_p = TRUE then 1 else 0 end) as use_sender_p,
                   object_id
            from acs_mail_lite_queue
            where locking_server = '' or locking_server is NULL
        </querytext>
    </fullquery>

</queryset>
