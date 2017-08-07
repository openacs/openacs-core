<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="pretty_name_unique">      
<querytext>
    select case when exists (select 1 from acs_object_types t where t.pretty_name = :pretty_name)
          then 1 else 0 end
</querytext>
</fullquery>

 
<fullquery name="select_group_supertypes">      
      <querytext>
      select repeat('&nbsp;', (tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey)) * 4) || t2.pretty_name, t2.object_type
         from acs_object_types t1, acs_object_types t2
       where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
         and t1.object_type = 'group'
      </querytext>
</fullquery>

 
</queryset>
