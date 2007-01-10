# /packages/mbryzek-subsite/tcl/rel-segments-procs.tcl

ad_library {

    Helpers for relational segments

    @author mbryzek@arsdigita.com
    @creation-date Tue Dec 12 16:37:45 2000
    @cvs-id $Id$
    
}

ad_proc -public rel_segments_new {
    { -context_id "" }
    { -creation_user "" }
    { -creation_ip "" }
    group_id
    rel_type
    segment_name 
} {
    Creates a new relational segment

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @return The <code>segment_id</code> of the new segment

} {
    if { [ad_conn isconnected] } {
	if { $creation_user eq "" } {
	    set creation_user [ad_conn user_id]
	}
	if { $creation_ip eq "" } {
	    set creation_ip [ad_conn peeraddr]
	}
    }
    return [db_exec_plsql create_rel_segment {
      declare
      begin 
	:1 := rel_segment.new(segment_name => :segment_name,
                                  group_id => :group_id,
                                  context_id => :context_id,
                                  rel_type => :rel_type,
                                  creation_user => :creation_user,
                                  creation_ip => :creation_ip
                                 );
      end;
    }]

}

ad_proc -public rel_segments_delete {
    segment_id 
} {
    Deletes the specified relational segment including all relational
    constraints that depend on it. 

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/12/2001

} {
    # First delete dependant constraints.
    db_foreach select_dependant_constraints {
	select c.constraint_id
	  from rel_constraints c
	 where c.required_rel_segment = :segment_id
    } {
	db_exec_plsql constraint_delete {
	    begin rel_constraint.del(:constraint_id); end;
	}
    }

    db_exec_plsql rel_segment_delete {
	begin rel_segment.del(:segment_id); end;
    }
    
}

ad_proc -public rel_segments_permission_p { 
    { -user_id "" }
    { -privilege "read" }
    segment_id
} {

    Wrapper for ad_permission to allow us to bypass having to
    specify the read privilege

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

} {
    return [ad_permission_p -user_id $user_id $segment_id $privilege]
}

