<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="rel_type_info">      
      <querytext>

    select object_type as ancestor_rel_type
      from acs_object_types
     where supertype = 'relationship'
       and object_type in (
               select t2.object_type
		 from acs_object_types t1, acs_object_types t2
		where t1.object_type = :add_with_rel_type
		  and t1.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
           )

      </querytext>
</fullquery>

 
</queryset>
