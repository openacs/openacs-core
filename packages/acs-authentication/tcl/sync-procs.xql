<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::sync::entry::get.select_entry">
        <querytext>
            select e.entry_id,
                   to_char(e.entry_time, 'YYYY-MM-DD HH24:MI:SS') as entry_time,
                   e.operation,
                   a.authority_id,
                   a.pretty_name as authority_pretty_name,
                   e.job_id,
                   e.username,
                   e.user_id,
                   e.success_p,
                   e.message,
                   e.element_messages
            from auth_batch_job_entries e,
                 auth_authorities a,
                 auth_batch_jobs j
            where e.entry_id = :entry_id
              and e.job_id = j.job_id
              and j.authority_id = a.authority_id
        </querytext>
    </fullquery>

</queryset>
