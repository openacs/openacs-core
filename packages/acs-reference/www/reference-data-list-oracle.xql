<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="data_select">      
      <querytext>
       
select repository_id,
  table_name,
  internal_data_p,
  package_name,
  to_char(last_update,'MM-DD-YYYY') updated,
  source,
  source_url,
  effective_date,
  expiry_date
from  acs_reference_repositories a
order by table_name

      </querytext>
</fullquery>

 
</queryset>
