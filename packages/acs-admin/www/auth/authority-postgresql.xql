<?xml version="1.0"?>
<queryset>
<rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_batch_jobs">
      <querytext>
      
        select job_id,
               to_char(job_start_time, 'YYYY-MM-DD HH24:MI:SS') as start_time_ansi,
               to_char(job_end_time, 'YYYY-MM-DD HH24:MI:SS') as end_time_ansi,
               snapshot_p,
               (select count(e1.entry_id)
                from   auth_batch_job_entries e1
                where  e1.job_id = auth_batch_jobs.job_id) as num_actions,
                (select count(e2.entry_id)
                 from   auth_batch_job_entries e2
                 where  e2.job_id = auth_batch_jobs.job_id
                 and    e2.success_p = 'f') as num_problems,
               interactive_p,
               message,
               trunc(extract(epoch from (coalesce(job_end_time, current_timestamp) - job_start_time))) as run_time_seconds
        from   auth_batch_jobs
        where  authority_id = :authority_id
		order by start_time_ansi
      </querytext>
</fullquery>

 
</queryset>
