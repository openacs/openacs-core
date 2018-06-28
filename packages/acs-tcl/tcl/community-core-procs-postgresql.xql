<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_user::delete.permanent_delete">
      <querytext>
          select acs__remove_user(:user_id);
      </querytext>
</fullquery>

<fullquery name="person::delete.delete_person">      
      <querytext>

            select person__delete(:person_id);
        
      </querytext>
</fullquery>

<fullquery name="acs_user::create_portrait.create_rel">
  <querytext>

    select acs_rel__new (
    null,
    'user_portrait_rel',
    :user_id,
    :item_id,
    null,
    null,
    null
    )

  </querytext>
</fullquery>

<partialquery name="party::types_valid_for_rel_type_multirow.start_with_clause_party">
  <querytext>
    (t1.object_type = 'group' or t1.object_type = 'person')
  </querytext>
</partialquery>	      

<partialquery name="party::types_valid_for_rel_type_multirow.start_with_clause">
  <querytext>
    t1.object_type = :start_with
  </querytext>
</partialquery>	      

<fullquery name="party::types_valid_for_rel_type_multirow.select_sub_rel_types">      
  <querytext>

	select types.pretty_name, 
	       types.object_type, 
	       types.tree_level, 
	       types.indent,
	       case when valid_types.object_type = null then 0 else 1 end as valid_p
	  from (select t2.pretty_name,
		       t2.object_type,
		       tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey) as tree_level,
		       repeat('&nbsp;', (tree_level(t2.tree_sortkey) - tree_level(t1.tree_sortkey)) * 4) as indent,
		       t2.tree_sortkey
		  from acs_object_types t1,
		       acs_object_types t2
		 where t2.tree_sortkey between t1.tree_sortkey and tree_right(t1.tree_sortkey)
	           and $start_with_clause ) types
                  left outer join
	            (select object_type 
		       from rel_types_valid_obj_two_types
		      where rel_type = :rel_type ) valid_types
		    using (object_type)
         order by types.tree_sortkey
	
  </querytext>
</fullquery>

</queryset>
