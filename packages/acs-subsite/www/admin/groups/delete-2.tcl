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

if { [string eq $operation "Yes, I really want to delete this group"] } {
    db_transaction {
	set group_type [group::delete $group_id]
    }
    if { [empty_string_p $return_url] && ![empty_string_p $group_type] } {
	set return_url "../group-types/one?[ad_export_vars group_type]"
    }
} else {
    if { [empty_string_p $return_url] } {
	set return_url "one?[ad_export_vars group_id]"
    }
}


ad_returnredirect $return_url
