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

proc template::query { statement_name result_name type sql args } {

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
      set ret_code [template::query::$type $statement_name $db $result_name \ 
                    $sql] 
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

proc template::query::onevalue { statement_name db result_name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  upvar $opts(uplevel) $result_name result
  set result ""

  uplevel "set __row \[db_exec 0or1row $db $full_statement_name $sql\]"
  upvar __row row

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

proc template::query::onerow { statement_name db result_name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  uplevel "set __row \[db_exec 0or1row $db $full_statement_name $sql\]"
  upvar __row row

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

proc template::query::multirow { statement_name db result_name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  uplevel "set __row \[db_exec select $db $full_statement_name $sql\]"
  upvar __row row

  upvar $opts(uplevel) $result_name:rowcount rowcount \ 
                       $result_name:columns column_list

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
      upvar $opts(uplevel) $name:has_more_rows has_more_rows
      set has_more_rows 1
      incr rowcount -1
      break
    }

    # set the results in the calling frame
    upvar $opts(uplevel) ${name}:$rowcount result

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
        upvar 0 ${name}:$rowcount row; $opts(eval)
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

proc template::query::multilist { statement_name db result_name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  uplevel "set __row \[db_exec select $db $full_statement_name $sql\]"
  upvar __row row

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

proc template::query::nestedlist { statement_name db result_name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  uplevel "set __row \[db_exec select $db $full_statement_name $sql\]"
  upvar __row row

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

proc template::query::onelist { statement_name db result_name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  uplevel "set __row \[db_exec select $db $full_statement_name $sql\]"
  upvar __row row

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

proc template::query::dml { statement_name db name sql } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  upvar opts opts

  uplevel "db_exec dml $db $full_statement_name \"$sql\""
}

# @private get_cached_result

# Looks in the appropriate cache for the named query result
# If a valid result is found, then sets the result in the returning
# stack frame.

# @return 1 if result was successfully retrieved, 0 if failed

proc get_cached_result { name type } {

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

# Places a query result in the appropriate cache.

proc set_cached_result {} {

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

proc template::query::iterate { statement_name db sql body } {

  set full_statement_name [db_qd_get_fullname $statement_name]

  uplevel "set __result \[db_exec select $db $full_statement_name $sql\]"
  upvar __result result

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

# Flush the cached queries where the query name matches the
# specified string match

proc template::query::flush_cache { cache_match } {

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

proc template::multirow { op name args } {
  
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

    default {
      error "Unknown op $op in template::multirow.  
             Must be create, append, get, set or size."
    }
  }
}

proc template::url { command args } {

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

proc cache { command key args } {

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
