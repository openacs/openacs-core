<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="subsite::default::create_app_group.add_constraint">      
      <querytext>

	select rel_constraint__new(
	  null,
	  'rel_constraint',
	  :constraint_name,
	  :segment_id,
	  'two',
	  rel_segment__get(:supersite_group_id, 'membership_rel'),
	  null,
	  :user_id,
	  :creation_ip
	);
		
      </querytext>
</fullquery>

<fullquery name="subsite::util::object_type_path_list.select_object_type_path">      
      <querytext>

	select t2.object_type
	  from acs_object_types t1, acs_object_types t2
	 where t1.object_type = :object_type
	   and t1.tree_sortkey between t2.tree_sortkey and tree_right(t2.tree_sortkey)
	 order by t2.tree_sortkey desc
    
      </querytext>
</fullquery>

</queryset>
