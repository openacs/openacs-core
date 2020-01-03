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

</queryset>
