<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="subsite::default::create_app_group.add_constraint">      
      <querytext>
      
		    BEGIN
			:1 := rel_constraint.new(
			constraint_name => :constraint_name,
			rel_segment => :segment_id,
			rel_side => 'two',
			required_rel_segment => rel_segment.get(:supersite_group_id, 'membership_rel'),
			creation_user => :user_id,
			creation_ip => :creation_ip
			);
		    END;
		
      </querytext>
</fullquery>

<fullquery name="subsite::util::object_type_path_list.select_object_type_path">      
      <querytext>
      
	select object_type
	from acs_object_types
	start with object_type = :object_type
	connect by object_type = prior supertype
    
      </querytext>
</fullquery>

</queryset>
