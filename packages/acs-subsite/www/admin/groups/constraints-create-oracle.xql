<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_props">      
      <querytext>
      
    select acs_group.name(:group_id) as group_name,
           t.pretty_name as rel_type_pretty_name
      from acs_object_types t
     where t.object_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>
