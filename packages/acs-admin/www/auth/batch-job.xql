<?xml version="1.0"?>
<queryset>

<fullquery name="pagination">
      <querytext>
      
    select entry_id
    from   auth_batch_job_entries
    where  job_id = :job_id
    [template::list::filter_where_clauses -and -name batch_actions]
    order  by entry_id
	
      </querytext>
</fullquery>
 
</queryset>
