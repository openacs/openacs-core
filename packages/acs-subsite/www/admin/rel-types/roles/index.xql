<?xml version="1.0"?>
<queryset>

<fullquery name="select_roles">      
      <querytext>
    select r.role, r.pretty_name, coalesce(num1.number_rels,0) + coalesce(num2.number_rels,0) as number_rel_types
      from acs_rel_roles r left join
	(select t.role_one as role, count(*) as number_rels
             from acs_rel_types t
            group by t.role_one) num1 on r.role=num1.role left join
           (select t.role_two as role, count(*) as number_rels
             from acs_rel_types t
            group by t.role_two) num2 on r.role=num2.role
     order by lower(r.role)

      </querytext>
</fullquery>

 
</queryset>
