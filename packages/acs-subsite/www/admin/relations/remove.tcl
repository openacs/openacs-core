# /packages/mbryzek-subsite/www/admin/relations/remove.tcl

ad_page_contract {
    Confirmation page for relation removal.

    @author mbryzek@arsdigita.com
    @creation-date 2000-12-16
    @cvs-id $Id$
} {
    rel_id:naturalnum,notnull
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    rel:onerow
    dependants:multirow
} -validate {
    permission_p -requires {rel_id:notnull} {
	if { ![relation_permission_p -privilege delete $rel_id] } {
	    ad_complain "The relation either does not exist or you do not have permission to remove it"
	}
    }
    relation_in_scope_p -requires {rel_id:notnull permission_p} {
	if { ![application_group::contains_relation_p -rel_id $rel_id]} {
	    ad_complain "The relation either does not exist or does not belong to this subsite."
	}
    }
}

set context [list "Remove relation"]

if { ![db_0or1row select_rel_info {} -column_array rel] 
} {
    ad_return_error "Error" "Relation $rel_id does not exist"
    ad_script_abort
}

# Now let's see if removing this relation would violate some
# constraint.

if { [relation_segment_has_dependant -rel_id $rel_id] } {
    set return_url "[ad_conn url]?[ad_conn query]"
    # We can't remove this relation - display the violations
    template::multirow create dependants rel_id rel_type_pretty_name object_id_one_name object_id_two_name export_vars

    db_foreach select_dependants {} {
	template::multirow append dependants $rel_id $rel_type_pretty_name $object_id_one_name $object_id_two_name [export_vars {rel_id return_url}]
    }
    ad_return_template remove-dependants-exist
    return
}


set export_vars [export_vars -form {rel_id return_url}]

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
