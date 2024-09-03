ad_library {

    Helpers for relational segments

    @author mbryzek@arsdigita.com
    @creation-date Tue Dec 12 16:37:45 2000
    @cvs-id $Id$

}

namespace eval rel_segment {}

ad_proc -deprecated rel_segments_new args {
    Creates a new relational segment

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @return The <code>segment_id</code> of the new segment

    DEPRECATED: does not comply with OpenACS naming convention

    @see rel_segment::new

} {
    return [rel_segment::new {*}$args]
}

ad_proc -public rel_segment::new {
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
    if { [ns_conn isconnected] } {
        if { $creation_user eq "" } {
            set creation_user [ad_conn user_id]
        }
        if { $creation_ip eq "" } {
            set creation_ip [ad_conn peeraddr]
        }
    }
    return [db_exec_plsql create_rel_segment {}]

}

ad_proc -deprecated rel_segments_delete {
    segment_id
} {
    Deletes the specified relational segment including all relational
    constraints that depend on it.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/12/2001

    DEPRECATED: does not comply with OpenACS naming convention

    @see rel_segment::delete
} {
    return [rel_segment::delete $segment_id]
}

ad_proc -public rel_segment::delete {
    segment_id
} {
    Deletes the specified relational segment including all relational
    constraints that depend on it.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 1/12/2001

} {
    # First delete dependent constraints.
    db_foreach select_dependent_constraints {
        select c.constraint_id
          from rel_constraints c
         where c.required_rel_segment = :segment_id
    } {
        db_exec_plsql constraint_delete {}
    }

    db_exec_plsql rel_segment_delete {}

}

ad_proc -deprecated -public rel_segments_permission_p {
    { -user_id "" }
    { -privilege "read" }
    segment_id
} {

    Wrapper for ad_permission to allow us to bypass having to
    specify the read privilege

    Deprecated: just another wrapper for permission::permission_p

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/2000

    @see permission::permission_p

} {
    return [permission::permission_p -party_id $user_id -object_id $segment_id -privilege $privilege]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
