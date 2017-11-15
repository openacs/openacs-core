<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::sync::job::start_get_document.update_doc_start_time">
        <querytext>
            update auth_batch_jobs
            set    doc_start_time = current_timestamp
            where  job_id = :job_id
        </querytext>
    </fullquery>

    <fullquery name="auth::sync::job::end.update_job_end">
        <querytext>

            update auth_batch_jobs
            set    job_end_time = current_timestamp,
                   message = :message
            where  job_id = :job_id

        </querytext>
    </fullquery>    

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

    <fullquery name="auth::sync::purge_jobs.purge_jobs">
        <querytext>
            delete from auth_batch_jobs
            where  job_end_time < current_date - cast(:num_days as integer)
        </querytext>
    </fullquery>    

</queryset>
