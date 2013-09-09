# /packages/mbryzek-subsite/www/admin/groups/rel-type-add-2.tcl

ad_page_contract {

    Adds a relationship type to the list of permissible ones for this
    group

    @author mbryzek@arsdigita.com
    @creation-date Tue Jan  2 12:10:17 2001
    @cvs-id $Id$

} {
    group_id:integer,notnull
    rel_type:notnull
    { return_url "" }
} -validate {
    rel_type_acceptable_p -requires {group_id:notnull rel_type:notnull} {
	# This test makes sure this group can accept the specified rel
	# type. This means the group is itself a type (or subtype) of
	# rel_type.object_type_one
	db_1row select_group_type {
	    select o.object_type as group_type
	      from acs_objects o
	     where o.object_id = :group_id
	}
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

if { [catch {
    set group_rel_id [db_nextval acs_object_id_seq]
    db_dml insert_rel_type {
    insert into group_rels
    (group_rel_id, group_id, rel_type)
    values
    (:group_rel_id, :group_id, :rel_type)
}   } err_msg] } {
    # Does this pair already exists?
    if { ![db_string exists_p {
	select case when exists (select 1 
                                   from group_rels 
                                  where group_id = :group_id
                                    and rel_type = :rel_type)
                    then 1 else 0 end
	  from dual
    }] } {
	ad_return_error "Error inserting to database" $err_msg
	return
    }
}

# Now let's see if there is no relational segment. If not, offer to create one
if { [db_string segment_exists_p {
    select case when exists (select 1 
                               from rel_segments s 
                              where s.group_id = :group_id
                                and s.rel_type = :rel_type)
                then 1 else 0 end
      from dual
}] } {
    if { $return_url eq "" } {
	set return_url one?[ad_export_vars group_id]
    }
    ad_returnredirect $return_url 
} else {
    ad_returnredirect constraints-create?[ad_export_vars {group_id rel_type return_url}]
}

