<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_relation_types">      
      <querytext>
    select t.pretty_name, t.object_type as rel_type,
    lpad('&nbsp;', (level - 1) * 4) as indent
    from acs_object_types t
    where t.object_type not in (select s.rel_type from rel_segments s where s.group_id = :group_id)
    and (t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types where object_type='membership_rel') or
	t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types where object_type='composition_rel'))
    order by lower(t.pretty_name) desc

      </querytext>
</fullquery>

 
<fullquery name="select_basic_info">      
      <querytext>
      
    select acs_group__name(:group_id) as group_name
      

      </querytext>
</fullquery>

 
</queryset>
