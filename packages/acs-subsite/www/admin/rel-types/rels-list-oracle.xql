<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="rels_select">      
      <querytext>
      
    select r.rel_id, acs_object.name(r.object_id_one) || ' and ' || acs_object.name(r.object_id_two) as name
      from acs_rels r, acs_object_party_privilege_map perm,
           app_group_distinct_rel_map m
     where perm.object_id = r.rel_id
       and perm.party_id = :user_id
       and perm.privilege = 'read'
       and r.rel_type = :rel_type
       and m.rel_id = r.rel_id
       and m.package_id = :package_id
     order by lower(name)

      </querytext>
</fullquery>

 
</queryset>
