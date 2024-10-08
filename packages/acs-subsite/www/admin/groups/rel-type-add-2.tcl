ad_page_contract {

    Adds a relationship type to the list of permissible ones for this
    group

    @author mbryzek@arsdigita.com
    @creation-date Tue Jan  2 12:10:17 2001
    @cvs-id $Id$

} {
    group_id:integer,notnull
    rel_type:notnull
    { return_url:localurl "" }
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
        if { ![db_0or1row types_match_p {
            with recursive type_hierarchy as (
                select object_type
                  from acs_object_types
                 where object_type = (select object_type_one
                                      from acs_rel_types
                                      where rel_type = :rel_type)

                union all

                select t.object_type
                  from acs_object_types t,
                       type_hierarchy h
                 where t.supertype = h.object_type
                   and h.object_type <> :group_type
            )
            select 1 from type_hierarchy
            where object_type = :group_type
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
    }
} err_msg]} {
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
        ad_script_abort
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
        set return_url [export_vars -base one group_id]
    }
    ad_returnredirect $return_url
} else {
    ad_returnredirect [export_vars -base constraints-create {group_id rel_type return_url}]
}
ad_script_abort



# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
