<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="number_subtypes">      
      <querytext>
      
    select case when exists (select 1 
                               from acs_object_types t
                              where t.supertype = :group_type) 
                then 1 else 0 end
      

      </querytext>
</fullquery>

 
<fullquery name="rel_type_exists_p">      
      <querytext>
      
    select case when exists (select 1 
                               from acs_rel_types t
                              where t.object_type_one = :group_type
                                 or t.object_type_two = :group_type)
                then 1 else 0 end
      

      </querytext>
</fullquery>

 
</queryset>
