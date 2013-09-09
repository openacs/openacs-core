# /packages/mbryzek-subsite/www/admin/groups/delete-2.tcl

ad_page_contract {

    Deletes a group

    @author mbryzek@arsdigita.com
    @creation-date Fri Dec  8 14:41:36 2000
    @cvs-id $Id$

} {
    group_id:integer,notnull
    { operation "" }
    { return_url "" }
} -validate {
    groups_exists_p -requires {group_id:notnull} {
	if { ![group::permission_p $group_id] } {
	    ad_complain "The group either does not exist or you do not have permission to view it"
	}
    }
}

if {$operation eq "Yes, I really want to delete this group"} {
    db_transaction {
	set group_type [group::delete $group_id]
    }
    if { $return_url eq "" && $group_type ne "" } {
	set return_url "../group-types/one?[ad_export_vars group_type]"
    }
} else {
    if { $return_url eq "" } {
	set return_url "one?[ad_export_vars group_id]"
    }
}


ad_returnredirect $return_url
