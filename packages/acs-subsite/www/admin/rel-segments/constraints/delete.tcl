# /packages/mbryzek-subsite/www/admin/rel-segments/constraints/delete.tcl

ad_page_contract {
    
    Confirms deletions of a constraint

    @author mbryzek@arsdigita.com
    @creation-date Fri Dec 15 11:22:34 2000
    @cvs-id $Id$

} {
    constraint_id:naturalnum,notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    constraint_name:onevalue
    segment_name:onevalue
    export_vars:onevalue
}

set context [list [list [export_vars -base one constraint_id] "One constraint"] "Delete constraint"]

set package_id [ad_conn package_id]

if { ![db_0or1row select_constraint_props {
    select c.constraint_name, s.segment_name
      from rel_constraints c, application_group_segments s,
           application_group_segments s2
     where c.rel_segment = s.segment_id
       and c.constraint_id = :constraint_id
       and s.package_id = :package_id
       and s2.segment_id = c.required_rel_segment
       and s2.package_id = :package_id
}] } {
    # The constraint is already deleted.... return
    ad_returnredirect $return_url
    ad_script_abort
}

set export_vars [export_vars -form {constraint_id return_url}]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
