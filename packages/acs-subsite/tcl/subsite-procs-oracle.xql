<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="acs_subsite_post_instantiation.add_constraint">      
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

 
<fullquery name="acs_subsite_post_instantiation.sub_type_exists_p">      
      <querytext>
      
	select case 
                 when exists (select 1 from acs_object_types 
                              where supertype = :object_type)
                 then 1 
                 else 0 
               end
        from dual
    
      </querytext>
</fullquery>

 
</queryset>
