<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_roles">      
      <querytext>
      
    select r.role, r.pretty_name, nvl(num1.number_rels,0) + nvl(num2.number_rels,0) as number_rel_types
      from (select t.role_one as role, count(*) as number_rels
             from acs_rel_types t
            group by t.role_one) num1,
           (select t.role_two as role, count(*) as number_rels
             from acs_rel_types t
            group by t.role_two) num2,
           acs_rel_roles r
     where r.role = num1.role(+)
       and r.role = num2.role(+)
     order by lower(r.role)

      </querytext>
</fullquery>

 
</queryset>
