<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_rel_type_properties">      
      <querytext>
      
    select t1.pretty_name as object_type_one_pretty_name, 
           r.object_type_one, acs_rel_type.role_pretty_name(r.role_one) as role_one_pretty_name, 
           r.role_one, r.min_n_rels_one, r.max_n_rels_one,
           t2.pretty_name as object_type_two_pretty_name, 
           r.object_type_two, acs_rel_type.role_pretty_name(r.role_two) as role_two_pretty_name, 
           r.role_two, r.min_n_rels_two, r.max_n_rels_two
      from acs_rel_types r, acs_object_types t1, acs_object_types t2
     where r.rel_type = :rel_type
       and r.object_type_one = t1.object_type
       and r.object_type_two = t2.object_type

      </querytext>
</fullquery>

 
<fullquery name="rels_select">      
      <querytext>
      
    select inner.* 
      from (select r.rel_id, acs_object.name(r.object_id_one) || ' and ' || acs_object.name(r.object_id_two) as name
              from acs_rels r, acs_object_party_privilege_map perm,
                   app_group_distinct_rel_map m
             where perm.object_id = r.rel_id
               and perm.party_id = :user_id
               and perm.privilege = 'read'
               and r.rel_type = :rel_type
               and m.rel_id = r.rel_id
               and m.package_id = :package_id
             order by lower(acs_object.name(r.object_id_one)), lower(acs_object.name(r.object_id_two))) inner
    where rownum <= 26

      </querytext>
</fullquery>

 
</queryset>
