ad_library {
    Database Query API for the ArsDigita Templating System

    @creation-date 29 September 2000
    @author Karl Goldstein (karlg@arsdigita.com)
    @author Stanislav Freidin (sfreidin@arsdigita.com)
    
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::query {}

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


ad_proc -public template::query { statement_name result_name type sql args } {
    Public interface to template query api.  This routine parses the arguments and
    dispatches to the query command specified by the type argument.

    @option maxrows    Limits the query results of a multirow query
                       to a fixed number of rows.

    @option cache      Cache the query results keyed on an identifier
                       that is unique for both the query and the bind variables
                       used in the query.  The cached result reflects
                       any initial specification of maxrows and startrows.

    @option refresh    Force a query to be performed even if it is cached,
                       and refresh the cache.
                       <p>
                       Only applicable if the cache option is specified as
                       well. Does not affect a previously specified timeout 
                       period.

    @option timeout    The maximum period of time for which the cached results
                       are valid in seconds.  Only applicable for
                       persistently cached results.

    @option persistent Cache the query results persistently, so that
                       all subsequent requests use the results.

    @param statement_name Standard db_api query name

    @param result_name Tcl variable name when doing an uplevel to 
           set the returned result

    @param type The query type

    @param sql The sql to be used for the query

    @param args Optional args: uplevel, cache, maxrows

    @return 1 if query was a success, 0 if it failed
} {

  set sql [string trim $sql]
  set full_statement_name [db_qd_get_fullname $statement_name]

  #set beginTime [clock clicks -milliseconds]

  template::util::get_opts $args
  
  if { ! [info exists opts(uplevel)] } {
    set opts(uplevel) 2
  } else {
    set opts(uplevel) [expr {2 + $opts(uplevel)}]
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

  #set timeElapsed [expr ([clock clicks -milliseconds] - $beginTime)]
  #ns_log Notice "Query performed in: $timeElapsed ms"
  
  return $ret_code
}

ad_proc -private template::query::onevalue { statement_name db result_name sql } {
    Process a onevalue query.  Use a single array to store the results.

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

    @param db Database handle

    @param result_name Tcl variable name to use when setting the result

    @param sql Query to use when processing this command

} {

  upvar opts opts

  upvar $opts(uplevel) $result_name result
  set result ""

  set row [db_exec 0or1row $db $statement_name $sql 3]

  if { $row ne "" } {

    # Set the result in the calling frame.
    set result [ns_set value $row 0]

    if { [info exists opts(cache)] } {
      set opts(result) $result
    }
  }
}

ad_proc -private template::query::onerow { statement_name db result_name sql } {
    Process a onerow query.  Use a single array to store the results.

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

    @param db Database handle

    @param result_name Tcl variable name to use when setting the result

    @param sql Query to use when processing this command
} {

  upvar opts opts

  set row [db_exec 0or1row $db $statement_name $sql 3]

  if { $row ne "" } {

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

ad_proc -private template::query::multirow { statement_name db result_name sql } {
    Process a multirow query.  Use an array for each row row in the
    result.  Arrays are named name0, name1, name2 etc.  The variable
    name.rowcount is also defined for checking and iteration.

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

    @param db Database handle

    @param result_name Tcl variable name to use when setting the result

    @param sql Query to use when processing this command

    @see db_multirow
    @see template::multirow
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
    set ref_level [expr {$opts(uplevel) - 2}]
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
    Process a multilist query.

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

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


ad_proc -private template::query::nestedlist { statement_name db result_name sql } {
    Creates a data source where the values for each row 
    are returned as a list.  Rows are grouped according
    to the column values specified in the -groupby option
    See template::util::lnest for more details.

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

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

    template::util::lnest rows $values {*}$group_values
  }

  if { [info exists opts(cache)] } {
    set opts(result) $rows
  }

  return $rows
}

ad_proc -private template::query::onelist { statement_name db result_name sql } {
    Process a onelist query.

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

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
    Process an SQL statement that is not a query; perhaps update or insert

    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

    @param db Database handle

    @param result_name Tcl variable name to use when setting the result

    @param sql Query to use when processing this command
} {

  upvar opts opts

  db_exec dml $db $statement_name "$sql" 3
}


ad_proc -private get_cached_result { name type } {
    Looks in the appropriate cache for the named query result
    If a valid result is found, then sets the result in the returning
    stack frame.

    @param name Name of cached result-set

    @param type Type of query

    @return 1 if result was successfully retrieved, 0 if failed
} {

  upvar opts opts
  set cache_key $opts(cache)
  set success 0

  if { [info exists opts(persistent)] } {

    if { [ns_cache names template_query_cache $cache_key] ne ""} {

      if {[ns_info name] eq "NaviServer"} {
	set cached_result [ns_cache_eval template_query_cache $cache_key {}]
      } else {

	# get the pair of the timeout and value
	lassign [ns_cache get template_query_cache $cache_key] timeout cached_result

	# check the timeout
	if { $timeout > [ns_time] } {
	  set success 1
	} else {
	  ns_cache flush template_query_cache $cache_key
	}
      }
    }

  } else {
    if { [info exists ::__template_query_request_cache($cache_key)] } {
      set cached_result $::__template_query_request_cache($cache_key)
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

ad_proc -private set_cached_result {} {

    Places a query result in the appropriate cache.

} {

  upvar opts opts
  
  if { ! [info exists opts(result)] } { return } 

  set cache_key $opts(cache)

  if { [info exists opts(persistent)] } {
    #
    # calculate the timeout
    #
    if { [info exists opts(timeout)] } {
      set timeout [expr {[ns_time] + $opts(timeout)}]
    } else {
      set timeout [expr {[ns_time] + 60 * 60 * 24 * 7}]
    }

    if {[ns_info name] eq "NaviServer"} {
      #
      # NaviServer allows per entry expire time
      #
      ns_cache_eval -expires $timeout -force template_query_cache $cache_key \
	  set _ $opts(result)
    } else {
      #
      # set the cached value as a pair of timeout and value
      #
      ns_cache set template_query_cache $cache_key [list $timeout $opts(result)]
    }

  } else {
    set ::__template_query_request_cache($cache_key) $opts(result)
  }
}

ad_proc -public -deprecated template::query::iterate { statement_name sql body } {
    @param statement_name Standard db_api statement name used to hook 
                          into query dispatcher

    @param sql Query to use when processing this command

    @param body Code body to be execute for each result row of the 
                returned query

    @see db_foreach
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

ad_proc -private template::query::flush_cache { cache_match } {

    Flush the cached queries where the query name matches the
    specified string match

    @param cache_match Name of query to match for cache flushing
} {
  # Flush persistent cache
  set names [ns_cache names template_query_cache]
  foreach name $names {
    if { [string match $cache_match $name] } {
      ns_log debug "template::query::flush_cache: FLUSHING QUERY (persistent): $name"
      ns_cache flush template_query_cache $name
      if {[ns_info name] ne "NaviServer"} {
	ns_cache flush template_timeout_cache $name
      }
    }
  }

  # Flush temporary cache
  set names [array names ::__template_query_persistent_cache]
  foreach name $names {
    if { [string match $cache_match $name] } {
      ns_log debug "template::query::flush_cache: FLUSHING QUERY (request): $name"
      unset ::__template_query_persistent_cache($name)
    }
  }

}


ad_proc -public multirow {
    {-ulevel 1}
    {-local:boolean}
    -unclobber:boolean
    op
    name
    args
} { 
    multirow is really template::multirow or possibly 
    template::query::multirow depending on context.
    the "template::" or "template::query::"
    may be omitted depending on what the namespace 
    is.  .tcl pages are evaluated in the template:: 
    namespace.

    @see template::multirow
    @see template::query::multirow
} -        

ad_proc -public template::multirow { 
  {-ulevel 1}
  {-local:boolean}
  -unclobber:boolean
  command
  name
  args
} {
    Create/Manipulate a multirow datasource (for use with &lt;multiple&gt; tags)

    <dl>
    <dt> <b>template::multirow create datasourcename column [column ...]</b></dt>
    <dd> creates a multirow datasource of datasourcename </dd>
    <dt> <b>template::multirow extend datasourcename column [column ...] </b></dt>
    <dd> extend adds a column to an existing multirow</dd>
    <dt> <b>template::multirow append datasourcename value [value ...]</b></dt>
    <dd> appends the row to an existing multirow.</dd>
    <dt> <b>template::multirow pop datasourcename </b></dt>
    <dd> pops a row off an existing multirow, returning a list of the rows keys gand values</dd>
    <dt> <b>template::multirow size datasourcename</b></dt>
    <dd> returns the rowcount</dd>
    <dt> <b>template::multirow columns datasourcename</b></dt>
    <dd> returns the columns in the datasource</dd>
    <dt> <b>template::multirow get datasourcename rownum [column]</b></dt>
    <dd> returns the row of of data (or the particular row/column if column is provided)</dd>
    <dt> <b>template::multirow set datasourcename rownum column value</b></dt>
    <dd> set an element value</dd>
    <dt> <b>template::multirow foreach datasource code </b></dt>
    <dd> evaluate code block for each row (like db_foreach)</dd>
    <dt> <b>template::multirow upvar datasource [new_name]</b></dt>
    <dd> upvar the multirow, aliasing to new_name if provided</dd>
    <dt> <b>template::multirow unset datasource</b></dt>
    <dd> unset multirow</dd>
    <dt> <b>template::multirow sort datasource -lsort-switch -lsort-switch col1 col2</b></dt>
    <dd> Sort the multirow by the column(s) specified. The value sorted by will be the the values of the columns specified, separated by the space character. Any switches specified before the columns will be passed directly to the lsort command. </dd>
    <dt> <b>template::multirow exists datasource</b></dt>
    <dd> Return 1 if the multirow datasource exists, 0 if it doesn't.
    </dl>
   
    @param local If set, the multirow will be looked for in the scope the number 
           of levels up given by ulevel (normally the caller's scope), 
           instead of the <code>[template::adp_level]</code> scope, which 
           is the default.

    @param ulevel Used in conjunction with the "local" parameter to specify how 
           many levels up the multirow variable resides.

    @param command Multirow datasource operation: create, extend, append, pop, size, get, set, foreach, upvar

    @param name Name of the multirow datasource

    @param args optional args

    @param unclobber This only applies to the 'foreach' command.
    If set, will cause the proc to not overwrite local variables. Actually, what happens
    is that the local variables will be overwritten, so you can access them within the code block. However, 
    if you specify -unclobber, we will revert them to their original state after execution of this proc.

    @see db_multirow
    @see template::query::multirow
} {  
  if { $local_p } {
    set multirow_level_up $ulevel
  } else {
    set multirow_level_up \#[adp_level]
    if { $multirow_level_up eq "\#" } {
      # in event adp_level not defined we are calling either at install so up 1.
      set multirow_level_up 1
    }
  }
  
  switch -exact $command {

    create {
      upvar $multirow_level_up $name:rowcount rowcount $name:columns columns
      set rowcount 0
      set columns $args
    }

    unset {
      upvar $multirow_level_up $name:rowcount rowcount $name:columns columns
      for { set i 1 } { $i <= $rowcount } { incr i } {
        upvar $multirow_level_up $name:$i row
        unset row
      }
      unset rowcount columns
    }

    extend {
      upvar $multirow_level_up $name:columns columns
      foreach column_name $args {
        lappend columns $column_name
      }
    }

    pop {
        upvar $multirow_level_up $name:rowcount rowcount $name:columns columns
        set r_list [list]
        if {$rowcount > 0} {
            upvar $multirow_level_up $name:$rowcount row
            for { set i 0 } { $i < [llength $columns] } { incr i } {
                set key [lindex $columns $i]
                if {[info exists row($key)]} {
                    set value $row($key)
                    lappend r_list $key $value
                }
            }
            array unset row
        }
        incr rowcount -1
        return $r_list
    }

    append {
      upvar $multirow_level_up $name:rowcount rowcount $name:columns columns
      incr rowcount
      upvar $multirow_level_up $name:$rowcount row
      
      for { set i 0 } { $i < [llength $columns] } { incr i } {
        
        set key [lindex $columns $i]
        set value [lindex $args $i];	#(!) missing columns are silently empty
        set row($key) $value
      }
      set row(rownum) $rowcount
    }

    size {
      upvar $multirow_level_up $name:rowcount rowcount
      if { [template::util::is_nil rowcount] } {
          return 0
      }
      return $rowcount
    }

    columns {
      upvar $multirow_level_up $name:columns columns
      if { [template::util::is_nil columns] } {
          return {}
      }
      return $columns
    }
    
    get {
      
      set index [lindex $args 0]
      set column [lindex $args 1]
      # Set an array reference if no column is specified
      if {$column eq ""} {

        # If -local was specified, the upvar is done with a relative stack frame
        # index, and we must take into account the fact that the uplevel moves up
        # the frame one level.  If -local was not specified, the an absolute stack
        # frame is passed to upvar, which of course needs no adjustment.

        if { $local_p } {
            uplevel "upvar [expr { $multirow_level_up - 1 }] $name:$index $name"
        } else {
            uplevel "upvar $multirow_level_up $name:$index $name"
        }

      } else {
          # If a column is specified, just return the value for it
          upvar $multirow_level_up $name:$index arr
          if {[info exists arr($column)]} {
              return $arr($column)
          } else {
              ns_log warning "can't obtain template variable form ${name}:${index}: $column"
              return ""
          }
      }
    }
    
    set {
      
      set index [lindex $args 0]
      set column [lindex $args 1]
      set value [lindex $args 2]
      
      if {$column eq {}} {
        error "No column specified to template::multirow set"
      }
      
      # Mutate the value
      upvar $multirow_level_up $name:$index arr
      set arr($column) $value
      return $arr($column)
      
    }
    
    upvar {
      # upvar from wherever the multirow is to the current stack frame
      if { [llength $args] > 0 } {
        set new_name [lindex $args 0]
      } else {
        set new_name $name
      }
      uplevel "
        upvar $multirow_level_up $name:rowcount $new_name:rowcount $name:columns $new_name:columns
        for { set i 1 } { \$i <= \${$new_name:rowcount} } { incr i } {
          upvar $multirow_level_up $name:\$i $new_name:\$i
        }
      "
    }
    
    foreach {
      set code_block [lindex $args 0]
      upvar $multirow_level_up $name:rowcount rowcount $name:columns columns

      if {![info exists rowcount] || ![info exists columns]} { 
        return 
      } 
      
      # Save values of columns which we might clobber
      if { $unclobber_p } {
        foreach col $columns {
          upvar 1 $col column_value __saved_$col column_save
          
          if { [info exists column_value] } {
            if { [array exists column_value] } {
              array set column_save [array get column_value]
            } else {
              set column_save $column_value
            }
            
            # Clear the variable
            unset column_value
          }
        }
      }

      for { set i 1 } { $i <= $rowcount } { incr i } {
        # Pull values into variables (and into the array - aks),
        # evaluate the code block, and pull values back out to
        # the array.
        
        upvar $multirow_level_up $name:$i row

        foreach column_name $columns {
          upvar 1 $column_name column_value
          if { [info exists row($column_name)] } {
            set column_value $row($column_name)
          } else {
            set column_value ""
          }
        }
        
        # Also set the special var __rownum
        upvar 1 __rownum __rownum
        set __rownum $row(rownum)

        set errno [catch { uplevel 1 $code_block } error]

        switch $errno {
          0 {
            # TCL_OK
          }
          1 {
            # TCL_ERROR
            error $error $::errorInfo $::errorCode
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
          upvar 1 $column_name column_value
          if { [info exists column_value] } {
            set row($column_name) $column_value
          }
        }
      }
      
      if { $unclobber_p } {
        foreach col $columns {
          upvar 1 $col column_value __saved_$col column_save
          
          # Unset it first, so the road's paved to restoring
          if { [info exists column_value] } {
            unset column_value
          }
          
          # Restore it
          if { [info exists column_save] } {
            if { [array exists column_save] } {
              array set column_value [array get column_save]
            } else {
              set column_value $column_save
            }
            
            # And then remove the saved col
            unset column_save
          }
        }
      }
    }

    sort {
        # args is a list of names of columns to sort by
        # construct a list which we can lsort
        
        upvar $multirow_level_up $name:rowcount rowcount
        
        if { ![info exists rowcount] } {
            error "Multirow $name does not exist"
        } 

        # Construct list of (rownum,columns appended with a space)

        # Allow for -ascii, -dictionary, -integer, -real, -command <command>, -increasing, -decreasing, unique switches

        set sort_args {}

        set len [llength $args]
        for { set i 0 } { $i < $len } { incr i } {
            if { [string equal [string index [lindex $args $i] 0] "-"] } {
                switch -exact [string range [lindex $args $i] 1 end] { 
                    command {
                        # command takes an additional argument
                        lappend sort_args [lindex $args $i]
                        incr i
                        lappend sort_args [lindex $args $i]
                    }
                    default {
                        lappend sort_args [lindex $args $i]
                    }
                }
            } else {
                break
            }
        }

        set sort_cols [lrange $args $i end]
            
        set sort_list [list]
        
        for { set i 1 } { $i <= $rowcount } { incr i } {
            upvar $multirow_level_up $name:$i row

            # Make a copy of the row
            array set copy:$i [array get row]

            # Contruct the list
            set sortby {}
            foreach col $sort_cols {
                append sortby $row($col) " "
            }
            
            lappend sort_list [list $i $sortby]
        }

        set sort_list [lsort {*}$sort_args -index 1 $sort_list]

        
        # Now we have a list with two elms, (rownum, sort-by-value), sorted by sort-by-value
        # Rearrange multirow to match the sort order
        
        set i 0
        foreach elm $sort_list {
            incr i
            upvar $multirow_level_up $name:$i row

            # which rownum in the original list should fill this space in the sorted multirow?
            set org_rownum [lindex $elm 0]

            # Replace the row in the multirow with the row from the copy with the rownum according to the sort
            array set row [array get copy:$org_rownum]

            # Replace the 'rownum' column
            set row(rownum) $i
        }
        
        # Multirow length may have changed if you said -unique
        set rowcount [llength $sort_list]
    }

    exists {
       upvar $multirow_level_up $name:rowcount rowcount
       return [info exists rowcount]
    }

    default {
      error "Unknown command $command in template::multirow.
      Must be create, extend, append, backup, get, set, size, upvar, sort, exists or foreach."
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

ad_proc -public cache { command cache_key args } {
    Generic Caching
} {

  set result ""

  switch -exact $command {

    get {
      if {[ns_info name] eq "NaviServer"} {
	if {[ns_cache_keys template_cache $cache_key] ne ""} {
	  set result [ns_cache_eval template_cache $cache_key {}]
	}
      } else {
	if { [ns_cache names template_cache $cache_key] ne "" } {
	  # get timeout and value
	  lassign [ns_cache get template_cache $cache_key] timeout value
	  # validate timeout
	  if { $timeout > [ns_time] } {
	    set result $value
	  } else {
	    ns_cache flush template_cache $cache_key
	  }
	}
      }
    }
 
    set {

      if { [llength $args] == 1 } {
	set timeout [expr {[ns_time] + 60 * 60 * 24 * 7}]
      } else {
	set timeout [expr {[ns_time] + [lindex $args 1]}]
      }

      if {[ns_info name] eq "NaviServer"} {
	#
	# NaviServer allows per entry expire time
	#
	ns_cache_eval -expires $timeout -force template_cache $cache_key \
	    set _ [lindex $args 0]
      } else {
	#
	# Use a pair for AOLserver
	#
	ns_cache set template_cache $cache_key [list $timeout [lindex $args 0]]
      }
    }

    flush {
      # The key is actually a string match pattern
      if {[ns_info name] eq "NaviServer"} {
	ns_cache_flush -glob template_cache $cache_key
      } else {
	set names [ns_cache names template_cache]
	foreach name $names {
	  if { [string match $cache_key $name] } {
	    ns_log debug "cache: FLUSHING CACHE: $name"
	    ns_cache flush template_cache $name
	  }
	}
      }
    }

    exists  {
      if {[ns_info name] eq "NaviServer"} {
	set result [expr {[ns_cache_keys template_cache $cache_key] ne ""}]
      } else {
	if { [ns_cache get template_cache $cache_key cached_value] } {
	  # get timeout and value
	  lassign $cached_value timeout value
	  # validate timeout
	  if { $timeout > [ns_time] } {
	    set result 1
	  } else {
	    set result 0
	  }
	} else {
	  set result 0
	}
      }
    }

    default {
      error "Invalid command option to cache: must be get or set."
    } 

  }

  return $result
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
