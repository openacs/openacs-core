ad_library {
    Sweep the all the files in the system looking for systematic errors.

    @author Jeff Davis
    @creation-date 2005-02-28
    @cvs-id $Id$
}


aa_register_case -cats {db smoke production_safe} datamodel__named_constraints {
    Check that there are no tables with unnamed constraints

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
        default {
            aa_log "Not run for [db_name]"
        }
    }
}



aa_register_case -cats {db smoke production_safe} datamodel__acs_object_type_check {
    Check that the object type tables exist and that th

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

        set __pk {}
        if {![db_table_exists $table_name]} {
            aa_log_result fail "Type $object_type: table $table_name does not exit"
        } else {
            if {[string is space $id_column]} {
                aa_log_result fail "Type $object_type: id_column not specified"
            } else {
                # limit pg only?
                # we could just check the column exists but since we want to 
                # check the name method try at least to get a real object_id
                if {[catch {db_0or1row check_exists "select $id_column as __pk from $table_name limit 1"} errMsg]} { 
                    aa_log_result fail "Type $object_type: select $id_column from $table_name failed:\n$errMsg"
                }
            }
        }

        if {![string is space $name_method]} {
            if {![string eq [string tolower $name_method] $name_method]} {
                aa_log_result fail "Type $object_type: name method $name_method mixed case"
            }
            set name_method [string tolower $name_method]
            if {[string is integer -strict $__pk]} {
                # intentionally don't use bind variables here which is ok 
                # since we just checked __pk was an integer
                if { [catch {db_0or1row name_method "select ${name_method}($__pk) as NAME from dual"} errMsg] } { 
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
    Check that the object type tables exist and that th

    @author Jeff Davis davis@xarg.net
} {
    array set allow_types {
        string {TEXT VARCHAR CHAR}
        boolean {BOOL INT2 INT4}
        number {NUMERIC INT2 INT4 INT8 FLOAT4 FLOAT8}
        integer {INT2 INT4 INT8}
        money {NUMERIC FLOAT4 FLOAT8}
        timestamp {TIMESTAMPTZ}
        time_of_day {TIMESTAMPTZ}
        enumeration {INT2 INT4 INT8}
        url {VARCHAR TEXT}
        email {VARCHAR TEXT}
        text  {VARCHAR TEXT CLOB}
        keyword {CHAR VARCHAR TEXT}
    }

    db_foreach attribute {select a.*, lower(ot.table_name) as obj_type_table from acs_attributes a, acs_object_types ot where ot.object_type = a.object_type order by object_type} {

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
