<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="select_supertypes">      
      <querytext>

    select lpad('&nbsp;', (level - 1) * 4) || t.pretty_name as name,
           t.object_type
      from acs_object_types t
     where (t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types
				where object_type= 'membership_rel')
	or t.tree_sortkey like (select tree_sortkey || '%' from acs_object_types
				where object_type= 'composition_rel'))

      </querytext>
</fullquery>

 
</queryset>
