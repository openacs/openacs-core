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

                rel_segment.delete(row.constraint_id);

            end loop;

	    -- delete the actual group
	    ${package_name}.delete(:group_id); 
	  END;
        
      </querytext>
</fullquery>

 
</queryset>
