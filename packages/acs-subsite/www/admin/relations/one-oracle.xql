<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="select_rel_info">      
      <querytext>
      
    select r.rel_type, acs_object_type.pretty_name(t.rel_type) as rel_type_pretty_name,
           acs_rel_type.role_pretty_name(t.role_one) as role_one_pretty_name,
           acs_rel_type.role_pretty_name(t.role_two) as role_two_pretty_name,
           t.object_type_two as object_type_two,
           acs_object.name(r.object_id_one) as object_id_one_name,
           r.object_id_one,
           acs_object.name(r.object_id_two) as object_id_two_name,
           r.object_id_two
      from acs_rels r, acs_rel_types t
     where r.rel_id = :rel_id
       and r.rel_type = t.rel_type
      </querytext>
</fullquery>

 
</queryset>
