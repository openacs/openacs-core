# /packages/mbryzek-subsite/www/admin/relations/remove.tcl

ad_page_contract {
    Confirmation page for relation removal.

    @author mbryzek@arsdigita.com
    @creation-date 2000-12-16
    @cvs-id $Id$
} {
    rel_id:naturalnum,notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    rel:onerow
    dependents:multirow
} -validate {
    permission_p -requires {rel_id:notnull} {
        if { ![permission::permission_p -object_id $rel_id -privilege "delete"] } {
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

if { ![db_0or1row select_rel_info {
    select (select pretty_name from acs_object_types
             where object_type = r.rel_type) as rel_type_pretty_name,
           r.object_id_one,
           r.object_id_two
      from acs_rels r
     where r.rel_id = :rel_id    
} -column_array rel] } {
    ad_return_error "Error" "Relation $rel_id does not exist"
    ad_script_abort
}

set rel(object_id_one_name) [acs_object_name $rel(object_id_one)]
set rel(object_id_two_name) [acs_object_name $rel(object_id_two)]

# Now let's see if removing this relation would violate some
# constraint.

if { [relation_segment_has_dependent -rel_id $rel_id] } {
    set return_url "[ad_conn url]?[ad_conn query]"
    # We can't remove this relation - display the violations
    db_multirow -extend {export_vars} dependents select_dependents {} {
        set export_vars [export_vars {rel_id return_url}]
    }
    ad_return_template remove-dependents-exist
    return
}


set export_vars [export_vars -form {rel_id return_url}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
