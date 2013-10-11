# /packages/mbryzek-subsite/tcl/group-type-procs.tcl

ad_library {

    Procs for creating group types

    @author mbryzek@arsdigita.com
    @creation-date Tue Nov  7 22:52:39 2000
    @cvs-id $Id$

}

namespace eval group_type {

    ad_proc -public drop_all_groups_p { 
	{ -user_id "" } 
	group_type 
    } {
	Returns 1 if the user has permission to delete all groups of
	the specified type. 0 otherwise. <code>user_id</code> defaults to <code>ad_conn
	user_id</code> if we have a connection. If there is no
	connection, and no user id, throws an error.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 12/2000

    } {
	if { $user_id eq "" } {
	    if { ![ad_conn isconnected] } {
		error "group_type::drop_all_groups_p: User ID not specified and we have no connection from which to obtain current user ID.\n"
	    } 
	    set user_id [ad_conn user_id]	
	}
	return [db_string group_exists_p {
	    select case when exists (select 1 
                                       from acs_objects o
                                      where acs_permission.permission_p(o.object_id, :user_id, 'delete') = 'f'
                                        and o.object_type = :group_type)
                        then 0 else 1 end
              from dual
	}]
    }

    
    ad_proc -public new {
	{ -group_type "" }
	{ -execute_p "t" }
	{ -supertype "group" }
	pretty_name
	pretty_plural
    } {
	Creates a new group type

	<p><b>Example:</b>
	<pre>
	# create a new group of type user_discount_class
	set group_type [group_type::new -group_type $group_type \
		-supertype group \
		"User Discount Class" "User Discount Classes"]
	</pre>

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 12/2000
	
	@param group_type The type of group_type to create. If empty,
	       we generate a unique group_type based on "group_id" where id is
	       the next value from acs_object_id_seq.

	@param execute_p If t, we execute the pl/sql. If f, we return
               a string that represents the pl/sql we are about to execute.

	@return the <code>group_type</code> of the object created
    } {
	if { $group_type eq "" } {
	    # generate a unique group type name. Note that we expect
	    # the while loop to finish immediately
	    while { $group_type eq "" || [plsql_utility::object_type_exists_p $group_type] } {
		set group_type "GROUP_[db_nextval "acs_object_id_seq"]"
	    }
	} else {
	    # use 29 chars to leave 1 character in the name for later dynamic views
	    set group_type [plsql_utility::generate_oracle_name -max_length 29 $group_type]
	    if { [plsql_utility::object_type_exists_p $group_type] } {
		error "Specified group type, $group_type, already exists"
	    }
	}
	
	set table_name [string toupper "${group_type}_ext"]
	# Since all group types are extensions of groups, maintain a
	# unique group_id primary key
	
	set id_column [db_string select_group_id_column {
	    select upper(id_column) from acs_object_types where object_type='group'
	}]
	set package_name [string tolower $group_type]
    
	# pull out information about the supertype 
	db_1row supertype_table_column {
	    select t.table_name as references_table,
                   t.id_column as references_column
  	      from acs_object_types t
	     where t.object_type = :supertype
	}

	# What happens if a constraint with the same name already
	# exists? We need to add robustness to the auto-generation of constraint
	# names at a later date. Probability of name collision is
	# small though so we leave it for a future version

	set constraint(fk) [plsql_utility::generate_constraint_name $table_name $id_column "fk"]
	set constraint(pk) [plsql_utility::generate_constraint_name $table_name $id_column "pk"]

	# Store the plsql in a list so that we can choose, at the end,
	# to either execute it or return it as a debug message

	set plsql [list]
	set plsql_drop [list]

	if { [db_table_exists $table_name] } {
	    # What to do? Options:
	    # a) throw an error
	    # b) select a new table name (Though this is probably an
	    #    error in the package creation script...)
	    # Choose (a)
	    error "The type extension table, $table_name, for the object type, $group_type, already exists. You must either drop the existing table or enter a different group type"
	}

	# Create the table if it doesn't exist. 
	lappend plsql_drop [list drop_type [db_map drop_type]]
	lappend plsql [list "create_type" [db_map create_type]]
  
        # Mark the type as dynamic
        lappend plsql [list update_type [db_map update_type]]

        # Now, copy the allowable relation types from the super type
        lappend plsql_drop [list remove_rel_types "delete from group_type_rels where group_type = :group_type"]
        lappend plsql [list copy_rel_types [db_map copy_rel_types]]

        if { $execute_p == "f" } {
	    set text "-- Create script"
	    foreach pair $plsql {
		append text "[plsql_utility::parse_sql [lindex $pair 1]]\n\n"
	    }
	    # Now add the drop script
	    append text "-- Drop script\n";
	    for { set i [expr {[llength $plsql_drop] - 1}] } { $i >= 0 } { set i [expr {$i - 1}] } {
		# Don't need the sql keys when we display debugging information
		append text "-- [lindex $plsql_drop $i 1]\n\n"
	    }
	    return $text
	}
	
	foreach pair $plsql { 
	    db_exec_plsql [lindex $pair 0] [lindex $pair 1]
	}

	# The following create table statement commits the
	# transaction. If it fails, we roll back what we've done
	if { [catch {db_exec_plsql create_table "
create table $table_name ( 
    $id_column   integer 
                 constraint $constraint(pk) primary key
                 constraint $constraint(fk) 
                   references $references_table ($references_column)
)"} errmsg] } {
            # Roll back our work so for
            for { set i [expr {[llength $plsql_drop] - 1}] } { $i >= 0 } { incr i -1 } {
		set pair [lindex $plsql_drop $i]
		if { [catch {db_exec_plsql [lindex $drop_pair 0] [lindex $drop_pair 1]} err_msg_2] } {
		    append errmsg "\nAdditional error while trying to roll back: $err_msg_2"
		    return -code error $errmsg
		}
	    }
	    return -code error $errmsg
        }

	# We need to add something to the group_types table, too! (Ben - OpenACS)
	db_dml insert_group_type {}

        # Finally, create the PL/SQL package. 

	package_recreate_hierarchy $group_type

	return $group_type

    }
	
}
