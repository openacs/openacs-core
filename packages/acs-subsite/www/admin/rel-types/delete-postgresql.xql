<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="number_subtypes">      
      <querytext>
      
    select case when exists (select 1 
                               from acs_object_types t
                              where t.supertype = :rel_type) 
                then 1 else 0 end
      

      </querytext>
</fullquery>

 
<fullquery name="select_counts">      
      <querytext>
      
    select (select count(*) from rel_segments where rel_type = :rel_type) as segments,
           (select count(*) from acs_rels where rel_type = :rel_type) as rels
      

      </querytext>
</fullquery>

 
</queryset>
