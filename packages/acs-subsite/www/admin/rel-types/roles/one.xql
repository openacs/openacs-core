<?xml version="1.0"?>
<queryset>

<fullquery name="select_role_props">      
      <querytext>
      
    select r.pretty_name, r.pretty_plural
      from acs_rel_roles r 
     where r.role = :role

      </querytext>
</fullquery>

 
<fullquery name="select_rel_types_one">      
      <querytext>
      
    select r.rel_type as role, t.pretty_name, r.rel_type,
           case when r.role_one = :role then 'Side one' else 'Side two' end as side
      from acs_object_types t, acs_rel_types r
     where t.object_type = r.rel_type
       and (r.role_one = :role or r.role_two = :role)
     order by side, t.pretty_name

      </querytext>
</fullquery>

 
</queryset>
