ad_library {

    An API for managing database queries.

    @creation-date 15 Apr 2000
    @author Jon Salz (jsalz@arsdigita.com)
    @cvs-id $Id$
}


# TODO: The multi-db work below is incomplete.  Using the default
# database should work the same as it always has in OpenACS, but using
# the new -dbn switch will give errors in many cases.  See below under
# BUGS: --atp@piskorski.com, 2003/03/17 14:27 EST

# As originally released in (at least) ACS 4.2 through OpenACS 4.6,
# this DB API supported only a single, default database.  You could
# define any number of different database drivers and pools in
# AOLserver, but could only use ONE database here.
#
# I have eliminated this restriction.  Now, in OpenACS 4.7 and later,
# to access a non-default database, simply pas the optional -dbn
# (Database Name) switch to any of the DB API procs which support it.
#
# BUGS, and Other Limitations and Caveats:
#
#   - Currently, using the -dbn switch to access any database which
# uses a different driver than the default database will fail, because
# there are separte Oracle and PostgreSQL implementations of db_exec,
# and db_exec is used for basica stuff like db_string, etc.  Argh.
# --atp@piskorski.com, 2003/03/17 14:27 EST
#
# Note that -dbn specifies a "Database Name", NOT a database pool!
#
# I could have provided access to secondary databases via a -pool
# rather than a -dbn switch, but chose not to, as the existing DB API
# already had the nicely general feature that if you try to do nested
# queries, the DB API will transparently grab a second database handle
# from another pool to make it work.  You can nest your queries as
# many levels deep as you have database pools defined for that
# database.  So, the existing API essentially already supported the
# notion of "binning" database pools into logical "databases", it just
# didn't provide any way to define more than the single, default
# database!  Thus I chose to preserve this "binning" by specifying
# databases via the -dbn switch rather than database pools via a -pool
# switch.
#
# To define what databases exist, and what pools belong to what
# databases, you need to put something like this in your nsd.tcl
# AOLserver config file:
#
#   ns_section ns/server/$server_name/acs/database
#     ns_param databases  [list ora pg foo]
#     ns_param pools_ora  [list main subquery log]
#     ns_param pools_pg   [list pg-main pg-subquery pg-log]
#     ns_param pools_foo  [list foo1 foo2]
#

# Note that the FIRST database listed in the databases parameter - in
# this case 'ora' - becomes the default database, used for all normal
# OpenACS transactions!
#
# Note also that since each database is just a logical bucket for
# holding database pools, you are free to do weird stuff like assign
# the same pool to more than one database, or define more than one
# logical database for a single real, physical database.
#
# --atp@piskorski.com, 2003/03/16 21:30 EST


# We now use the following global variables:
#
# Server-Global variables:
#   One nsv array:
#     db_default_database .
#   One nsv array per Database Name:
#     db_available_pools $dbn
#     db_driver_type_is $dbn
#
# Thread-Global variables:
#   One Tcl array per Database Name:
#     db_state_${dbn}
#
# The db_available_pools and db_state arrays are used in exactly the
# same manner as they were before, except that in the original DB API
# we had only one of each array total, while now we have one of each
# array per database.
#
# We use the procs db_state_array_name_is, db_available_pools, and
# db_driver_type_is to help keep track of these different arrays.
# Note that most code should now NEVER read from any of the
# db_available_pools nsvs listed above, but should instead use the
# proc db_available_pools provided for that purpose.
#
# The original implementation comments on the use of these global
# variables are below:
#
# --atp@piskorski.com, 2003/03/16 21:30 EST


# Old comments, from before adding the above multi-db support:
# --atp@piskorski.com, 2003/03/16 21:31 EST

# NSV db_pooled_sequences($sequence) is the number of sequence values for the
#     sequence named $sequence that should be pooled.
# NSV db_pooled_nextvals($sequence) is a list of available sequence values for
#     the sequence named $sequence. It is a ring buffer (values are added to the
#     end and popped from the beginning).
# NSV db_pooled_nextvals(.mutex) is a mutex guarding the db_pooled_nextvals.

# global db_state(handles) is a list of handles that have been allocated.
#
# global db_state(n_handles_used) is the number of handles in this list that are
# presently in use.
#
# E.g.:
#
#        db_foreach statement_name "select ..." {
#            # $db_state(handles) is "nsdb1"; $db_state(n_handles_used) is 1
#            db_foreach statement_name "select ..." {
#                # $db_state(handles) is "nsdb1 nsdb2"; $db_state(n_handles_used) is 2
#            }
#            # $db_state(handles) is "nsdb1 nsdb2"; $db_state(n_handles_used) is 1
#            db_release_unused_handles
#            # $db_state(handles) is "nsdb1"; $db_state(n_handles_used) is 1
#        }
#        # $db_state(handles) is "nsdb1"; $db_state(n_handles_used) is 0
#        db_release_unused_handles
#        # $db_state(handles) is ""; $db_state(n_handles_used) is 0
#
# The list of available pools are stored in the nsv db_available_pools(.) = { pool1 pool2 pool3 }
#
# This list is defined in the [ns/server/yourserver/acs/database] section using the key
# AvailablePool=foo (one line per pool).
#
# If none are specified, it defaults to all the pools available to AOLserver.


ad_proc -private db_state_array_name_is {{ -dbn "" }} {
    Returns the name of the global db_state array for the given
    database name.

    @param dbn The database name to use.  If empty_string, uses the
    default database.

    @author Andrew Piskorski (atp@piskorski.com)
    @creation-date 2003/03/16
} {
    if { [empty_string_p $dbn] } {
        set dbn [nsv_get {db_default_database} .]
    }
    return "db_state_${dbn}"
}


proc_doc db_type { } {
    Returns the RDBMS type (i.e. oracle, postgresql) this OpenACS installation is
    using.  The nsv ad_database_type is set up during the bootstrap process.
} {
    # Currently this should always be either "oracle" or "postgresql":
    # --atp@piskorski.com, 2003/03/16 22:01 EST

    return [nsv_get ad_database_type .]
}

ad_proc db_compatible_rdbms_p { db_type } {
    Returns 1 if the given db_type is compatible with the current RDBMS.  
} {
    return [expr { [empty_string_p $db_type] || [string equal [db_type] $db_type] }]
}

ad_proc -deprecated db_package_supports_rdbms_p { db_type_list } {
    Returns 1 if db_type_list contains the current RDMBS type.  A package
    intended to run with a given RDBMS must note this in it's package info
    file regardless of whether or not it actually uses the database. 

    @see apm_package_supports_rdbms_p
} {
    if { [lsearch $db_type_list [db_type]] != -1 } {
        return 1
    }

    # DRB: Legacy package check - we allow installation of old aD Oracle 4.2 packages,
    # though we don't guarantee that they work.

    if { [db_type] == "oracle" && [lsearch $db_type_list "oracle-8.1.6"] != -1 } {
        return 1
    }

    return 0
}

ad_proc db_legacy_package_p { db_type_list } {
    Returns 1 if the package is a legacy package.  We can only tell for certain if
    it explicitly supports Oracle 8.1.6 rather than the OpenACS more general oracle.
} {
    if { [lsearch $db_type_list "oracle-8.1.6"] != -1 } {
        return 1
    }
    return 0
}

proc_doc db_version { } {
    Returns the RDBMS version (i.e. 8.1.6 is a recent Oracle version; 7.1 a
    recent PostgreSQL version.
} {
    return [nsv_get ad_database_version .]
}

proc_doc db_current_rdbms { } {
    Returns the current rdbms type and version.
} {
    return [db_rdbms_create [db_type] [db_version]]
}

proc_doc db_known_database_types { } {
    Returns a list of three-element lists describing the database engines known
    to OpenACS.  Each sublist contains the internal database name (used in file
    paths, etc), the driver name, and a "pretty name" to be used in selection
    forms displayed to the user.

    The nsv containing the list is initialized by the bootstrap script and should
    never be referenced directly by user code.
} {
    return [nsv_get ad_known_database_types .]
}

proc_doc db_null { } {
    Returns an empty string, which Oracle thinks is null.  This routine was
    invented to provide an RDBMS-specific null value but doesn't actually
    work.  I (DRB) left it in to speed porting - we should really clean up
    the code an pull out the calls instead, though.
} {
    return ""
}

proc_doc db_quote { string } { Quotes a string value to be placed in a SQL statement. } {
    regsub -all {'} "$string" {''} result
    return $result
}


ad_proc db_nth_pool_name {{ -dbn "" } n } { 
    Returns the name of the pool used for the nth-nested selection (0-relative). 

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    set available_pools [db_available_pools -dbn $dbn]

    if { $n < [llength $available_pools] } {
	set pool [lindex $available_pools $n]
    } else {
	return -code error "Ran out of database pools ($available_pools)"
    }
    return $pool
}


ad_proc db_with_handle {{ -dbn "" } db code_block } {

    Places a usable database handle in $db and executes $code_block.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar 1 $db dbh
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    # Initialize bookkeeping variables.
    if { ![info exists db_state(handles)] } {
	set db_state(handles) [list]
    }
    if { ![info exists db_state(n_handles_used)] } {
	set db_state(n_handles_used) 0
    }
    if { $db_state(n_handles_used) >= [llength $db_state(handles)] } {
	set pool [db_nth_pool_name -dbn $dbn $db_state(n_handles_used)]
	set start_time [clock clicks]
	set errno [catch {
	    set db [ns_db gethandle $pool]
	} error]
	ad_call_proc_if_exists ds_collect_db_call $db gethandle "" $pool $start_time $errno $error
	lappend db_state(handles) $db
	if { $errno } {
	    global errorInfo errorCode
	    return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
	}
    }
    set my_dbh [lindex $db_state(handles) $db_state(n_handles_used)]
    set dbh $my_dbh
    set db_state(last_used) $my_dbh

    incr db_state(n_handles_used)
    set errno [catch { uplevel 1 $code_block } error]
    incr db_state(n_handles_used) -1

    # This may have changed while the code_block was being evaluated.
    set db_state(last_used) $my_dbh

    # Unset dbh, so any subsequence use of this variable will bomb.
    if { [info exists dbh] } {
	unset dbh
    }


    # If errno is 1, it's an error, so return errorCode and errorInfo;
    # if errno = 2, it's a return, so don't try to return errorCode/errorInfo
    # errno = 3 or 4 give undefined results
    
    if { $errno == 1 } {
	
	# A real error occurred
	global errorInfo errorCode
	return -code $errno -errorcode $errorCode -errorinfo $errorInfo $error
    }
    
    if { $errno == 2 } {
	
	# The code block called a "return", so pass the message through but don't try
	# to return errorCode or errorInfo since they may not exist
	
	return -code $errno $error
    }
}


ad_proc db_release_unused_handles {{ -dbn "" }} {

    Releases any database handles that are presently unused.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    if { [info exists db_state(n_handles_used)] } {
	# Examine the elements at the end of db_state(handles), killing off
	# handles that are unused and not engaged in a transaction.

	set index_to_examine [expr { [llength $db_state(handles)] - 1 }]
	while { $index_to_examine >= $db_state(n_handles_used) } {
	    set db [lindex $db_state(handles) $index_to_examine]

	    # Stop now if the handle is part of a transaction.
	    if { [info exists db_state(transaction_level,$db)] && \
		     $db_state(transaction_level,$db) > 0 } {
		break
	    }

	    set start_time [clock clicks]
	    ns_db releasehandle $db
	    ad_call_proc_if_exists ds_collect_db_call $db releasehandle "" "" $start_time 0 ""
	    incr index_to_examine -1
	}
	set db_state(handles) [lrange $db_state(handles) 0 $index_to_examine]
    }
}


ad_proc -private db_getrow { db selection } {

    A helper procedure to perform an ns_db getrow, invoking developer support
    routines as necessary.

} {
    set start_time [clock clicks]
    set errno [catch { return [ns_db getrow $db $selection] } error]
    ad_call_proc_if_exists ds_collect_db_call $db getrow "" "" $start_time $errno $error
    if { $errno == 2 } {
	return $error
    }
    global errorInfo errorCode
    return -code $errno -errorinfo $errorInfo -errorcode $errorCode $error
}


ad_proc db_string {{ -dbn "" } statement_name sql args } {

    Usage: <b>db_string</b> <i>statement-name sql</i> [ <tt>-default</tt> <i>default</i> ] [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]
  
    <p>Returns the first column of the result of the SQL query $sql.
    If the query doesn't return a row, returns $default (or raises an error if no $default is provided).

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    # Query Dispatcher (OpenACS - ben)
    set full_name [db_qd_get_fullname $statement_name]

    ad_arg_parser { default bind } $args

    db_with_handle -dbn $dbn db {
	set selection [db_exec 0or1row $db $full_name $sql]
    }

    if { [empty_string_p $selection] } {
	if { [info exists default] } {
	    return $default
	}
	return -code error "Selection did not return a value, and no default was provided"
    }
    return [ns_set value $selection 0]
}


ad_proc db_list {{ -dbn "" } statement_name sql args } {

    Usage: <b>db_list</b> <i>statement-name sql</i> [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]
    
    <p>Returns a Tcl list of the values in the first column of the result of SQL query <tt>sql</tt>. 
    If <tt>sql</tt> doesn't return any rows, returns an empty list. Analogous to <tt>database_to_tcl_list</tt>.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args

    # Query Dispatcher (OpenACS - SDW)
    set full_statement_name [db_qd_get_fullname $statement_name]

    # Can't use db_foreach here, since we need to use the ns_set directly.
    db_with_handle -dbn $dbn db {
	set selection [db_exec select $db $full_statement_name $sql]
	set result [list]
	while { [db_getrow $db $selection] } {
	    lappend result [ns_set value $selection 0]
	}
    }
    return $result
}


ad_proc db_list_of_lists {{ -dbn "" } statement_name sql args } {

    Usage: <b>db_list_of_lists</b> <i>statement-name sql</i> [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]

    <p>Returns a Tcl list, each element of which is a list of all column 
    values in a row of the result of the SQL query<tt>sql</tt>. If 
    <tt>sql</tt> doesn't return any rows, returns an empty list. 
    Analogous to <tt>database_to_tcl_list_list</tt>.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args

    # Query Dispatcher (OpenACS - SDW)
    set full_statement_name [db_qd_get_fullname $statement_name]

    # Can't use db_foreach here, since we need to use the ns_set directly.
    db_with_handle -dbn $dbn db {
	set selection [db_exec select $db $full_statement_name $sql]

	set result [list]

	while { [db_getrow $db $selection] } {
	    set this_result [list]
	    for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		lappend this_result [ns_set value $selection $i]
	    }
	    lappend result $this_result
	}
    }
    return $result
}


ad_proc -public db_list_of_ns_sets {
    { -dbn "" }
    statement_name
    sql
    args
} {
    Usage: <b>db_list_of_ns_sets</b> <i>statement-name sql</i> [ <tt>-bind</tt> <i>bind_set_id</i> | <tt>-bind</tt> <i>bind_value_list</i> ]

    <p>Returns a list of ns_sets with the values of each column of each row
    returned by the sql query specified.

    @param statement_name The name of the query.
    @param sql The SQL to be executed.
    @param args Any additional arguments.

    @return list of ns_sets, one per each row return by the SQL query

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind } $args

    set full_statement_name [db_qd_get_fullname $statement_name]

    db_with_handle -dbn $dbn db {
        set result [list]
        set selection [db_exec select $db $full_statement_name $sql]

        while {[db_getrow $db $selection]} {
            lappend result [ns_set copy $selection]
        }
    }

    return $result
}


ad_proc db_foreach {{ -dbn "" } statement_name sql args } {

    Usage: 
    <blockquote>
    db_foreach <em><i>statement-name sql</i></em> [ -bind <em><i>bind_set_id</i></em> | -bind <em><i>bind_value_list</i></em> ] \
        [ -column_array <em><i>array_name</i></em> | -column_set <em><i>set_name</i></em> ] \
	    <em><i>code_block</i></em> [ if_no_rows <em><i>if_no_rows_block</i> ]</em>

    </blockquote>

    <p>Performs the SQL query <em><i><tt>sql</tt></i></em>, executing
    <em><i><tt>code_block</tt></i></em> once for each row with variables set to
    column values (or a set or array populated if <tt>-column_array</tt> or
    <tt>column_set</tt> is specified). If the query returns no rows, executes
    <em><i><tt>if_no_rows_block</tt></i></em> (if provided). </p>

    <p>Example:

    <blockquote><pre>db_foreach greeble_query "select foo, bar from greeble" {
	ns_write "&lt;li&gt;foo=$foo; bar=$bar\n"
    } if_no_rows {
	# This block is optional.
	ns_write "&lt;li&gt;No greebles!\n"
    }</pre></blockquote>

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    ad_arg_parser { bind column_array column_set args } $args

    # Do some syntax checking.
    set arglength [llength $args]
    if { $arglength == 1 } {
	# Have only a code block.
	set code_block [lindex $args 0]
    } elseif { $arglength == 3 } {
	# Should have code block + if_no_rows + code block.
	if { ![string equal [lindex $args 1] "if_no_rows"] && ![string equal [lindex $args 1] "else"] } {
	    return -code error "Expected if_no_rows as second-to-last argument"
	}
	set code_block [lindex $args 0]
	set if_no_rows_code_block [lindex $args 2]
    } else {
	return -code error "Expected 1 or 3 arguments after switches"
    }

    if { [info exists column_array] && [info exists column_set] } {
	return -code error "Can't specify both column_array and column_set"
    }

    if { [info exists column_array] } {
	upvar 1 $column_array array_val
    }

    if { [info exists column_set] } {
	upvar 1 $column_set selection
    }

    db_with_handle -dbn $dbn db {
	set selection [db_exec select $db $full_statement_name $sql]

	set counter 0
	while { [db_getrow $db $selection] } {
	    incr counter
	    if { [info exists array_val] } {
		unset array_val
	    }
	    if { ![info exists column_set] } {
		for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		    if { [info exists column_array] } {
			set array_val([ns_set key $selection $i]) [ns_set value $selection $i]
		    } else {
			upvar 1 [ns_set key $selection $i] column_value
			set column_value [ns_set value $selection $i]
		    }
		}
	    }
	    set errno [catch { uplevel 1 $code_block } error]

	    # Handle or propagate the error. Can't use the usual "return -code $errno..." trick
	    # due to the db_with_handle wrapped around this loop, so propagate it explicitly.
	    switch $errno {
		0 {
		    # TCL_OK
		}
		1 {
		    # TCL_ERROR
		    global errorInfo errorCode
		    error $error $errorInfo $errorCode
		}
		2 {
		    # TCL_RETURN
		    error "Cannot return from inside a db_foreach loop"
		}
		3 {
		    # TCL_BREAK
		    ns_db flush $db
		    break
		}
		4 {
		    # TCL_CONTINUE - just ignore and continue looping.
		}
		default {
		    error "Unknown return code: $errno"
		}
	    }
	}
	# If the if_no_rows_code is defined, go ahead and run it.
	if { $counter == 0 && [info exists if_no_rows_code_block] } {
	    uplevel 1 $if_no_rows_code_block
	}
    }
}


ad_proc -public db_multirow {
    -local:boolean
    -append:boolean
    {-upvar_level 1}
    {-extend {}}
    {-dbn ""}
    var_name
    statement_name
    sql
    args 
} {
    @param dbn The database name to use.  If empty_string, uses the default database.

   Usage:
    <blockquote>
    db_multirow [ -local ] [ -upvar_level <em><i>n_levels_up</i></em> ] [ -append ] [ -extend <em><i>column_list</i></em> ] \
        <em><i>var-name statement-name sql</i></em> [ -bind <em><i>bind_set_id</i></em> | -bind <em><i>bind_value_list</i></em> ] \
	<em><i>code_block</i></em> [ if_no_rows <em><i>if_no_rows_block</i> ]</em>

    </blockquote>

    <p>Performs the SQL query <code>sql</code>, saving results in variables
    of the form
    <code><i>var_name</i>:1</code>, <code><i>var_name</i>:2</code>, etc,
    setting <code><i>var_name</i>:rowcount</code> to the total number
    of rows, and setting <code><i>var_name</i>:columns</code> to a
    list of column names. 

    <p>
    
    Each row also has a column, rownum, automatically 
    added and set to the row number, starting with 1. Note that this will
    override any column in the SQL statement named 'rownum', also if you're
    using the Oracle rownum pseudo-column.
    
    <p>
    If the <code>-local</code> is passed, the variables defined                                                            
    by db_multirow will be set locally (useful if you're compiling dynamic templates                                                           
    in a function or similar situations). Use the <code>-upvar_level</code>
    switch to specify how many levels up the variable should be set.

    <p>

    You may supply a code block, which will be executed for each row in 
    the loop. This is very useful if you need to make computations that 
    are better done in Tcl than in SQL, for example using ns_urlencode 
    or ad_quotehtml, etc. When the Tcl code is executed, all the columns 
    from the SQL query will be set as local variables in that code. Any
    changes made to these local variables will be copied back into the
    multirow.

    <p>

    You may also add additional, computed columns to the multirow, using the
    <code>-extend { <i>col_1</i> <i>col_2</i> ... }</code> switch. This is 
    useful for things like constructing a URL for the object retrieved by 
    the query.

    <p>

    If you're constructing your multirow through multiple queries with the 
    same set of columns, but with different rows, you can use the 
    <code>-append</code> switch. This causes the rows returned by this query
    to be appended to the rows already in the multirow, instead of starting
    a clean multirow, as is the normal behavior. The columns must match the
    columns in the original multirow, or an error will be thrown.

    <p>

    Your code block may call <code>continue</code> in order to skip a row 
    and not include it in the multirow. Or you can call <code>break</code>
    to skip this row and quit looping.

    <p>

    Notice the nonstandard numbering (everything
    else in Tcl starts at 0); the reason is that the graphics designer, a non
    programmer, may wish to work with row numbers.

    <p>

    Example: 
<pre>db_multirow -extend { user_url } users users_query {
    select user_id first_names, last_name, email from cc_users
} {
    set user_url [acs_community_member_url -user_id $user_id]
}</pre>

   @see template::multirow
} {
    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { $local_p } {
        set level_up $upvar_level
    } else {
        set level_up \#[template::adp_level]
    }

    ad_arg_parser { bind args } $args

    # Do some syntax checking.
    set arglength [llength $args]
    if { $arglength == 0 } {
	# No code block.
	set code_block ""
    } elseif { $arglength == 1 } {
	# Have only a code block.
	set code_block [lindex $args 0]
    } elseif { $arglength == 3 } {
	# Should have code block + if_no_rows + code block.
	if {   ![string equal [lindex $args 1] "if_no_rows"] \
	    && ![string equal [lindex $args 1] "else"] } {
	    return -code error "Expected if_no_rows as second-to-last argument"
	}
	set code_block [lindex $args 0]
	set if_no_rows_code_block [lindex $args 2]
    } else {
	return -code error "Expected 1 or 3 arguments after switches"
    }
    
    upvar $level_up "$var_name:rowcount" counter
    upvar $level_up "$var_name:columns" columns

    if { !$append_p || ![info exists counter]} {
	set counter 0
    } 

    db_with_handle -dbn $dbn db {
	set selection [db_exec select $db $full_statement_name $sql]
        set local_counter 0

	while { [db_getrow $db $selection] } {
            
            if { $local_counter == 0 } {
                for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
                    lappend local_columns [ns_set key $selection $i]
                }
                set local_columns [concat $local_columns $extend]
                if { !$append_p || ![info exists columns] } {
                    # store the list of columns in the var_name:columns variable
                    set columns $local_columns
                } else {
                    # Check that the columns match, if not throw an error
                    if { ![string equal [join [lsort -ascii $local_columns]] [join [lsort -ascii $columns]]] } {
                        error "Appending to a multirow with differing columns.
Original columns     : [join [lsort -ascii $columns] ", "].
Columns in this query: [join [lsort -ascii $local_columns] ", "]" "" "ACS_MULTIROW_APPEND_COLUMNS_MISMATCH"
                    }
                }
            }

	    if { [empty_string_p $code_block] } {
		# No code block - pull values directly into the var_name array.
	        upvar $level_up "$var_name:[expr {$counter+1}]" array_val
		for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		    set array_val([ns_set key $selection $i]) \
			[ns_set value $selection $i]
		}
	    } else {
		# Pull values from the query into local variables
		for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
		    upvar 1 [ns_set key $selection $i] column_value
		    set column_value [ns_set value $selection $i]
		}

                # Initialize the "extend" columns to the empty string
                foreach column_name $extend {
		    upvar 1 $column_name column_value
		    set column_value ""
                }
                
                # Execute the code block
		set errno [catch { uplevel 1 $code_block } error]

		# Handle or propagate the error. Can't use the usual
		# "return -code $errno..." trick due to the db_with_handle
		# wrapped around this loop, so propagate it explicitly.
		switch $errno {
		    0 {
			# TCL_OK
		    }
		    1 {
			# TCL_ERROR
			global errorInfo errorCode
			error $error $errorInfo $errorCode
		    }
		    2 {
			# TCL_RETURN
			error "Cannot return from inside a db_multirow loop"
		    }
		    3 {
			# TCL_BREAK
			ns_db flush $db
			break
		    }
		    4 {
			# TCL_CONTINUE
			continue
		    }
		    default {
			error "Unknown return code: $errno"
		    }
		}

		# Pull the local variables back out and into the array.
		upvar $level_up "$var_name:[expr {$counter + 1}]" array_val
		foreach column_name $columns {
		    upvar 1 $column_name column_value
		    set array_val($column_name) $column_value
		}
	    }
	    incr counter
            incr local_counter
	    set array_val(rownum) $counter
	}
    }

    # If the if_no_rows_code is defined, go ahead and run it.
    if { $counter == 0 && [info exists if_no_rows_code_block] } {
	uplevel 1 $if_no_rows_code_block
    }
}


ad_proc db_0or1row {{ -dbn "" } statement_name sql args } { 

    Usage: 
    <blockquote>
    db_0or1row <i>statement-name sql</i> [ -bind <i>bind_set_id</i> | -bind <i>bind_value_list</i> ] \
        [ -column_array <i>array_name</i> | -column_set <i>set_name</i> ]
	
    </blockquote>

    <p>Performs the SQL query sql. If a row is returned, sets variables 
    to column values (or a set or array populated if -column_array 
    or column_set is specified) and returns 1. If no rows are returned, 
    returns 0. If more than one row is returned, throws an error.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    ad_arg_parser { bind column_array column_set } $args

    # Query Dispatcher (OpenACS - ben)
    set full_statement_name [db_qd_get_fullname $statement_name]

    if { [info exists column_array] && [info exists column_set] } {
	return -code error "Can't specify both column_array and column_set"
    }

    if { [info exists column_array] } {
	upvar 1 $column_array array_val
	if { [info exists array_val] } {
	    unset array_val
	}
    }

    if { [info exists column_set] } {
	upvar 1 $column_set selection
    }

    db_with_handle -dbn $dbn db {
	set selection [db_exec 0or1row $db $full_statement_name $sql]
    }
    
    if { [empty_string_p $selection] } {
	return 0
    }

    if { [info exists column_array] } {
	for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
	    set array_val([ns_set key $selection $i]) [ns_set value $selection $i]
	}
    } elseif { ![info exists column_set] } {
	for { set i 0 } { $i < [ns_set size $selection] } { incr i } {
	    upvar 1 [ns_set key $selection $i] value
	    set value [ns_set value $selection $i]
	}
    }

    return 1
}


ad_proc db_1row { args } {
    Usage: 
    <blockquote>
    db_1row <i>statement-name sql</i> [ -bind <i>bind_set_id</i> | -bind <i>bind_value_list</i> ] \
        [ -column_array <i>array_name</i> | -column_set <i>set_name</i> ]
	
    </blockquote>

    <p>Performs the SQL query sql. If a row is returned, sets variables 
    to column values (or a set or array populated if -column_array 
    or column_set is specified). If no rows are returned, 
    throws an error.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    if { ![uplevel db_0or1row $args] } {
	return -code error "Query did not return any rows."
    }
}


ad_proc db_transaction {{ -dbn ""} transaction_code args } {
    Usage: <b><i>db_transaction</i></b> <i>transaction_code</i> [ on_error { <i>error_code_block</i> } ]
    
    Executes transaction_code with transactional semantics.  This means that either all of the database commands
    within transaction_code are committed to the database or none of them are.  Multiple <code>db_transaction</code>s may be
    nested (end transaction is transparently ns_db dml'ed when the outermost transaction completes).<p>

    To handle errors, use <code>db_transaction {transaction_code} on_error {error_code_block}</code>.  Any error generated in 
    <code>transaction_code</code> will be caught automatically and process control will transfer to <code>error_code_block</code>
    with a variable <code>errmsg</code> set.  The error_code block can then clean up after the error, such as presenting a usable
    error message to the user.  Following the execution of <code>error_code_block</code> the transaction will be aborted.
    If you want to explicity abort the transaction, call <code>db_abort_transaction</code>
    from within the transaction_code block or the error_code block.<p>

    Example 1:<br>
    In this example, db_dml triggers an error, so control passes to the on_error block which prints a readable error.
    <pre>
    db_transaction {
	db_dml test "nonsense"
    } on_error {
        ad_return_error "Error in blah/foo/bar" "The error was: $errmsg"
    }
    </pre>

    Example 2:<br>
    In this example, the second command, "nonsense" triggers an error.  There is no on_error block, so the
    transaction is immediately halted and aborted.
    <pre>
    db_transaction {
	db_dml test {insert into footest values(1)}
	nonsense
	db_dml test {insert into footest values(2)}
    } 
    </pre>

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state
    
    set syn_err "db_transaction: Invalid arguments. Use db_transaction { code } \[on_error { error_code_block }\] "
    set arg_c [llength $args]
    
    if { $arg_c != 0 && $arg_c != 2 } {
	# Either this is a transaction with no error handling or there must be an on_error { code } block.
	error $syn_err
    }  elseif { $arg_c == 2 } {
	# We think they're specifying an on_error block
	if { [string compare [lindex $args 0] "on_error"] } {
	    # Unexpected: they put something besides on_error as a connector.
	    error $syn_err
	} else {
	    # Success! We got an on_error code block.
	    set on_error [lindex $args 1]
	}
    }
    # Make the error message and database handle available to the on_error block.
    upvar errmsg errmsg
    
    db_with_handle -dbn $dbn db {
	# Preserve the handle, since db_with_handle kills it after executing
	# this block.
	set dbh $db	
	# Remember that there's a transaction happening on this handle.
	if { ![info exists db_state(transaction_level,$dbh)] } {
	    set db_state(transaction_level,$dbh) 0
	}
	set level [incr db_state(transaction_level,$dbh)]
	if { $level == 1 } {
	    ns_db dml $dbh "begin transaction"
	}
    }
    # Execute the transaction code.
    set errno [catch {
	uplevel 1 $transaction_code 
    } errmsg]
    incr db_state(transaction_level,$dbh) -1
    
    set err_p 0
    switch $errno {
	0 {
	    # TCL_OK
	}
	2 {
	    # TCL_RETURN
	}
	3 {
	    # TCL_BREAK - Abort the transaction and do the break.
	    ns_db dml $dbh "abort transaction"
	    db_release_unused_handles -dbn $dbn
	    break
	}
	4 {
	    # TCL_CONTINUE - just ignore.
	}
	default {
	    # TCL_ERROR or unknown error code: Its a real error.
	    set err_p 1
	}
    }

    if { $err_p || [db_abort_transaction_p]} {
	# An error was triggered or the transaction has been aborted.  
	db_abort_transaction
	if { [info exists on_error] && ![empty_string_p $on_error] } {
	    # An on_error block exists, so execute it.
            if {[string equal postgresql [db_type]]} { 
                # JCD: with postgres we abort the transaction prior to 
                # executing the on_error block since there is nothing 
                # you can do to "fix it" and keeping it meant things like 
                # queries in the on_error block would then fail.
                # 
                # Note that the semantics described in the proc doc 
                # are not possible to support on postresql.
                ns_db dml $dbh "abort transaction"
                db_release_unused_handles
            }
	    set errno  [catch {
		uplevel 1 $on_error
	    } on_errmsg]
	    # Determine what do with the error.
	    set err_p 0
	    switch $errno {
		0 {
		    # TCL_OK
		}
		
		2 {
		    # TCL_RETURN
		}
		3 {
		    # TCL_BREAK
		    ns_db dml $dbh "abort transaction"
		    db_release_unused_handles
		    break
		}
		4 {
		    # TCL_CONTINUE - just ignore.
		}
		default {
		    # TCL_ERROR or unknown error code: Its a real error.
		    set err_p 1
		}
	    }

	    if { $err_p } {
		# An error was generated from the $on_error block.
		if { $level == 1} {
		    # We're at the top level, so we abort the transaction.
		    set db_state(db_abort_p,$dbh) 0
		    ns_db dml $dbh "abort transaction"
		} 
		# We throw this error because it was thrown from the error handling code that the programmer must fix.
		global errorInfo errorCode
		error $on_errmsg $errorInfo $errorCode
	    } else {
		# Good, no error thrown by the on_error block.
		if [db_abort_transaction_p] {
		    # This means we should abort the transaction.
		    if { $level == 1 } {
			set db_state(db_abort_p,$dbh) 0
			ns_db dml $dbh "abort transaction"
			# We still have the transaction generated error.  We don't want to throw it, so we log it.
			ns_log Error "Aborting transaction due to error:\n$errmsg" 
		    } else {
			# Propagate the error up to the next level.
			global errorInfo errorCode
			error $errmsg $errorInfo $errorCode
		    }
		} else {
		    # The on_error block has resolved the transaction error.  If we're at the top, commit and exit.
		    # Otherwise, we continue on through the lower transaction levels.
		    if { $level == 1} {
			ns_db dml $dbh "end transaction"
		    }
		}
	    }
	} else {
	    # There is no on_error block, yet there is an error, so we propagate it.
	    if { $level == 1 } {
		set db_state(db_abort_p,$dbh) 0
		ns_db dml $dbh "abort transaction"
		global errorInfo errorCode
		error "Transaction aborted: $errmsg" $errorInfo $errorCode
	    } else {		
		db_abort_transaction
		global errorInfo errorCode
		error $errmsg $errorInfo $errorCode
	    }
	}
    } else {
	# There was no error from the transaction code.   
	if [db_abort_transaction_p] {
	    # The user requested the transaction be aborted.
	    if { $level == 1 } {
		set db_state(db_abort_p,$dbh) 0
		ns_db dml $dbh "abort transaction"
	    } 
	} elseif { $level == 1 } {
	    # Success!  No errors and no requested abort.  Commit.
	    ns_db dml $dbh "end transaction"
	}
    }
}


ad_proc db_abort_transaction {{ -dbn "" }} {
    
    Aborts all levels of a transaction. That is if this is called within 
    several nested transactions, all of them are terminated. Use this 
    instead of db_dml "abort" "abort transaction".

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    db_with_handle -dbn $dbn db {
	# We set the abort flag to true.
	set db_state(db_abort_p,$db) 1
    }
}


ad_proc db_abort_transaction_p {{ -dbn "" }} {
    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    upvar "#0" [db_state_array_name_is -dbn $dbn] db_state

    db_with_handle -dbn $dbn db {
	if { [info exists db_state(db_abort_p,$db)] } { 
	    return $db_state(db_abort_p,$db)
	} else {
	    # No abort flag registered, so we assume everything is ok.
	    return 0
	}
    }
}


ad_proc -public db_name {{ -dbn "" }} {

    Returns the name of the database as reported by the driver.

    @param dbn The database name to use.  If empty_string, uses the default database.
} {
    db_with_handle -dbn $dbn db {
        set dbtype [ns_db dbtype $db]
    }
    return $dbtype
}
