# /packages/mbryzek-subsite/www/admin/rel-segments/new.tcl

ad_page_contract {

    Form to create a new relational segment

    @author mbryzek@arsdigita.com
    @creation-date Mon Dec 11 13:51:21 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
    { rel_type:trim "" }
    { return_url "" }
} -properties {
    context:onevalue
    export_vars:onevalue
    group_id:onevalue
    primary_rels:multirow
    group_name:onevalue
    subsite_group_id:onevalue
} -validate {
    group_in_scope_p -requires {group_id:notnull} {
	if { ![application_group::contains_party_p -party_id $group_id -include_self]} {
	    ad_complain "The group either does not exist or does not belong to this subsite."
	}
    }
}

set subsite_group_id [application_group::group_id_from_package_id]

# If the user has specified a rel_type, redirect to new-2
if { $rel_type ne "" } {
    ad_returnredirect [export_vars -base new-2 {group_id rel_type return_url}]
    ad_script_abort
} 

permission::require_permission -object_id $group_id -privilege "read"

set context [list [list "" "Relational segments"] "Add segment"]

set export_vars [export_vars -form {group_id return_url}]
# Select out all relationship types
db_multirow rel_types select_relation_types {}

db_1row select_basic_info {}

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
