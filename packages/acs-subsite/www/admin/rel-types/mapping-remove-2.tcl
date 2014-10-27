# /packages/mbryzek-subsite/www/admin/rel-types/mapping-remove.tcl

ad_page_contract {

    Removes a mapping for a permissible rel_type between either a
    group or a group_type

    @author mbryzek@arsdigita.com
    @creation-date Tue Dec 12 10:45:07 2000
    @cvs-id $Id$

} {
    { group_rel_id:naturalnum "" }
    { group_type_rel_id:naturalnum "" }
    { return_url "" }
} -properties {
    context:onevalue
}

if { $group_rel_id eq "" || $group_type_rel_id eq "" } {
    error "Either group_rel_id or group_rel_type_id must be specified"
}

if { $group_rel_id ne "" } {
    db_dml delete_group_rel_mapping {
	delete from group_rels 
	 where group_rel_id = :group_rel_id
    }
} elseif { $group_rel_id ne "" } {
    db_dml delete_group_type_rel_mapping {
	delete from group_type_rels 
	 where group_type_rel_id = :group_type_rel_id
    }
}

ad_returnredirect $return_url
