# /packages/mbryzek-subsite/www/admin/group-types/delete-2.tcl

ad_page_contract {

    Deletes a group type

    @author mbryzek@arsdigita.com
    @creation-date Wed Nov  8 18:29:11 2000
    @cvs-id $Id$

} {
    group_type
    { return_url:localurl "" }
    { operation "" }
} -properties {
    context:onevalue
} -validate {
    user_can_delete_group -requires {group_type:notnull} {
	if { ![group_type::drop_all_groups_p $group_type] } {
	    ad_complain "Groups exist that you do not have permission to delete. All groups must be deleted before you can remove a group type. Please contact the site administrator."
	}
    }
}

if { $operation ne "Yes, I really want to delete this group type" } {
    if { $return_url eq "" } {
	ad_returnredirect [export_vars -base one {group_type}]
    } else {
	ad_returnredirect $return_url
    }
    ad_script_abort
}

set plsql [list]

if { ![db_0or1row select_type_info {
    select t.table_name, t.package_name
      from acs_object_types t
     where t.object_type=:group_type
}] } {
    set table_name ""
    set package_name $group_type
}
    
if { [db_string package_exists {}] } {
    lappend plsql [list "package_drop" [db_map package_drop]]
} else {
    set package_name ""
}

# Remove the specified rel_types
lappend plsql [list "delete_rel_types" [db_map delete_rel_types]]

# Remove the group_type
lappend plsql [list "delete_group_type" [db_map delete_group_type]]

if { [db_string type_exists {}] } {
    lappend plsql [list "drop_type" [db_map drop_type]]
}

# Make sure we drop the table last
if { $table_name ne "" && [db_table_exists $table_name] } {
    lappend plsql [list "drop_table" [db_map drop_table]]
}

# How do we handle the situation where we delete the groups we can,
# but there are groups that we do not have permission to delete? For
# now, we check in advance if there is a group that must be deleted
# that this user can't delete, and if there is, we return an error
# message (in the validate block of page contract). If another group
# is added while we're deleting, then it's possible that we'll fail
# when actually dropping the type, but that seems reasonable to me. 
# - mbryzek (famous last words...)

set user_id [ad_conn user_id]

db_transaction {
    # First delete the groups
    if { $package_name ne "" } {

	foreach group_id [db_list select_group_ids {}] {
	    group::delete $group_id
	}
    }

    foreach pair $plsql {
	db_exec_plsql [lindex $pair 0] [lindex $pair 1]
    }
} on_error {
    ad_return_error "Error deleting group type" "We got the following error trying to delete this group type:<pre>$errmsg</pre>"
    return
}

# Reset the attribute view for objects of this type
package_object_view_reset $group_type

ad_returnredirect $return_url 

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
