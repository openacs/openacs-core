<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="delete.delete_group">      
      <querytext>
      
	  BEGIN 
            -- the acs_group package takes care of segments referred
  	    -- to by rel_constraints.rel_segment. We delete the ones
	    -- references by rel_constraints.required_rel_segment here.

	    for row in (select cons.constraint_id
                          from rel_constraints cons, rel_segments segs
                         where segs.segment_id = cons.required_rel_segment
                           and segs.group_id = :group_id) loop

                rel_segment.del(row.constraint_id);

            end loop;

	    -- delete the actual group
	    ${package_name}.del(:group_id); 
	  END;
        
      </querytext>
</fullquery>

<fullquery name="group::member_p.user_is_member">      
      <querytext>
	  select acs_group.member_p(:user_id,:group_id, :cascade) from dual
      </querytext>
</fullquery>

 
<fullquery name="group::get_rel_types_options.select_rel_types">      
      <querytext>
    select role.pretty_name,
           gr.rel_type
    from   group_rels gr,
           acs_rel_types rt,
           acs_rel_roles role
    where  gr.group_id = :group_id
    and    rt.rel_type = gr.rel_type
    and    role.role = rt.role_two
    and    rt.object_type_two = :object_type
    order  by decode(gr.rel_type, 'membership_rel', 0, 1)||role.pretty_name

      </querytext>
</fullquery>


</queryset>
