<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="number_subtypes">      
      <querytext>
      
    select case when exists (select 1 
                               from acs_object_types t
                              where t.supertype = :rel_type) 
                then 1 else 0 end
      from dual

      </querytext>
</fullquery>

 
<fullquery name="select_counts">      
      <querytext>
      
    select (select count(*) from rel_segments where rel_type = :rel_type) as segments,
           (select count(*) from acs_rels where rel_type = :rel_type) as rels
      from dual

      </querytext>
</fullquery>

 
</queryset>
