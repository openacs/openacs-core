# /packages/mbryzek-subsite/www/admin/rel-types/mapping-remove.tcl

ad_page_contract {

    Removes a mapping for a permissible rel_type between either a
    group or a group_type

    @author mbryzek@arsdigita.com
    @creation-date Tue Dec 12 10:45:07 2000
    @cvs-id $Id$

} {
    { group_rel_id:integer "" }
    { group_type_rel_id "" }
    { return_url "" }
} -properties {
    context:onevalue
}

if { [empty_string_p $group_rel_id] || [empty_string_p $group_type_rel_id] } {
    error "Either group_rel_id or group_rel_type_id must be specified"
}

if { ![empty_string_p $group_rel_id] } {
    db_dml delete_group_rel_mapping {
	delete from group_rels 
	 where group_rel_id = :group_rel_id
    }
} elseif { ![empty_string_p $group_rel_id] } {
    db_dml delete_group_type_rel_mapping {
	delete from group_type_rels 
	 where group_type_rel_id = :group_type_rel_id
    }
}

ad_returnredirect $return_url
