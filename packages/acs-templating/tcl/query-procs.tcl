# Database Query API for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


# Supplied options are "oracle" and "generic"

set path "ns/server/[ns_info server]/ats"
set db [ns_config $path DatabaseInterface oracle]

source "[file dirname [info script]]/database-procs/$db.tcl"

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
