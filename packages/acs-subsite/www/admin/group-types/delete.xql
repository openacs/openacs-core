<?xml version="1.0"?>
<queryset>

<fullquery name="select_pretty_name">      
      <querytext>
      
    select t.pretty_name as group_type_pretty_name
      from acs_object_types t
     where t.object_type = :group_type

      </querytext>
</fullquery>

 
<fullquery name="select_subtypes">      
      <querytext>
      
	select t.object_type as group_type, t.pretty_name
          from acs_object_types t
         where t.supertype = :group_type
    
      </querytext>
</fullquery>

 
<fullquery name="select_rel_types">      
      <querytext>
      
	select rel.rel_type, t.pretty_name
          from acs_rel_types rel, acs_object_types t
         where (rel.object_type_one = :group_type 
                or rel.object_type_two = :group_type)
	   and rel.rel_type = t.object_type
    
      </querytext>
</fullquery>

 
<fullquery name="groups_of_this_type">      
      <querytext>
      
    select count(o.object_id) 
      from acs_objects o
     where o.object_type = :group_type

      </querytext>
</fullquery>

 
<fullquery name="relations_to_this_type">      
      <querytext>
      
    select count(r.rel_id)
      from acs_rels r
     where r.rel_type in (select t.rel_type
                            from acs_rel_types t
                           where t.object_type_one = :group_type
                              or t.object_type_two = :group_type)

      </querytext>
</fullquery>

 
</queryset>
