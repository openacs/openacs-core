<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="group::delete.delete_group">      
      <querytext>
	  DECLARE
	    row record;
	  BEGIN 
            -- the acs_group package takes care of segments referred
  	    -- to by rel_constraints.rel_segment. We delete the ones
	    -- references by rel_constraints.required_rel_segment here.

	    for row in select cons.constraint_id
                          from rel_constraints cons, rel_segments segs
                         where segs.segment_id = cons.required_rel_segment
                           and segs.group_id = :group_id loop

                perform rel_segment__delete(row.constraint_id);

            end loop;

	    -- delete the actual group
	    perform ${package_name}__delete(:group_id);

	    return 1;
	  END;
        
      </querytext>
</fullquery>

<fullquery name="member_p.user_is_member">      
      <querytext>
	  select acs_group__member_p(:user_id,:group_id, :cascade) from dual
      </querytext>
</fullquery>

 
</queryset>
