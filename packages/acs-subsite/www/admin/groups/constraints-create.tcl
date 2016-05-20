# /packages/mbryzek-subsite/www/admin/groups/constraints-create.tcl

ad_page_contract {

    Describes constraints and offers the option to create a relational
    segment for this rel_type

    @author mbryzek@arsdigita.com
    @creation-date Thu Jan  4 10:54:36 2001
    @cvs-id $Id$

} {
    group_id:notnull,naturalnum
    rel_type:notnull
    { return_url:localurl "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    rel_type_pretty_name:onevalue
    group_name:onevalue
}

set context [list [list "[ad_conn package_url]admin/groups/" "Groups"] [list [export_vars -base one group_id] "One Group"] "Add constraint"]
set export_vars [export_vars -form {group_id rel_type return_url}]

db_1row select_props {}

ad_return_template



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
