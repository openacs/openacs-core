<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_basic_info">      
      <querytext>
      
    select acs_group.name(:group_id) as group_name,
    nvl(acs_rel_type.role_pretty_plural(t.role_two),'Elements') as role_pretty_plural
      from acs_rel_types t
     where t.rel_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>
