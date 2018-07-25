ad_library {
    Sweep the all the files in the system looking for systematic errors.

    @author Jeff Davis
    @creation-date 2005-02-28
    @cvs-id $Id$
}


aa_register_case \
    -cats {db smoke production_safe} \
    -error_level warning \
    -procs {} \
    datamodel__named_constraints {
        
        Check that all the constraints meet the constraint naming
        standards.

        @author Jeff Davis davis@xarg.net
} {

    set db_is_pg_p [string equal [db_name] "PostgreSQL"]

    if { $db_is_pg_p } {
	set get_constraints "select 
		cla.relname as table_name,
		con.conrelid,
		con.conname as constraint_name,
		CASE 
		when con.contype='c' then 'ck'
		when con.contype='f' then 'fk'
		when con.contype='p' then 'pk'
		when con.contype='u' then 'un'
		else '' 
		END as constraint_type,
		con.conkey,
                '' as search_condition
		from 
		pg_constraint con,
		pg_class cla
		where con.conrelid != 0 and cla.oid=con.conrelid
		order by table_name,constraint_name"
	set get_constraint_col "select attname from pg_attribute where attnum = :columns_list and attrelid = :conrelid"
    } else {
	# Oracle
	set get_constraints "select
		acc.*, ac.search_condition,
		  decode(ac.constraint_type,'C','CK','R','FK','P','PK','U','UN','') as constraint_type
		from 
		  (select count(column_name) as columns, table_name, constraint_name from user_cons_columns group by table_name, constraint_name) acc,
		  user_constraints ac 
		where ac.constraint_name = acc.constraint_name
		order by acc.table_name, acc.constraint_name"
	set get_constraint_col "select column_name from user_cons_columns where constraint_name = :constraint_name"
    }

    db_foreach check_constraints $get_constraints {
	if { $db_is_pg_p || [string last "$" $table_name] eq -1 } {

	    regsub {_[[:alpha:]]+$} $constraint_name "" name_without_type
	    set standard_name "${name_without_type}_${constraint_type}"
            set standard_name_alt "${name_without_type}_[ad_decode $constraint_type pk pkey fk fkey un key ck ck missing]"

	    if { $db_is_pg_p } {
		set columns_list [split [string range $conkey 1 end-1] ","]
		set columns [llength $columns_list]
	    }

	    if { $columns eq 1 } {

		set column_name [db_string get_col $get_constraint_col]
		
		# NOT NULL constraints (oracle only)
		if { [string equal $search_condition "\"$column_name\" IS NOT NULL"] } {
		    set constraint_type "NN"
		}

		set standard_name ${table_name}_${column_name}_${constraint_type}

		if { [string length $standard_name] > 30 } {
		    # Only check the abbreviation
		    set standard_name "${name_without_type}_${constraint_type}"
		}
	    }

	    # Giving a hint for constraint naming
	    if {[string range $standard_name 0 2] eq "SYS"} {
		set hint "unnamed"
	    } else {
		set hint "hint: $standard_name"
	    }

	    if { $standard_name ne $constraint_name 
                 && $standard_name_alt ne $constraint_name } {
		aa_log_result fail "Table $table_name constraint $constraint_name ($constraint_type) violates naming standard ($hint)"
	    }
	}
    }
}



aa_register_case \
    -cats {db smoke production_safe} \
    -procs {db_table_exists} \
    datamodel__acs_object_type_check {
        
        Check that the object type tables exist and that the id column is
        present and the name method works.

        @author Jeff Davis davis@xarg.net
} {
    db_foreach object_type {select * from acs_object_types} {
        if {[string tolower $table_name] ne $table_name } {
            aa_log_result fail "Type $object_type: table_name $table_name mixed case"
        }
        if {[string tolower $id_column] ne $id_column } {
            aa_log_result fail "Type $object_type: id_column $id_column mixed case"
        }
        set table_name [string tolower $table_name]
        set id_column [string tolower $id_column]

        set the_pk {}
	while { [string is space $table_name] && $object_type ne $supertype } {
	    if {![db_0or1row get_supertype "select * from acs_object_types where object_type = :supertype"]} {
		break
	    }
        } 
	if {![db_table_exists $table_name]} {
            aa_log_result fail "Type $object_type: table $table_name does not exit"
        } else {
            if {[string is space $id_column]} {
                aa_log_result fail "Type $object_type: id_column not specified"
            } else {
                # we could just check the column exists but since we want to 
                # check the name method try at least to get a real object_id
                if {[catch {db_0or1row check_exists "select min($id_column) as the_pk from $table_name"} errMsg]} { 
                    aa_log_result fail "Type $object_type: select $id_column from $table_name failed:\n$errMsg"
                }
            }
        }

        if {![string is space $name_method]} {
            if {[string tolower $name_method] ne $name_method } {
                aa_log_result fail "Type $object_type: name method $name_method mixed case"
            }
            set name_method [string tolower $name_method]
            if {[string is integer -strict $the_pk]} {
                # intentionally don't use bind variables here which is ok 
                # since we just checked the_pk was an integer
                if { [catch {db_0or1row name_method "select ${name_method}($the_pk) as NAME from dual"} errMsg] } { 
                    aa_log_result fail "Type $object_type: name method $name_method failed\n$errMsg"
                }
            }
        }
        if {![string is space $type_extension_table] 
            && ![db_table_exists $type_extension_table]} { 
            aa_log_result fail "Type $object_type: type extension table $type_extension_table does not exist"
        }
    }
}



aa_register_case \
    -cats {db smoke production_safe} \
    -procs {db_column_type db_columns} \
    datamodel__acs_attribute_check {
        
        Check that the acs_attribute column is present and the
        datatype is vaguely consistent with the db datatype.

        @author Jeff Davis davis@xarg.net
} {
    array set allow_types {
        string {TEXT VARCHAR CHAR VARCHAR2}
        boolean {BOOL INT2 INT4 CHAR BPCHAR}
        number {NUMERIC INT2 INT4 INT8 FLOAT4 FLOAT8 NUMBER}
        integer {INT2 INT4 INT8 NUMBER}
        money {NUMERIC FLOAT4 FLOAT8}
        timestamp {TIMESTAMP TIMESTAMPTZ}
        time_of_day {TIMESTAMP TIMESTAMPTZ}
        enumeration {INT2 INT4 INT8}
        url {VARCHAR TEXT VARCHAR2}
        email {VARCHAR TEXT VARCHAR2}
        text  {VARCHAR TEXT CLOB VARCHAR2}
        keyword {CHAR VARCHAR TEXT VARCHAR2}
    }

    db_foreach attribute {
        select a.*, lower(ot.table_name) as obj_type_table
        from acs_attributes a, acs_object_types ot
        where ot.object_type = a.object_type order by a.object_type
    } {

        if {[string tolower $table_name] ne $table_name } {
            aa_log_result fail "Type $object_type attribute $table_name.$attribute_name mixed case"
            set table_name [string tolower $table_name]
        } elseif {[string is space $table_name]} {
            set table_name $obj_type_table
        }

        switch -exact $storage {
            type_specific {
                if {![info exists columns($table_name)]} {
                    set columns($table_name) [db_columns $table_name]
                }

                if {[string is space $column_name]} {
                    set column_name $attribute_name
                }
                set column_name [string tolower $column_name]

                if {$column_name ni $columns($obj_type_table)} {
                    aa_log_result fail "Type $object_type attribute column $column_name not found in $obj_type_table"
                } else {
                    # check the type of the column is vaguely like the acs_datatype type.
                    if {[info exists allow_types($datatype)]} {
                        set actual_type [db_column_type $table_name $column_name]
                        if {$actual_type eq "-1"} {
                            aa_log_result fail "Type $object_type attribute $attribute_name database type get for ($table_name.$column_name) failed"
                        } else {
                            if {$actual_type ni $allow_types($datatype)} {
                                aa_log_result fail "Type $object_type attribute $attribute_name database type was $actual_type for $datatype"
                            }
                        }
                    }
                }
            }
            generic {
                # nothing really to do here...
            }
            default {
                # it was null which is probably not sensible.
                aa_log_result fail "Type $object_type attribute $table_name.$attribute_name storage type null"
            }
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
