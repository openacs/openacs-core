<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_supertypes">      
      <querytext>

    select repeat('&nbsp;', (tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey)) * 4) || t2.pretty_name as name,
           t2.object_type
      from acs_object_types t1,
	   acs_object_types t2
     where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
       and t1.object_type in ('membership_rel', 'composition_rel')

      </querytext>
</fullquery>

 
</queryset>
