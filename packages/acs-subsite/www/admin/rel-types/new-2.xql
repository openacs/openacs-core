<?xml version="1.0"?>
<queryset>

<fullquery name="select_object_types">      
      <querytext>
      
    select r.object_type_one as max_object_type_one, 
           r.object_type_two as max_object_type_two,
           t.pretty_name as supertype_pretty_name,
           r.role_one as supertype_role_one, r.role_two as supertype_role_two,
           r.min_n_rels_one as supertype_min_n_rels_one,
           r.max_n_rels_one as supertype_max_n_rels_one,
           r.min_n_rels_two as supertype_min_n_rels_two,
           r.max_n_rels_two as supertype_max_n_rels_two
      from acs_object_types t, acs_rel_types r
     where r.rel_type = :supertype
       and r.rel_type = t.object_type

      </querytext>
</fullquery>

 
<fullquery name="select_roles">      
      <querytext>
      
    select r.pretty_name, r.role
      from acs_rel_roles r
     order by lower(r.role)

      </querytext>
</fullquery>

 
</queryset>
