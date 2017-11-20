<?xml version="1.0"?>

<queryset>
    <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

    <fullquery name="acs_mail_lite::send.create_queue_entry">
        <querytext>
            insert into acs_mail_lite_queue
                  (message_id,
                   creation_date,
                   locking_server,
                   to_addr,
                   from_addr,
                   reply_to,
                   subject,
                   package_id,
                   file_ids,
		   filesystem_files,
		   delete_filesystem_files_p,
                   mime_type,
                   no_callback_p,
                   use_sender_p,
                   cc_addr,
                   bcc_addr,
                   body,
                   extraheaders,
                   object_id
                  )
            values
                  (acs_mail_lite_id_seq.nextval,
                   :creation_date,
                   :locking_server,
                   :to_addr,
                   :from_addr,
                   :reply_to,
                   :subject,
                   :package_id,
                   :file_ids,
                   :filesystem_files,
                   decode(:delete_filesystem_files_p,'1','t','f'),,
                   :mime_type,
                   decode(:no_callback_p,'1','t','f'),
                   decode(:use_sender_p,'1','t','f'),
                   :cc_addr,
                   :bcc_addr,
                   :body,
                   :extraheaders,
                   :object_id
                  )
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
		   filesystem_files,
		   delete_filesystem_files_p,
                   mime_type,
                   decode(no_callback_p,'t',1,0) as no_callback_p,
                   extraheaders,
                   decode(use_sender_p,'t',1,0) as use_sender_p,
                   object_id
            from acs_mail_lite_queue
            where locking_server = '' or locking_server is NULL
        </querytext>
    </fullquery>

</queryset>
