<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_basic_info">      
      <querytext>
      
    select acs_group__name(:group_id) as group_name,
    coalesce(acs_rel_type__role_pretty_plural(t.role_two),'Elements') as role_pretty_plural
      from acs_rel_types t
     where t.rel_type = :rel_type

      </querytext>
</fullquery>

 
</queryset>
