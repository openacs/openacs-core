# /packages/mbryzek-subsite/www/admin/group-types/rel-type-add-2.tcl

ad_page_contract {

    Adds the relationship type to the list of allowable ones for this
    group type=

    @author mbryzek@arsdigita.com
    @creation-date Sun Dec 10 16:57:10 2000
    @cvs-id $Id$

} {
    group_type:trim,notnull
    rel_type:trim,notnull
    { return_url "" }
} -validate {
    rel_type_acceptable_p -requires {group_type:notnull rel_type:notnull} {
	# This test makes sure this group_type can accept the
	# specified rel type. This means the group type is itself a
	# type (or subtype) of rel_type.object_type_one
	if { ![db_string types_match_p {
	    select count(*)
	      from acs_rel_types t
	     where (t.object_type_one = :group_type 
                    or acs_object_type.is_subtype_p(t.object_type_one, :group_type) = 't')
               and t.rel_type = :rel_type
	}] } {
	    ad_complain "Groups of type \"$group_type\" cannot use relationships of type \"$rel_type.\""
	}
    }
}


if { [catch {db_dml insert_rel_type {
    insert into group_type_rels
    (group_rel_type_id, group_type, rel_type)
    values
    (acs_object_id_seq.nextval, :group_type, :rel_type)
}   } err_msg] } {
    # Does this pair already exists?
    if { ![db_string exists_p {select count(*) from group_type_rels where group_type = :group_type and rel_type = :rel_type}] } {
	ad_return_error "Error inserting to database" $err_msg
	return
    }

}

db_release_unused_handles

if { [empty_string_p $return_url] } {
    set return_url "one?[ad_export_vars {group_type}]"
}

ad_returnredirect $return_url
