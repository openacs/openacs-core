ad_library {
    Utility procs, e.g. for querying the data dictionary.

    @author Lars Pind (lars@pinds.com)
    @creation-date 8 July 2000
    @cvs-id $Id$
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

ad_proc -public db_type { } {

    Returns the database type

    @author Yon Feldman (yon@arsdigita.com)

} {

    # just while i figure out where to find this in the data dictionary
    return "Oracle8"

}
