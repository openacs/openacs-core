<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="acs_subsite_post_instantiation.add_constraint">      
      <querytext>
--      FIX ME PLSQL
--		    BEGIN
                select rel_constraint__new(
			:constraint_name,               -- constraint_name
			:segment_id,                    -- rel_segment
			'two',                          -- rel_side
			rel_segment.get(:supersite_group_id, 'membership_rel'), -- required_rel_segment
			:user_id,                       -- creation_user
			:creation_ip                    -- creation_ip
			);
--		    END;

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


      </querytext>
</fullquery>


</queryset>
