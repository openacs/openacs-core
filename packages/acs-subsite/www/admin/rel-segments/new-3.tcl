# /packages/mbryzek-subsite/www/admin/rel-segments/new-3.tcl

ad_page_contract {

    Creates a relational segment. Finished by asking the user to
    create constraints

    @author mbryzek@arsdigita.com
    @creation-date Wed Dec 13 20:00:25 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
    segment_name:notnull
    rel_type:notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    segment_name:onevalue
} -validate {
    group_in_scope_p -requires {group_id:notnull} {
	if { ![application_group::contains_party_p -party_id $group_id -include_self]} {
	    ad_complain "The group either does not exist or does not belong to this subsite."
	}
    }
    relation_in_scope_p -requires {rel_id:notnull permission_p} {
	if { ![application_group::contains_relation_p -rel_id $rel_id]} {
	    ad_complain "The relation either does not exist or does not belong to this subsite."
	}
    }
}


# Make sure we are creating a segment on a group we can actually see
permission::require_permission -object_id $group_id -privilege "read"

db_transaction {
    set segment_id [rel_segments_new -context_id $group_id $group_id $rel_type $segment_name]
} on_error {
    # Let's see if this segment already exists
    set segment_id [db_string select_segment_id {
	select s.segment_id
	  from rel_segments s
	 where s.group_id = :group_id
	   and s.rel_type = :rel_type
    } -default ""]
    if { $segment_id eq "" } {
	ad_return_error "Error creating segment" $errmsg
	ad_script_abort
    }
}

# Now let's offer to walk the user through the process of creating
# constraints it there are any other segments

if { ![db_string segments_exists_p {}] } {
    # No more segments... can't create constraints
    ad_returnredirect $return_url
    return
}


set context [list [list "[ad_conn package_url]admin/rel-segments/" "Relational segments"] [list [export_vars -base one segment_id] "One segment"] "Create constraints"]
set export_vars [export_vars -form {segment_id return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
