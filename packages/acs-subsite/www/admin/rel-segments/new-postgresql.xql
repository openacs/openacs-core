<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_relation_types">      
      <querytext>
    select t2.pretty_name, t2.object_type as rel_type,
	   repeat('&nbsp;', (tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey)) * 4) as indent
      from acs_object_types t1,
	   acs_object_types t2,
           rel_segments s
     where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
       and t1.object_type in ('membership_rel', 'composition_rel')
       and t2.object_type <> s.rel_type
       and s.group_id = :group_id
    order by lower(t2.pretty_name) desc

      </querytext>
</fullquery>

 
<fullquery name="select_basic_info">      
      <querytext>
      
    select acs_group__name(:group_id) as group_name
      

      </querytext>
</fullquery>

 
</queryset>
