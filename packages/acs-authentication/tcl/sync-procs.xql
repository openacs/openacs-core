<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::sync::entry::get.select_entry">
        <querytext>
            select entry_id,
                   to_char(entry_time, 'YYYY-MM-DD HH24:MI:SS') as entry_time,
                   operation,
                   authority_id,
                   (select aa.pretty_name 
                    from auth_authorities aa 
                    where aa.authority_id = auth_batch_job_entries.authority_id
                   ) as authority_pretty_name,
                   job_id,
                   username,
                   user_id,
                   success_p,
                   message,
                   element_messages
            from auth_batch_job_entries
            where entry_id = :entry_id
        </querytext>
    </fullquery>

</queryset>
