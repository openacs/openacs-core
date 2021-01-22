<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rels_select">      
      <querytext>
      
    select r.rel_id, acs_object__name(r.object_id_one) || ' and ' || acs_object__name(r.object_id_two) as name
      from acs_rels r, app_group_distinct_rel_map m
     where 
       and r.rel_type = :rel_type
       and m.rel_id = r.rel_id
       and m.package_id = :package_id
       and acs_permission__permission_p(r.rel_id, :user_id, 'read')

     order by lower(acs_object__name(r.object_id_one) || ' and ' || acs_object__name(r.object_id_two))

      </querytext>
</fullquery>

 
</queryset>
