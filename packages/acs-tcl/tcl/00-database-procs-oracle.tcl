ad_library {

    Oracle-specific database API and utility procs

    @creation-date 15 Apr 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
}

ad_proc -public db_nullify_empty_string { string } {
    A convenience function that returns [db_null] if $string is the empty string.
} {
    if { [empty_string_p $string] } {
	return [db_null]
    } else {
	return $string
    }
}

proc_doc db_nextval { sequence } { Returns the next value for a sequence. This can utilize a pool of sequence values to save hits to the database. } {
    return [db_string "nextval" "select $sequence.nextval from dual"]
}

proc_doc db_exec_plsql { statement_name sql args } {

    Executes a PL/SQL statement, returning the variable of bind variable <code>:1</code>.

} {
    ad_arg_parser { bind_output bind } $args

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { [info exists bind_output] } {
	return -code error "the -bind_output switch is not currently supported"
    }

    db_with_handle db {
	# Right now, use :1 as the output value if it occurs in the statement,
	# or not otherwise.
        set test_sql [db_qd_replace_sql $full_statement_name $sql]
	if { [regexp {:1} $test_sql] } {
	    return [db_exec exec_plsql_bind $db $full_statement_name $sql 2 1 ""]
	} else {
	    return [db_exec dml $db $full_statement_name $sql]
	}
    }
}

ad_proc -private db_exec { type db statement_name pre_sql {ulevel 2} args } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

} {
    set start_time [clock clicks]

    db_qd_log QDDebug "PRE-QD: the SQL is $pre_sql for $statement_name"

    # Query Dispatcher (OpenACS - ben)
    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert tcl variable values (Openacs - Dan)
    if {![string equal $sql $pre_sql]} {
        set sql [uplevel $ulevel [list subst -nobackslashes $sql]]
    }

    db_qd_log QDDebug "POST-QD: the SQL is $sql"

    set errno [catch {
	upvar bind bind
	if { [info exists bind] && [llength $bind] != 0 } {
	    if { [llength $bind] == 1 } {
		return [eval [list ns_ora $type $db -bind $bind $sql] $args]
	    } else {
		set bind_vars [ns_set create]
		foreach { name value } $bind {
		    ns_set put $bind_vars $name $value
		}
		return [eval [list ns_ora $type $db -bind $bind_vars $sql] $args]
	    }
	} else {
	    return [uplevel $ulevel [list ns_ora $type $db $sql] $args]
	}
    } error]

    ad_call_proc_if_exists ds_collect_db_call $db $type $statement_name $sql $start_time $errno $error
    if { $errno == 2 } {
	return $error
    }

    global errorInfo errorCode
    return -code $errno -errorinfo $errorInfo -errorcode $errorCode $error
}

proc_doc db_dml { statement_name sql args } {
    Do a DML statement.
} {
    ad_arg_parser { clobs blobs clob_files blob_files bind } $args

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    # Only one of clobs, blobs, clob_files, and blob_files is allowed.
    # Remember which one (if any) is provided.
    set lob_argc 0
    set lob_argv [list]
    set command "dml"
    if { [info exists clobs] } {
	set command "clob_dml"
	set lob_argv $clobs
	incr lob_argc
    }
    if { [info exists blobs] } {
	set command "blob_dml"
	set lob_argv $blobs
	incr lob_argc
    }
    if { [info exists clob_files] } {
	set command "clob_dml_file"
	set lob_argv $clob_files
	incr lob_argc
    }
    if { [info exists blob_files] } {
	set command "blob_dml_file"
	set lob_argv $blob_files
	incr lob_argc
    }
    if { $lob_argc > 1 } {
	error "Only one of -clobs, -blobs, -clob_files, or -blob_files may be specified as an argument to db_dml"
    }
    db_with_handle db {
	if { $lob_argc == 1 } {
	    # Bind :1, :2, ..., :n as LOBs (where n = [llength $lob_argv])
	    set bind_vars [list]
	    for { set i 1 } { $i <= [llength $lob_argv] } { incr i } {
		lappend bind_vars $i
	    }
	    eval [list db_exec "${command}_bind" $db $full_statement_name $sql 2 $bind_vars] $lob_argv
	} else {
	    eval [list db_exec $command $db $full_statement_name $sql] $lob_argv
	}
    }
}

proc_doc db_resultrows {} { Returns the number of rows affected by the last DML command. } {
    global db_state
    return [ns_ora resultrows $db_state(last_used)]
}

ad_proc db_write_clob { statement_name sql args } {
    ad_arg_parser { bind } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle db {
	db_exec write_clob $db $full_statement_name $sql
    }
}

ad_proc db_write_blob { statement_name sql args } {
    ad_arg_parser { bind } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle db { 
	db_exec_lob write_blob $db $full_statement_name $sql
    }
}

ad_proc db_blob_get_file { statement_name sql args } {
    ad_arg_parser { bind file args } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle db {
	eval [list db_exec_lob blob_get_file $db $full_statement_name $sql 2 $file] $args
    }
}

ad_proc -private db_exec_lob { type db statement_name pre_sql {ulevel 2} args } {

    A helper procedure to execute a SQL statement, potentially binding
    depending on the value of the $bind variable in the calling environment
    (if set).

} {
    set start_time [clock clicks]

    db_qd_log QDDebug "PRE-QD: the SQL is $pre_sql for $statement_name"

    # Query Dispatcher (OpenACS - ben)
    set sql [db_qd_replace_sql $statement_name $pre_sql]

    # insert tcl variable values (Openacs - Dan)
    if {![string equal $sql $pre_sql]} {
        set sql [uplevel $ulevel [list subst -nobackslashes $sql]]
    }
 
    set file_storage_p 0
    upvar $ulevel storage_type storage_type

    if {[info exists storage_type] && [string equal $storage_type file]} {
        set file_storage_p 1
        set original_type $type
        set qtype 1row
        ns_log Notice "db_exec_lob: file storage in use"
    } else {
        set qtype $type
        ns_log Notice "db_exec_lob: blob storage in use"
    }

    db_qd_log QDDebug "POST-QD: the SQL is $sql"

    set errno [catch {
	upvar bind bind
	if { [info exists bind] && [llength $bind] != 0 } {
	    if { [llength $bind] == 1 } {
		set selection [eval [list ns_ora $qtype $db -bind $bind $sql] $args]
	    } else {
		set bind_vars [ns_set create]
		foreach { name value } $bind {
		    ns_set put $bind_vars $name $value
		}
		set selection [eval [list ns_ora $qtype $db -bind $bind_vars $sql] $args]
	    }
	} else {
	    set selection [uplevel $ulevel [list ns_ora $qtype $db $sql] $args]
	}

        if {$file_storage_p} {
            set content [ns_set value $selection 0]
            for {set i 0} {$i < [ns_set size $selection]} {incr i} {
                set name [ns_set key $selection $i]
                if {[string equal $name content]} {
                    set content [ns_set value $selection $i]
                }
            }

            switch $original_type {

                blob_get_file {
                    if {[file exists $content]} {
                        file copy -- $content $file
                        return $selection
                    } else {
                        error "file: $content doesn't exist"
                    }
                 }

                write_blob {

                    if {[file exists $content]} {
                        set ofp [open $content r]
                        fconfigure $ofp -encoding binary
                        ns_writefp $ofp
                        close $ofp
                        return $selection
                    } else {
                        error "file: $content doesn't exist"
                    }
                }
            }
        } else {
            return $selection
        }

    } error]

    ad_call_proc_if_exists ds_collect_db_call $db $type $statement_name $sql $start_time $errno $error
    if { $errno == 2 } {
	return $error
    }

    global errorInfo errorCode
    return -code $errno -errorinfo $errorInfo -errorcode $errorCode $error
}

ad_proc db_get_sql_user { } {

    Returns a valid user@database/password string to access a database through sqlplus.

} {

    set pool [lindex [nsv_get db_available_pools .] 0]
    set datasource [ns_config ns/db/pool/$pool DataSource]    
    if { ![empty_string_p $datasource] && ![string is space $datasource] } {
	return "[ns_config ns/db/pool/$pool User]/[ns_config ns/db/pool/$pool Password]@$datasource"
    } else {
	return "[ns_config ns/db/pool/$pool User]/[ns_config ns/db/pool/$pool Password]"
    }
}

ad_proc db_source_sql_file { {-callback apm_ns_write_callback} file } {

    Sources a SQL file (in SQL*Plus format).

} {
    
    global env
    set user_pass [db_get_sql_user]
    cd [file dirname $file]
    set fp [open "|[file join $env(ORACLE_HOME) bin sqlplus] $user_pass @$file" "r"]

    while { [gets $fp line] >= 0 } {
	# Don't bother writing out lines which are purely whitespace.
	if { ![string is space $line] } {
	    apm_callback_and_log $callback "[ad_quotehtml $line]\n"
	}
    }
    close $fp
}


ad_proc db_source_sqlj_file { {-callback apm_ns_write_callback} file } {

    Sources a SQLJ file using loadjava.

} {
    
    global env
    set user_pass [db_get_sql_user]
    set fp [open "|[file join $env(ORACLE_HOME) bin loadjava] -verbose -user $user_pass $file" "r"]


    # Despite the fact that this works, the text does not get written to the stream.
    # The output is generated as an error when you attempt to close the input stream as
    # done below.
    while { [gets $fp line] >= 0 } {
	# Don't bother writing out lines which are purely whitespace.
	if { ![string is space $line] } {
	    apm_callback_and_log $callback "[ad_quotehtml $line]\n"
	}
    }
    if { [catch {
	close $fp
    } errmsg] } {
	apm_callback_and_log $callback "[ad_quotehtml $errmsg]\n"
    }
}

ad_proc -public db_tables { -pattern } {
    Returns a Tcl list of all the tables owned by the connected user.
    
    @param pattern Will be used as LIKE 'pattern%' to limit the number of tables returned.

    @author Lars Pind lars@pinds.com

    @change-log yon@arsdigita.com 20000711 changed to return lower case table names
} {
    set tables [list]
    
    if { [info exists pattern] } {
	db_foreach table_names_with_pattern {
	    select lower(table_name) as table_name
	    from user_tables
	    where table_name like upper(:pattern)
	} {
	    lappend tables $table_name
	}
    } else {
	db_foreach table_names_without_pattern {
	    select lower(table_name) as table_name
	    from user_tables
	} {
	    lappend tables $table_name
	}
    }
    return $tables
}


ad_proc -public db_table_exists { table_name } {
    Returns 1 if a table with the specified name exists in the database, otherwise 0.
    
    @author Lars Pind (lars@pinds.com)
} {
    set n_rows [db_string table_count {
	select count(*) from user_tables where table_name = upper(:table_name)
    }]
    return $n_rows
}

ad_proc -public db_columns { table_name } {
    Returns a Tcl list of all the columns in the table with the given name.
    
    @author Lars Pind lars@pinds.com

    @change-log yon@arsdigita.com 20000711 changed to return lower case column names
} {
    set columns [list]
    db_foreach table_column_names {
	select lower(column_name) as column_name
	from user_tab_columns
	where table_name = upper(:table_name)
    } {
	lappend columns $column_name
    }
    return $columns
}


ad_proc -public db_column_exists { table_name column_name } {
    Returns 1 if the row exists in the table, 0 if not.
    
    @author Lars Pind lars@pinds.com
} {
    set columns [list]
    set n_rows [db_string column_exists {
	select count(*) 
	from user_tab_columns
	where table_name = upper(:table_name)
	and column_name = upper(:column_name)
    }]
    return [expr $n_rows > 0]
}


ad_proc -public db_column_type { table_name column_name } {

    Returns the Oracle Data Type for the specified column.
    Returns -1 if the table or column doesn't exist.

    @author Yon Feldman (yon@arsdigita.com)

    @change-log 10 July, 2000: changed to return error
                               if column name doesn't exist  
                               (mdettinger@arsdigita.com)

    @change-log 11 July, 2000: changed to return lower case data types 
                               (yon@arsdigita.com)

    @change-log 11 July, 2000: changed to return error using the db_string default clause
                               (yon@arsdigita.com)

} {

    return [db_string column_type_select "
	select data_type as data_type
	  from user_tab_columns
	 where upper(table_name) = upper(:table_name)
	   and upper(column_name) = upper(:column_name)
    " -default "-1"]

}

ad_proc -public ad_column_type { table_name column_name } {

    Returns 'numeric' for number type columns, 'text' otherwise
    Throws an error if no such column exists.

    @author Yon Feldman (yon@arsdigita.com)

} {

    set column_type [db_column_type $table_name $column_name]

    if { $column_type == -1 } {
	return "Either table $table_name doesn't exist or column $column_name doesn't exist"
    } elseif { [string compare $column_type "NUMBER"] } {
	return "numeric"
    } else {
	return "text"
    }

}
