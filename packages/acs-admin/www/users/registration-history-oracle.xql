<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="user_rows">      
      <querytext>
      select to_char(creation_date,'YYYYMM') as sort_key, rtrim(to_char(creation_date,'Month')) as pretty_month, to_char(creation_date,'YYYY') as pretty_year, count(*) as n_new
from users, acs_objects
where users.user_id = acs_objects.object_id
and creation_date is not null
group by to_char(creation_date,'YYYYMM'), to_char(creation_date,'Month'), to_char(creation_date,'YYYY')
order by 1
      </querytext>
</fullquery>

 
</queryset>
