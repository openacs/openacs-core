<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_props">      
      <querytext>
      
    select acs_group__name(:group_id) as group_name,
           t.pretty_name as rel_type_pretty_name
      from acs_object_types t
     where t.object_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>
