# Database Query API for the ArsDigita Templating System
# Oracle interface (ns_ora)

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein (karlg@arsdigita.com)
#          Andrew Grumet (aegrumet@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# initialize the global query result cache

nsv_set __template_query_persistent_cache . .
nsv_set __template_query_persistent_timeout . .

# @public get_db_handle

# Returns a database handle to the caller.  Returns the same database handle
# for all subsequent calls until release_db_handle is called.  This allows
# the same handle to be used easily across multiple procedures.  Because the
# handle is not released, care must be taken that subsequent code does
# not explicitly allocate any handles.

# @return A database handle

proc template::get_db_handle {} {

  global __template_db_handle

  if { ! [info exists __template_db_handle] } {
    set __template_db_handle [ns_db gethandle]
  }

  return $__template_db_handle
}

# @public release_db_handle

# Releases a database handle previously requested with get_db_handle.

proc template::release_db_handle {} {

  global __template_db_handle __template_db_transactions

  if { [info exists __template_db_handle] } {

    if { [info exists __template_db_transactions] } {
      ns_log Notice "WARNING: releasing handle without ending the transaction"
    }

    if { [ns_db connected $__template_db_handle] } {
	ns_db releasehandle $__template_db_handle
    }

    unset __template_db_handle
  }
}

# @public begin_db_transaction

# Begins a database transaction and returns the database handle for the
# transaction.  Subsequent calls to get_db_handle will return the same
# handle until end_db_transaction is called.  Calls to this procedure are
# balanced, so that transactions within procedures may be performed either
# alone or in the context of a larger procedure.

# @return A database handle

proc template::begin_db_transaction {} {

  set db [get_db_handle]

  global __template_db_transactions

  if { ! [info exists __template_db_transactions] } {

    set __template_db_transactions 1
    ns_db dml $db "begin transaction"

  } else {

    incr __template_db_transactions
  }

  return $db
}

# @public end_db_transaction

# Ends a database transaction.  The handle used for the transaction is
# NOT explicitly released.

proc template::end_db_transaction {} {

  set db [get_db_handle]

  global __template_db_transactions
  if { [info exists __template_db_transactions] } {

    incr __template_db_transactions -1
    
    if { $__template_db_transactions < 1 } { 
      ns_db dml $db "end transaction"
      unset __template_db_transactions
    }
  }
}  

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

proc template::query { name type sql args } {

  #set beginTime [clock clicks]

  template::util::get_opts $args
  
  if { ! [info exists opts(uplevel)] } {
    set opts(uplevel) 2
  } else {
    set opts(uplevel) [expr 2 + $opts(uplevel)]
  }

  # check the cache for a valid cached query result and return if so
  # otherwise continue to perform the query and cache the results afterwards

  if { [info exists opts(cache)] && [get_cached_result $name $type] } { 
    return $opts(result)
  }

  if { ! [info exists opts(maxrows)] } {
    set opts(maxrows) 10000
  }

  if { [info exists opts(db)] && $opts(db) != "" } {

    set result [template::query::$type $opts(db) $name $sql] 

  } else {

    global __template_db_handle

    if { ! [info exists __template_db_handle] } {
      set db [ns_db gethandle]
    } else {
      set db $__template_db_handle
    }

    set result [template::query::$type $db $name $sql] 

    if { ! [info exists __template_db_handle] } {
      ns_db releasehandle $db
    }
  }

  if { [info exists opts(cache)] } {
    
    # cache the query result
    set_cached_result
  }

  #set timeElapsed [expr ([clock clicks] - $beginTime) / 1000]
  #ns_log Notice "Query performed in: $timeElapsed ms"
  
  return $result
}

# @private onevalue

# Process a onevalue query.  Use a single array to store the results.

proc template::query::onevalue { db name sql } {

  upvar opts opts

  upvar $opts(uplevel) $name result
  set result ""

  uplevel 2 "set __row \[ns_ora 0or1row $db [list $sql]\]"
  upvar 2 __row row

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

proc template::query::onerow { db name sql } {

  upvar opts opts

  uplevel 2 "set __row \[ns_ora 0or1row $db [list $sql]\]"
  upvar 2 __row row

  if { $row != "" } {

    # Set the results in the calling frame.
    upvar $opts(uplevel) $name result

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

proc template::query::multirow { db name sql } {

  upvar opts opts

  uplevel 2 "set __row \[ns_ora select $db [list $sql]\]"
  upvar 2 __row row

  upvar $opts(uplevel) $name:rowcount rowcount $name:columns column_list

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

proc template::query::multilist { db name sql } {

  upvar opts opts

  uplevel 2 "set __row \[ns_ora select $db [list $sql]\]"
  upvar 2 __row row

  upvar $opts(uplevel) $name rows

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

proc template::query::nestedlist { db name sql } {

  upvar opts opts

  uplevel 2 "set __row \[ns_ora select $db [list $sql]\]"
  upvar 2 __row row

  upvar $opts(uplevel) $name rows
  
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

proc template::query::onelist { db name sql } {

  upvar opts opts

  uplevel 2 "set __row \[ns_ora select $db [list $sql]\]"
  upvar 2 __row row

  upvar $opts(uplevel) $name rows

  set rows [list]

  while { [ns_db getrow $db $row] } {

    set values [list]
    lappend rows [ns_set value $row 0]
  }

  if { [info exists opts(cache)] } {
    set opts(result) $rows
  }
}

proc template::query::dml { db name sql } {

  upvar opts opts

  uplevel 2 "ns_ora dml $db \"$sql\""
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

proc template::query::iterate { db sql body } {

  if { [template::util::is_nil db] } {
    set db [ns_db gethandle]
    set free_db 1
  } else {
    set free_db 0
  }

  uplevel "set __result \[ns_ora select $db [list $sql]\]"
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

  if { $free_db } {
    ns_db releasehandle $db
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
