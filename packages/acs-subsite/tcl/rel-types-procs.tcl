# /packages/mbryzek-subsite/tcl/rel-types-procs.tcl

ad_library {

    Procs about relationships

    @author mbryzek@arsdigita.com
    @creation-date Tue Dec 12 15:40:39 2000
    @cvs-id $Id$

}


ad_page_contract_filter rel_type_dynamic_p { name value } {
    Checks whether the value (assumed to be a string referring to a
    relationship type) is a dynamic object type.

    @author Michael Bryzek (mbryzek@arsdigita.com)
    @creation-date 12/30/2000

} {
    if { [db_string rel_type_dynamic_p {
	select case when exists (select 1 
                                   from acs_object_types t
                                  where t.dynamic_p = 't'
                                    and t.object_type = :value)
	            then 1 else 0 end
	  from dual
    }] } {
	return 1
    }
    ad_complain "Specific rel type either does not exist or is not dynamic and thus cannot be modified"
    return 0
}


namespace eval rel_types {

    ad_proc -public additional_rel_types_p { 
	{ -group_id "" } 
	{ -group_type "" }
    } {
	Returns 1 if there is a relationship type not being used by
	the specified group_id or group_type. Useful for deciding when
	to offer the user a link to create a add a new permissible
	relationship type

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 12/2000
	
    } {
	if { ![empty_string_p $group_id] } {
	    return [additional_rel_types_group_p $group_id]
	} elseif { ![empty_string_p $group_type] } {
	    return [additional_rel_types_group_type_p $group_type]
	} else {
	    error "rel_types::rel_types_p error: One of group_id or group_type must be specified"
	}
    }

    ad_proc -private additional_rel_types_group_p { group_id } {
	returns 1 if there is a rel type that is not defined as a
	segment for this group

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 12/30/2000

    } {
	return [db_string "group_rel_type_exists" "
	     select case when exists (select 1 
                                        from acs_object_types t
                                        where t.object_type not in (select g.rel_type
                                                                      from group_rels g
                                                                     where g.group_id = :group_id)
                                      connect by prior t.object_type = t.supertype
                                        start with t.object_type in ('membership_rel','composition_rel'))
                    then 1 else 0 end
               from dual"]
    }


    ad_proc -private additional_rel_types_group_type_p { group_type } {
	returns 1 if there is a rel type that is not defined as
	allowable for the specified group_type.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 12/30/2000

    } {
	return [db_string "group_rel_type_exists" "
	     select case when exists (select 1 
                                        from acs_object_types t
                                        where t.object_type not in (select g.rel_type
                                                                      from group_type_rels g
                                                                     where g.group_type = :group_type)
                                      connect by prior t.object_type = t.supertype
                                        start with t.object_type in ('membership_rel','composition_rel'))
                    then 1 else 0 end
               from dual"]
    }

    
    ad_proc -public new {
	{ -supertype "relationship" }
	{ -role_one "" }
	{ -role_two "" }
	rel_type 
	pretty_name 
	pretty_plural 
	object_type_one 
	min_n_rels_one 
	max_n_rels_one 
	object_type_two 
	min_n_rels_two 
	max_n_rels_two
    } {
	Creates a new relationship type named rel_type
	
	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 12/30/2000

    } {
	
	# use 29 chars to leave 1 character in the name for later dynamic views
	set rel_type [plsql_utility::generate_oracle_name -max_length 29 $rel_type]
	if { [plsql_utility::object_type_exists_p $rel_type] } {
	    error "Specified relationship type, $rel_type, already exists (or another object of the same type exists)\n"
	}
	 
	if { ![db_0or1row parent_rel_type {
	    select table_name as references_table,
	           id_column as references_column
	      from acs_object_types
	     where object_type=:supertype
	}] } {
	    error "The specified supertype \"$supertype\" does not exist"
	}

	# use 29 chars to leave 1 character in the name for later dynamic views
	set table_name [plsql_utility::generate_oracle_name -max_length 29 "${rel_type}_ext"]
	set package_name $rel_type

	# We use rel_id for the primary key... since this is a relationship
	set pk_constraint_name [plsql_utility::generate_constraint_name $table_name rel_id "pk"]
	set fk_constraint_name [plsql_utility::generate_constraint_name $table_name rel_id "fk"]
    
	set plsql [list]

	# Create the actual acs object type
	lappend plsql_drop [list db_exec_plsql drop_type {FOO}]
	lappend plsql [list db_exec_plsql create_type {FOO}]
	
	# Mark the type as dynamic
	lappend plsql [list db_dml update_type {FOO}]
	
	foreach pair $plsql { 
	    eval [lindex $pair 0] [lindex $pair 1] [lindex $pair 2]
	}

	# The following create table statement commits the
	# transaction. If it fails, we roll back what we've done

	if { [catch {db_exec_plsql create_table "
	create table $table_name (
            rel_id constraint $fk_constraint_name
                   references $references_table ($references_column)
                   constraint $pk_constraint_name primary key
	)"} errmsg] } {
            # Roll back our work so for
            for { set i [expr [llength $plsql_drop] - 1] } { $i >= 0 } { incr i -1 } {
		set drop_pair [lindex $plsql_drop $i]
		if { [catch {eval [lindex $drop_pair 0] [lindex $drop_pair 1] [lindex $drop_pair 2]} err_msg_2] } {
		    append errmsg "\nAdditional error while trying to roll back: $err_msg_2"
		    return -code error $errmsg
		}
	    }
	    return -code error $errmsg
        }

	# Finally, create the PL/SQL package. 
	package_recreate_hierarchy $rel_type

	return $rel_type
    
    }

    ad_proc -public add_permissible {
	group_type
	rel_type
    } {
	Add a permissible relationship for a given group type
    } {
	if {[catch {
	    db_dml insert_rel_type {}
	} errmsg]} {
	}
    }

    ad_proc -public remove_permissible {
	group_type
	rel_type
    } {
	Add a permissible relationship for a given group type
    } {
	if {[catch {
	    db_dml delete_rel_type {}
	} errmsg]} {
	}
    }
	
}

