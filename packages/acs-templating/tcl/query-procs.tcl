ad_library {

    Database Query API for the ArsDigita Templating System

    @creation-date 29 September 2000
    @author Karl Goldstein (karlg@arsdigita.com)
            Stanislav Freidin (sfreidin@arsdigita.com)
    @cvs-id $Id$

}


# Database Query API for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


# (DCW - Openacs) converted template db api to use standard api and hooked it
# into the query-dispatcher.  This ties into the standard db api's 
# transaction control and handle allocation into the templating query interface
# allowing the two db api's to be mixed together. 

# Todo - convert caching to use ns_cache. 

nsv_set __template_query_persistent_cache . .
nsv_set __template_query_persistent_timeout . .


# @public query

# Perform a database query

# @option maxrows    Limits the query results of a multirow query
#                    to a fixed number of rows.
# @option cache      Cache the query results keyed on an identifier
#                    that is unique for both the query and the bind variables
#                    used in the query.  The cached result reflects
#                    any initial specification of maxrows and startrows.
# @option refresh    Force a query to be performed even if it is cached,
#                    and refresh the cache.
#                    Only applicable if the cache option is specified as well.
#                    Does not affect a previously specified timeout period.
# @option timeout    The maximum period of time for which the cached results
#                    are valid in seconds.  Only applicable for
#                    persistently cached results.
# @option persistent Cache the query results persistently, so that
#                    all subsequent requests use the results.

ad_proc -public template::query { statement_name result_name type sql args } {
    Public interface to template query api.  This routine parses the arguements and
    dispatches to the query command specified by the type arguement.

 @option maxrows    Limits the query results of a multirow query
                    to a fixed number of rows.
 @option cache      Cache the query results keyed on an identifier
                    that is unique for both the query and the bind variables
                    used in the query.  The cached result reflects
                    any initial specification of maxrows and startrows.
 @option refresh    Force a query to be performed even if it is cached,
                    and refresh the cache.
                    Only applicable if the cache option is specified as well.
                    Does not affect a previously specified timeout period.
 @option timeout    The maximum period of time for which the cached results
                    are valid in seconds.  Only applicable for
                    persistently cached results.
 @option persistent Cache the query results persistently, so that
                    all subsequent requests use the results.

    @return 1 if query was a success, 0 if it failed
    @param statement_name Standard db_api query name
    @param result_name Tcl variable name when doing an uplevel to set the returned result
    @param type The query type
    @param sql The sql to be used for the query
    @param args Optional args: uplevel, cache, maxrows
} {

  set sql [string trim $sql]
  set full_statement_name [db_qd_get_fullname $statement_name]

  #set beginTime [clock clicks]

  template::util::get_opts $args
  
  if { ! [info exists opts(uplevel)] } {
    set opts(uplevel) 2
  } else {
    set opts(uplevel) [expr 2 + $opts(uplevel)]
  }

  # check the cache for a valid cached query result and return if so
  # otherwise continue to perform the query and cache the results afterwards

  if { [info exists opts(cache)] && [get_cached_result $result_name $type] } { 
    return $opts(result)
  }

  if { ! [info exists opts(maxrows)] } {
    set opts(maxrows) 10000
  }

  db_with_handle db { 
      set ret_code [template::query::$type $full_statement_name $db $result_name $sql] 
  }

  if { [info exists opts(cache)] } {
    
    # cache the query result
    set_cached_result
  }

  #set timeElapsed [expr ([clock clicks] - $beginTime) / 1000]
  #ns_log Notice "Query performed in: $timeElapsed ms"
  
  return $ret_code
}

# @private onevalue

# Process a onevalue query.  Use a single array to store the results.

ad_proc -private template::query::onevalue { statement_name db result_name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command

} {

  upvar opts opts

  upvar $opts(uplevel) $result_name result
  set result ""

  set row [db_exec 0or1row $db $statement_name $sql 3]

  if { $row != "" } {

    # Set the result in the calling frame.
    set result [ns_set value $row 0]

    if { [info exists opts(cache)] } {
      set opts(result) $result
    }
  }
}

# @private onerow

# Process a onerow query.  Use a single array to store the results.

ad_proc -private template::query::onerow { statement_name db result_name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command
} {

  upvar opts opts

  set row [db_exec 0or1row $db $statement_name $sql 3]

  if { $row != "" } {

    # Set the results in the calling frame.
    upvar $opts(uplevel) $result_name result

    set size [ns_set size $row]

    for { set i 0 } { $i < $size } { incr i } {

	set column [ns_set key $row $i]
	set result($column) [ns_set value $row $i]
    }

    if { [info exists opts(cache)] } {
      set opts(result) [array get result]
    }
 
    return 1

  } else {

    return 0
  }
}

# @private multirow

# Process a multirow query.  Use an array for each row row in the
# result.  Arrays are named name0, name1, name2 etc.  The variable
# name.rowcount is also defined for checking and iteration.

ad_proc -private template::query::multirow { statement_name db result_name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command
} {

  upvar opts opts

  set row [db_exec select $db $statement_name $sql 3]

  upvar $opts(uplevel) $result_name:rowcount rowcount $result_name:columns column_list

  # set a local variable as to whether we are cacheing or not
  if { [info exists opts(cache)] } {
    set is_cached 1
    set cached_result [list]
  } else {
    set is_cached 0
  }

  set rowcount 0

  if { [info exists opts(eval)] } {
    # figure out the level at which to reference the row
    set ref_level [expr $opts(uplevel) - 2]
  }

  while { [ns_db getrow $db $row] } {

    incr rowcount
      
    # break if maxrows has been reached
    if { $rowcount > $opts(maxrows) } {
      ns_db flush $db
      upvar $opts(uplevel) ${result_name}:has_more_rows has_more_rows
      set has_more_rows 1
      incr rowcount -1
      break
    }

    # set the results in the calling frame
    upvar $opts(uplevel) ${result_name}:$rowcount result

    set result(rownum) $rowcount

    set size [ns_set size $row]

    for { set i 0 } { $i < $size } { incr i } {

      set column [ns_set key $row $i]
      set result($column) [ns_set value $row $i]

      if {$rowcount == 1 } {
	lappend column_list $column
      }
    }

    # Execute custom code for each row
    if { [info exists opts(eval)] } {
      uplevel $opts(uplevel) "
        upvar 0 ${result_name}:$rowcount row; $opts(eval)
      "
    }

    if { $is_cached } {
      lappend cached_result [array get result]
    }
  }

  if { $is_cached } {
    set opts(result) $cached_result
  }
}

ad_proc -private template::query::multilist { statement_name db result_name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command
} {

  upvar opts opts

  set row [db_exec select $db $statement_name $sql 3]

  upvar $opts(uplevel) $result_name rows

  set rows [list]

  while { [ns_db getrow $db $row] } {

    set values [list]
    set size [ns_set size $row]

    for { set i 0 } { $i < $size } { incr i } {

      lappend values [ns_set value $row $i]
    }

    lappend rows $values
  }

  if { [info exists opts(cache)] } {
    set opts(result) $rows
  }

  return $rows
}

# Creates a data source where the values for each row 
# are returned as a list.  Rows are grouped according
# to the column values specified in the -groupby option
# See template::util::lnest for more details.

ad_proc -private template::query::nestedlist { statement_name db result_name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command
} {

  upvar opts opts

  set row [db_exec select $db $statement_name $sql 3]

  upvar $opts(uplevel) $result_name rows
  
  set groups $opts(groupby)

  set rows [list]

  while { [ns_db getrow $db $row] } {

    set values [list]
    set size [ns_set size $row]

    for { set i 0 } { $i < $size } { incr i } {

      lappend values [ns_set value $row $i]
    }

    # build the values on which to group
    set group_values [list]
    foreach group $groups {
      lappend group_values [ns_set get $row $group]
    }

    eval template::util::lnest rows [list $values] $group_values
  }

  if { [info exists opts(cache)] } {
    set opts(result) $rows
  }

  return $rows
}

ad_proc -private template::query::onelist { statement_name db result_name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command
} {

  upvar opts opts

  set row [db_exec select $db $statement_name $sql 3]

  upvar $opts(uplevel) $result_name rows

  set rows [list]

  while { [ns_db getrow $db $row] } {

    set values [list]
    lappend rows [ns_set value $row 0]
  }

  if { [info exists opts(cache)] } {
    set opts(result) $rows
  }
}

ad_proc -private template::query::dml { statement_name db name sql } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param db Database handle
    @param result_name Tcl variable name to use when setting the result
    @param sql Query to use when processing this command
} {

  upvar opts opts

  db_exec dml $db $statement_name "$sql" 3
}

# @private get_cached_result

# Looks in the appropriate cache for the named query result
# If a valid result is found, then sets the result in the returning
# stack frame.

# @return 1 if result was successfully retrieved, 0 if failed

ad_proc -private get_cached_result { name type } {
    @param name Name of cached result-set
    @param type Type of query
} {

  upvar opts opts
  set cache_key $opts(cache)
  set success 0

  if { [info exists opts(persistent)] } {

    if { [nsv_exists __template_query_persistent_cache $cache_key] } {

      # check the timeout 

      set timeout [nsv_get __template_query_persistent_timeout $cache_key]
      if { $timeout > [ns_time] } {
	set cached_result \
	    [nsv_get __template_query_persistent_cache $cache_key]
	set success 1
      }
    }

  } else {

    global __template_query_request_cache

    if { [info exists __template_query_request_cache($cache_key)] } {

      set cached_result $__template_query_request_cache($cache_key)
      set success 1
    }      
  }

  if { $success } {

    switch $type {

      multirow {

	upvar $opts(uplevel) $name:rowcount rowcount
	set rowcount [llength $cached_result]
	set rownum 1

	foreach cached_row $cached_result {
	  upvar $opts(uplevel) $name:$rownum row
	  array set row $cached_row
	  incr rownum
	}
	set opts(result) ""
      } 
      onerow {

	upvar $opts(uplevel) $name result
	array set result $cached_result
	set opts(result) ""
      }
      default {

	upvar $opts(uplevel) $name result
	set result $cached_result
	set opts(result) $cached_result
      }
    }
  }

  return $success
}

# @private set_cached_result

ad_proc -private set_cached_result {} {

    Places a query result in the appropriate cache.

} {

  upvar opts opts
  
  if { ! [info exists opts(result)] } { return } 

  set cache_key $opts(cache)

  if { [info exists opts(persistent)] } {

    # set the result in the persistent cache

    nsv_set __template_query_persistent_cache $cache_key $opts(result)

    if { [info exists opts(timeout)] } {
      set timeout [expr [ns_time] + $opts(timeout)]
    } else {
      set timeout [expr [ns_time] + 60 * 60 * 24 * 7]
    }      

    nsv_set __template_query_persistent_timeout $cache_key $timeout

  } else {

    global __template_query_request_cache
    set __template_query_request_cache($cache_key) $opts(result)
  }
}

# Deprecated!

ad_proc -public template::query::iterate { statement_name sql body } {
    @param statement_name Standard db_api statement name used to hook into query dispatcher
    @param sql Query to use when processing this command
    @param body Code body to be execute for each result row of the returned query
} {

    db_with_handle db {
        set result [db_exec select $db $statement_name $sql 2]

        set rowcount 0

        while { [ns_db getrow $db $result] } {

            upvar __query_iterate_row row

            set row(rownum) [incr rowcount]

            set size [ns_set size $result]

            for { set i 0 } { $i < $size } { incr i } {

                set column [ns_set key $result $i]
                set row($column) [ns_set value $result $i]
            }

            # Execute custom code for each row
            uplevel "upvar 0 __query_iterate_row row; $body"
        }
    }
}

# Flush the cached queries where the query name matches the
# specified string match

ad_proc -private template::query::flush_cache { cache_match } {

    Flush the cached queries where the query name matches the
    specified string match

    @param cache_match Name of query to match for cache flushing
} {
  # Flush persistent cache
  set names [nsv_array names __template_query_persistent_cache]
  foreach name $names {
    if { [string match $cache_match $name] } {
      ns_log notice "FLUSHING QUERY (persistent): $name"
      nsv_unset __template_query_persistent_cache $name
    }
  }

  # Flush temporary cache
  global __template_query_request_cache
  set names [array names __template_query_persistent_cache]
  foreach name $names {
    if { [string match $cache_match $name] } {
      ns_log notice "FLUSHING QUERY (request): $name"
      unset __template_query_persistent_cache($name)
    }
  }

}

# Perform get/set operations on a multirow datasource

ad_proc -public template::multirow { op name args } {
    @param op Multirow datasource operation: create, extend, append, size, get, set, foreach
    @param name Name of the multirow datasource
    @param args optional args
} {  

  switch -exact $op {

    create {
      upvar \#[adp_level] $name:rowcount rowcount $name:columns columns
      set rowcount 0
      set columns $args
    }

    extend {
      upvar $name:columns columns
      foreach column_name $args {
        lappend columns $column_name
      }
    }

    append {
      upvar \#[adp_level] $name:rowcount rowcount $name:columns columns
      incr rowcount
      upvar \#[adp_level] $name:$rowcount row
      
      for { set i 0 } { $i < [llength $columns] } { incr i } {
        
        set key [lindex $columns $i]
        set value [lindex $args $i];	#(!) missing columns are silently empty
        set row($key) $value
      }
      set row(rownum) $rowcount
    }

    size {
      upvar \#[adp_level] $name:rowcount rowcount
      if { [template::util::is_nil rowcount] } {
        error "malformed multirow datasource - $name"
      }
      return $rowcount
    }
    
    get {
      
      set index [lindex $args 0]
      set column [lindex $args 1]
      # Set an array reference if no column is specified
      if { [string equal $column {}] } {
        uplevel "upvar \#[adp_level] $name:$index $name"
      } else {
        # If a column is specified, just return the value for it
        upvar \#[adp_level] $name:$index arr
        return $arr($column)
      }
    }
    
    set {
      
      set index [lindex $args 0]
      set column [lindex $args 1]
      set value [lindex $args 2]
      
      if { [string equal $column {}] } {
        error "No column specified to template::multirow set"
      }
      
      # Mutate the value
      upvar \#[adp_level] $name:$index arr
      set arr($column) $value
      return $arr($column)
      
    } 
    
    foreach {
      set code_block [lindex $args 0]
      
      upvar \#[adp_level] $name:rowcount rowcount

      upvar \#[adp_level] $name:columns columns

      for { set i 1 } { $i <= $rowcount } { incr i } {
        # Pull values into variables (and into the array - aks),
        # evaluate the code block, and pull values back out to
        # the array.
        
        upvar \#[adp_level] $name:$i row

        foreach column_name $columns {
          upvar \#[adp_level] $column_name column_value
          if { [info exists row($column_name)] } {
            set column_value $row($column_name)
          }
        }
        
        # Also set the special var __rownum
        upvar \#[adp_level] __rownum __rownum
        set __rownum $row(rownum)

        set errno [catch { uplevel \#[adp_level] $code_block } error]

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
            error "Cannot return from inside template::multirow foreach loop"
          }
          3 {
            # TCL_BREAK
            break
          }
          4 {
            # TCL_CONTINUE - just ignore and continue looping.
          }
          default {
            error "template::multirow foreach: Unknown return code: $errno"
          }
        }

        # Pull the variables into the array.
        foreach column_name $columns {
          upvar \#[adp_level] $column_name column_value
          if { [info exists column_value] } {
            set row($column_name) $column_value
          }
        }
      }
    }

    default {
      error "Unknown op $op in template::multirow.
      Must be create, extend, append, get, set, size, or foreach."
    }
  }
}

ad_proc -public template::url { command args } {
    
} {

  global __template_url_params
  upvar 0 __template_url_params params

  if { ! [info exists params] } {
    set params [ns_set create]
  }

  set result ""

  switch -exact $command {

    set_param {
      set name [lindex $args 0]
      set value [lindex $args 1]
      ns_set put $params $name $value
    }

    get_param {
      set name [lindex $args 0]
      set default [lindex $args 1]
      if { [ns_set find $params $name] != -1 } {
	set result [ns_set iget $params $name]
      } else {
	set result $default
      }
    }

    get_query {
      set keyvalues [list]
      for { set i 0 } { $i < [ns_set size $params] } { incr i } {
	set key [ns_set key $params $i]
	set value [ns_set value $params $i]
	lappend keyvalues [ns_urlencode $key]=[ns_urlencode $value]
      }
      set result [join $keyvalues &]
    } 

    default {
      error "Invalid command for url: 
             must be set_param, get_param or get_query"
    }

  }

  return $result
}

# Generic caching

nsv_set __template_cache_value . .
nsv_set __template_cache_timeout . .

ad_proc -public cache { command key args } {
    Generic Caching
} {

  set result ""

  switch -exact $command {

    get {

      if { [nsv_exists __template_cache_value $key] } {

	# check the timeout 
	set timeout [nsv_get __template_cache_timeout $key]

	if { $timeout > [ns_time] } {
	  set result [nsv_get __template_cache_value $key]
	} else {
	  nsv_unset __template_cache_value $key
	  nsv_unset __template_cache_timeout $key
	}
      }
    }
 
    set {

      set value [lindex $args 0]

      if { [llength $args] == 1 } {
	set timeout [expr [ns_time] + 60 * 60 * 24 * 7]
      } else {
	set timeout [expr [ns_time] + [lindex $args 1]]
      }

      nsv_set __template_cache_value $key $value
      nsv_set __template_cache_timeout $key $timeout
    }

    flush {
      # The key is actually a string match pattern
      set names [nsv_array names __template_cache_value]
      foreach name $names {
        if { [string match $key $name] } {
          ns_log notice "FLUSHING CACHE: $name"
          nsv_unset __template_cache_value $name
	} 
      }
    }

    default {
      error "Invalid command option to cache: must be get or set."
    } 

  }

  return $result
}
