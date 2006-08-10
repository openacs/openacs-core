ad_library {
    Sweep the all the files in the system looking for systematic errors.

    @author Jeff Davis
    @creation-date 2005-02-28
    @cvs-id $Id$
}


aa_register_case -cats {db smoke production_safe} datamodel__named_constraints {
    Check that all the contraints meet the constraint naming standards.

    @author Jeff Davis davis@xarg.net
} {
    switch -exact -- [db_name] {
        PostgreSQL {
            db_foreach check_constraints {
                select relname as table, conname from pg_constraint r join (select relname,oid from pg_class) c on (c.oid = r.conrelid) where
                not ( conname like '%_pk' or conname like '%_un' or conname like '%_fk' or conname like '%_ck')
            } {
                aa_log_result fail "Table $table constraints name $conname violates contraint naming standard"
            }
        }
	Oracle8 {
	    aa_log "CK type includes also NOT NULL constraints"
	    db_foreach check_constraints {
		select at.table_name,
		  decode(ac.constraint_type,'C','CK','R','FK','P','PK','U','UN','--') as c_type,
		  ac.constraint_name 
		from user_tables at, user_constraints ac 
		where ac.table_name (+)= at.table_name 
		  and not (constraint_name like '%_PK' or constraint_name like '%_UN' or constraint_name like '%_FK' or constraint_name like '%_CK' or constraint_name like '%_NN')
	    } {
                aa_log_result fail "Table $table_name constraints name $constraint_name ($c_type) violates constraint naming standard"
	    }
	}
        default {
            aa_log "Not run for [db_name]"
        }
    }
}



aa_register_case -cats {db smoke production_safe} datamodel__acs_object_type_check {
    Check that the object type tables exist and that the id column is present and the 
    name method works.

    @author Jeff Davis davis@xarg.net
} {
    db_foreach object_type {select * from acs_object_types} {
        if {![string eq [string tolower $table_name] $table_name]} {
            aa_log_result fail "Type $object_type: table_name $table_name mixed case"
        }
        if {![string eq [string tolower $id_column] $id_column]} {
            aa_log_result fail "Type $object_type: id_column $id_column mixed case"
        }
        set table_name [string tolower $table_name]
        set id_column [string tolower $id_column]

        set the_pk {}
        if {![db_table_exists $table_name]} {
            aa_log_result fail "Type $object_type: table $table_name does not exit"
        } else {
            if {[string is space $id_column]} {
                aa_log_result fail "Type $object_type: id_column not specified"
            } else {
                # limit pg only?
                # we could just check the column exists but since we want to 
                # check the name method try at least to get a real object_id
                if {[catch {db_0or1row check_exists "select min($id_column) as the_pk from $table_name"} errMsg]} { 
                    aa_log_result fail "Type $object_type: select $id_column from $table_name failed:\n$errMsg"
                }
            }
        }

        if {![string is space $name_method]} {
            if {![string eq [string tolower $name_method] $name_method]} {
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



aa_register_case -cats {db smoke production_safe} datamodel__acs_attribute_check {
    Check that the acs_attribute column is present and the datatype is vaguely 
    consistent with the db datatype.

    @author Jeff Davis davis@xarg.net
} {
    array set allow_types {
        string {TEXT VARCHAR CHAR VARCHAR2}
        boolean {BOOL INT2 INT4 CHAR}
        number {NUMERIC INT2 INT4 INT8 FLOAT4 FLOAT8 NUMBER}
        integer {INT2 INT4 INT8 NUMBER}
        money {NUMERIC FLOAT4 FLOAT8}
        timestamp {TIMESTAMPTZ}
        time_of_day {TIMESTAMPTZ}
        enumeration {INT2 INT4 INT8}
        url {VARCHAR TEXT VARCHAR2}
        email {VARCHAR TEXT VARCHAR2}
        text  {VARCHAR TEXT CLOB VARCHAR2}
        keyword {CHAR VARCHAR TEXT VARCHAR2}
    }

    db_foreach attribute {select a.*, lower(ot.table_name) as obj_type_table from acs_attributes a, acs_object_types ot where ot.object_type = a.object_type order by a.object_type} {

        if {![string eq [string tolower $table_name] $table_name]} {
            aa_log_result fail "Type $object_type attribute $attribute table name $table_name mixed case"
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

                if {[lsearch $columns($obj_type_table) $column_name] < 0} {
                    aa_log_result fail "Type $object_type attribute column $column_name not found in $obj_type_table"
                } else {
                    # check the type of the column is vaguely like the acs_datatype type.
                    if {[info exists allow_types($datatype)]} {
                        set actual_type [db_column_type $table_name $column_name]
                        if {$actual_type eq "-1"} {
                            aa_log_result fail "Type $object_type attribute $attribute_name database type get for ($table_name.$column_name) failed"
                        } else {
                            if {[lsearch $allow_types($datatype) $actual_type] < 0} {
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
                aa_log_result fail "Type $object_type attribute $attribute storage type null"
            }
        }
    }
}
