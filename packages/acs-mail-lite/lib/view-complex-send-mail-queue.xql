<?xml version="1.0"?>

<queryset>
    <fullquery name="get_all_complex_queued_messages">
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
            order by creation_date
        </querytext>
    </fullquery>             
</queryset>
