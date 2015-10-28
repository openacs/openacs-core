# /packages/mbryzek-subsite/www/admin/groups/delete.tcl

ad_page_contract {

    Deletes a group

    @author mbryzek@arsdigita.com
    @creation-date Fri Dec  8 14:32:28 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
} -properties {
    context:onevalue
    group_name:onevalue
    number:onerow
    group_id:onevalue
} -validate {
    groups_exists_p -requires {group_id:notnull} {
	if { ![group::permission_p -privilege delete $group_id] } {
	    ad_complain "The group either does not exist or you do not have permission to delete it"
	}
    }
}

set context [list [list "" "Groups"] [list [export_vars -base one {group_id}] "One Group"] "Nuke group"]
set group_name [db_string object_name {}]
set export_form_vars [export_vars -form {group_id}]

db_1row select_counts {} -column_array number

ad_return_template

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
