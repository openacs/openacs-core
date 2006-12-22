<?xml version="1.0"?>
<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>


    <fullquery name="acs_mail_lite::complex_send.create_complex_queue_entry">
        <querytext>
            insert into acs_mail_lite_complex_queue
                  (id,
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
	 	   reply_to,
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
                  (acs_mail_lite_id_seq.nextval,
		   :creation_date,
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
		   :reply_to,
                   :subject,
                   :body,
                   :package_id,
                   :files,
                   :file_ids,
                   :folder_ids,
                   :mime_type,
                   :object_id,
		   decode(:single_email_p,'1','t','f'),
		   decode(:no_callback_p,'1','t','f'),
                   :extraheaders,
		   decode(:alternative_part_p,'1','t','f'),
		   decode(:use_sender_p,'1','t','f')
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
                   decode(single_email_p,'t',1,0) as single_email_p,
                   decode(no_callback_p,'t',1,0) as no_callback_p,
                   extraheaders,
                   decode(alternative_part_p,'t',1,0) as alternative_part_p,
                   decode(use_sender_p,'t',1,0) as use_sender_p
            from acs_mail_lite_complex_queue
            where locking_server = '' or locking_server is NULL
        </querytext>
    </fullquery>             
</queryset>
