ad_library {
    Utility procedures for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
    @author Stanislav Freidin (sfreidin@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval template {}
namespace eval template::util {}
namespace eval template::query {}

ad_proc -public template::util::get_opts { argv } {
    Builds an array named "opts" in the calling frame, containing all
    switches passed at the end of a proc.  The array values are either
    switch parameters or 1 if no parameter was specified.

    Problem: there is currently no way to specify an option parameter that
    begins with a dash.  This particularly problematic for negative numbers.
} {

  upvar opts opts

  set size [llength $argv]

  # append a switch break
  lappend argv "-*"

  for { set i 0 } { $i < $size } {} {
    
    # Get a switch 
    set opt [string trimleft [lindex $argv $i] -]

    # Get the next arg
    set next [lindex $argv [incr i]]

    if { [string index $next 0] ne "-" 
	 || ![regexp {[a-zA-Z*]} [string index $next 1] match] } {
      
      # the next arg was not a switch so assume it is a parameter 
      set opts($opt) $next
      # advance the counter past the switch parameter
      incr i

    } else {
      
      # the next arg was a switch so just use 1 as the parameter
      set opts($opt) 1
    }
  }
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * Utility procedures for manipulating lists, arrays and ns_sets *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ad_proc -public template::util::list_opts { {array_ref opts} } {
    Converts an array to an option list

    @param  array_ref  The name of the array in the calling frame containing
                       option-value pairs.  Defaults to "opts".

    @return A list of option-value pairs suitable for appending to a command.
} {

  upvar $array_ref arr

  set ret [list]
  foreach {key value} [array get arr] {
    lappend ret "-$key" $value
  }
  
  return $ret
}

ad_proc -public template::util::is_nil { ref } {
    Determines whether a variable both exists and is not an empty string.

    @param ref  The name of a variable to test in the calling frame.

    @return 1 if the variable either not exist or is an empty string.  0 if
            the variable is either an array reference or a non-empty scalar.
} {

  upvar $ref var

  # check for an array as well
  if { [array exists var] } { return 0 }

  if { [info exists var] && $var ne {} } {
    set result 0
  } else {
    set result 1
  }
  return $result
}

ad_proc -public template::util::is_unique { table columns values } {
    Queries a database table for the existence of a particular row.
    Useful for validating form input to reduce the possibility of 
    unique constraint violations.

    @param table   The name of a database table.
    @param columns A list of columns on which to select the row.
    @param values  A list of values for each specified column.

    @return 1 if the row exists, 0 if not
} {

  set query "select count(*) from $table where "

  for { set i 0 } { $i < [llength $columns] } { incr i } {
   
    set value [ns_dbquotevalue [lindex $values $i]]
    lappend conditions "[lindex $columns $i] = $value"
  }

  append query [join $conditions " and "]

  set count [db_string get_count $query]

  return [expr {$count == 0}]
}

ad_proc -public template::util::is_true { x } {
    interprets its argument as a boolean.

    @param x  the value to test

    @return 0 if the variable can be interpreted as false; 
            1 for true if it can't.
} {
    #expr {[string tolower $x] ni {0 f false n no off ""}}
    #ns_log notice "TRUE [expr {[string tolower $x] ni {0 f false n no off ""}}] [string is true -strict $x]"
    string is true -strict $x
}

ad_proc -public template::util::lpop { ref } {
    Removes the last item from a list.  The operation is performed
    in-place, rather than returning the new list.

    @param ref The name of a list in the calling frame on which to operate.
} {
  upvar $ref the_list
  set the_list [lrange $the_list 0 end-1]
}

ad_proc -public template::util::lnest { listref value next args } {
    Recursive procedure for building a hierarchical or multidimensional
    data structure in a list.

    @param value   Either a list or scalar value to store in the list.
    @param next    A key value that determines the next node to
                   traverse outward in the data structure.
    @param args    Subsequent nodes to traverse.
} {

  upvar $listref inlist
  if { ! [info exists inlist] } {
    set inlist [list]
  }

  # inlist represents the top level of the data structure into which
  # we are inserting. We need to turn the list into an array to determine
  # which branch to follow next.

  array set values $inlist
 
  # next determines the next branch to follow as we look for the proper
  # location of the value.  if the key is not found, create a new branch by
  # adding an empty list to inlist

  if { [info exists values($next)] } {
    set next_list $values($next)
  } else {
    set next_list [list]
  }

  # the number of additional arguments after next determines how many
  # more branches or levels we need to traverse before reaching the actual
  # insertion point into the data structure.

  set remaining [llength $args]
  if { $remaining == 0 } {

    # we have reached a leaf
    lappend next_list $value

  } elseif { $remaining == 1 } {

   # continue for one more step to the leaf
   lnest next_list $value [lindex $args 0]

  } else {

   # more branches to go.  Call the procedure recursively starting with
   # the current branch.

   lnest next_list $value [lindex $args 0] [lrange $args 1 end]
  }

  # At this point the branch has been updated.  Update the branch in the
  # array.

  set values($next) $next_list

  # Update inlist.
  
  set inlist [array get values]
}

ad_proc -public template::util::set_to_list { set args } {
    Turns an ns_set into a key-value list, excluding any number of
    specified keys.  Useful for turning the contents on an ns_set into
    a form that may be cached or manipulated as a native Tcl data structure.

    @param set  A reference to an ns_set.
    @param args Any number of key names to exclude from the list.

    @return A list in the form { key value key value key value ... }
} {

  set result [list]

  for { set i 0 } { $i < [ns_set size $set] } { incr i } {

    set key [ns_set key $set $i]
    if { $key in $args } { continue }

    lappend result $key [ns_set value $set $i]
  }

  return $result
}

ad_proc -public template::util::set_to_vars { set args } {
    Declare local variables for set values

    @param set  A reference to an ns_set.
    @param args Any number of keys to declare as local variables.
} {

  if { [llength $args] == 0 } {

    for { set i 0 } { $i < [ns_set size $set] } { incr i } {
      set key [ns_set key $set $i]
      upvar $key value
      set value [ns_set get $set $key]
    }

  } else {

    foreach key $args {
      upvar $key value
      set value [ns_set get $set $key]
    }
  }
}

ad_proc -public template::util::array_to_vars { arrayname } {
    Declare local variables for every key in an array.

    @param arrayname   The name of an array in the calling frame.
} {
    upvar $arrayname arr

    foreach { key value } [array get arr] {
        uplevel [list set $key $value]
    }
}

ad_proc -public template::util::vars_to_array { arrayname args } {
    Place local variables into an array

    @param arrayname   The name of an array in the calling frame.
    @param args        Any number of local variables to include in the array
} {
  upvar $arrayname arr

  foreach var $args {
    upvar $var value
    set arr($var) $value
  }
}

ad_proc -public template::util::list_to_array { values array_ref columns } {
    Converts a list of values into an array, using a list of
    corresponding column names for the array keys.

    @param values    A list of values
    @param array_ref The name of the array to create in the calling frame.
    @param columns   A list of column names to use for the array keys.
                     The length of this list should be the same as the values
                     list.
} {

  upvar $array_ref array

  for { set i 0 } { $i < [llength $values] } { incr i } {

    set key [lindex $columns $i]
    set value [lindex $values $i]

    set array($key) $value
  }
}

ad_proc -public template::util::list_of_lists_to_array { lists array_ref } {
    Converts a list of lists in the form { { key value } { key value } ... } 
    to an array.
} {

  upvar $array_ref array

  foreach pair $lists {

    set key [lindex $pair 0]
    set value [lindex $pair 1]

    set array($key) $value
  }
}

ad_proc -public template::util::list_to_lookup { values array_ref } {
    Turn a list into an array where each key corresponds to an element
    of the list... Sort of like a sparse bitmap.  Each value corresponds
    to the key's position in the input list.

    @param values    A list of values
    @param array_ref The name of the array to create in the calling frame.
} {
  upvar $array_ref array

  set i 1

  foreach element $values {
    set array($element) $i
    incr i
  }
}


ad_proc -public template::util::multirow_to_list { 
    {-level 1}
    name 
} {
    generate a list structure representitive of a multirow data source

    <b>NB:</b> if the multirow is generated by db_multirow, db_multirow must
    be called with the -local option
 
    @param name the name of an existing multirow data source

    @return a representation of a multirow data source as a list,
    suitable for passing by value in the form { { row } { row } { row } ... }

    @see proc template::util::list_to_multirow
} {

  upvar $level $name:rowcount rowcount

  set rows [list]

  for { set i 1 } { $i <= $rowcount } { incr i } {

    upvar $level $name:$i row

    lappend rows [array get row]
  }

  return $rows
}

ad_proc -public template::util::list_to_multirow { name rows { level 1 } } {
    populate a multirow data source from a list string gotten from
    a call to template::util::multirow_to_list

    @param name the name of a multirow data source
    @param rows a representation of a multirow data source as a list,
    suitable for passing by value in the form { { row } { row } { row } ... }

    @see proc template::util::multirow_to_list
} {

  upvar $level $name:rowcount rowcount
  set rowcount [llength $rows]
  set rownum 1

  foreach rowlist $rows {
    lappend rowlist rownum $rownum
    upvar $level $name:$rownum row
    array set row $rowlist
    incr rownum
  }
}

ad_proc -public template::util::list_of_ns_sets_to_multirow {
    {-rows:required}
    {-var_name:required}
    {-level "1"}
} {
    Transform a list of ns_sets (most likely produced by db_list_of_ns_sets
    into a multirow datasource.

    @param rows The data to be transformed
    @param var_name The name of the multirow to create
    @param level How many levels up the stack to place the new datasource,
                 defaults to 1 level up.
} {
    upvar $level $var_name:rowcount rowcount $var_name:columns columns
    set rowcount [llength $rows]

    set i 1
    foreach row_set $rows {

        ns_set put $row_set rownum $i

        upvar $level $var_name:$i row
        array set row [util_ns_set_to_list -set $row_set]
	if {$i == 1} {
	    set columns [array names row]
	} 
        incr i
    }
}

# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
# * Utility procedures for interacting with the file system *
# * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *

ad_proc -public template::util::read_file { path } {
    Reads a text file.

    @param path The absolute path to the file

    @return A string with the contents of the file.
} {

  set fd [open $path]

  template::util::set_file_encoding $fd

  set text [read $fd]
  close $fd

  return $text
}

ad_proc -public template::util::set_file_encoding { file_channel_id } {
    Set encoding of the given file channel based on the OutputCharset
    parameter of AOLserver. All ADP, Tcl, and txt files are assumed
    to be in the same charset.

    @param file_channel_id The id of the file to set encoding for.
    
    @author Peter Marklund
} {
  set output_charset [ns_config "ns/parameters" OutputCharset]
  set tcl_charset [ns_encodingforcharset $output_charset]

  if { $tcl_charset ne "" } {
      fconfigure $file_channel_id -encoding $tcl_charset
  }
}

ad_proc -public template::util::write_file { path text } {
    Writes a text file

    @param path The absolute path to the file
    @param text A string containing the text to write to the file.
} {

  file mkdir [file dirname $path]

  set fd [open $path w]

  template::util::set_file_encoding $fd

  puts $fd $text
  close $fd
}

ad_proc -public template::util::master_to_file { url {reference_url ""} } {
    
    Resolve a URL into an absolute file path, but respect styled
    master configuration for named masters
    (e.g. acs-templating/resources/masters/... containing 2cols.adp)
    
} {
    if { [string index $url 0] ne "/" } {
	set master_stub [template::resource_path -type masters -style $url]

	if {[file exists $master_stub.adp]} {
	    set path $master_stub
	} else {
	    set path [file dirname $reference_url]/$url
	}
	
    } else {
	set path $::acs::rootdir/$url
    }
    return [ns_normalizepath $path]
}

ad_proc -public template::util::url_to_file { url {reference_url ""} } {
    Resolve a URL into an absolute file path.
} {

    if { [string index $url 0] ne "/" } {
        set path [file dirname $reference_url]/$url
    } else {
        set path $::acs::rootdir/$url
    }

    return [ns_normalizepath $path]
}

ad_proc -public template::util::resolve_directory_url { url } {
    Resolve the file name for a directory URL
} {
  set path $::acs::pageroot$url

  if { [file isdirectory $path] && [file exists ${path}index.adp] } {
    set url ${url}index.acs
  }

  return $url
}

ad_proc -public template::util::get_url_directory { url } {
    Get the directory portion of a URL.  If the URL has a trailing
    slash, then return the entire URL.
} {
  set directory $url

  set lastchar [string range $url [string length $url]-1 end]

  if {$lastchar ne "/" } {

    set directory [file dirname $url]/

    if {$directory eq "//"} { 
      # root directory is a special case
      set directory /
    }
  }

  return $directory
}

ad_proc -public -deprecated template::util::get_cookie { name {default_value ""} } {
    Retrieve the value of a cookie and return it
    Return the default if no such cookie exists
    
    @see ad_get_cookie
} {
  set headers [ns_conn headers]    
  set cookie [ns_set iget $headers Cookie]

  if { [regexp "$name=(\[^;\]+)" $cookie match value] } {
    return [ns_urldecode $value]
  }
  
  return $default_value
}

ad_proc -public -deprecated template::util::set_cookie { expire_state name value { domain "" } } {
    Create a cookie with specified parameters.  The expiration state 
    may be persistent, session, or a number of minutes from the current
    time.

    @see ad_set_cookie
} {

  if { [string match $domain {}] } { 
    set path "ns/server/[ns_info server]/module/nssock"
    set domain [ns_config $path Hostname]
  }

  set cookie "$name=[ns_urlencode $value]; path=/; domain=$domain"
    
  switch $expire_state {

    persistent {
      append cookie ";expires=Wed, 01-Jan-2020 01:00:00 GMT"
    }

    "" -
    session {
    }

    default {
      
      set time [expr {[ns_time] + ($expire_state * 60)}]
      append cookie ";expires=[ns_httptime $time]"
    }
  }

  ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
}

ad_proc -public -deprecated template::util::clear_cookie { name { domain "" } } { 
    Expires an existing cookie.

    @see ad_get_cookie

} {
  if { [string match $domain {}] } { 
    set path "ns/server/[ns_info server]/module/nssock"
    set domain [ns_config $path Hostname]
  }

  set cookie "$name=expired; path=/; domain=$domain;"
  append cookie "expires=Tue, 01-Jan-1980 01:00:00 GMT"

  ns_set put [ns_conn outputheaders] "Set-Cookie" $cookie
} 

ad_proc -deprecated -public template::util::quote_html {
  html
} {
  Quote possible HTML tags in the contents of the html parameter.  
} {

  return [ns_quotehtml $html]
}

ad_proc -public template::util::multirow_quote_html {multirow_ref column_ref} {
    implements template::util::quote_html on the designated column of a multirow

    @param multirow_ref name of the multirow
    @param column_ref name of the column to be

    @author simon
} {

    upvar $multirow_ref:rowcount rowcount

    for { set i 1 } { $i <= $rowcount } { incr i} {
        upvar $multirow_ref:$i arr
        set arr($column_ref) [ns_quotehtml [set arr($column_ref)]]
    }

}


ad_proc -deprecated -public template::util::multirow_foreach { name code_text } {
    runs a block of code foreach row in a multirow.

    Using "template::multirow foreach" is recommended over this routine.

    @param name the name of the multirow over which the block of 
                code is iterated

    @param code_text the block of code in the for loop; this block can 
                     reference any of the columns belonging to the 
                     multirow specified; with the multirow named 
                     "fake_multirow" containing columns named "spanky" 
                     and "foobar",to set the column spanky to the value 
                     of column foobar use:<br> 
                     <code>set fake_multirow.spanky @fake_multirow.foobar@</code>
                     <p>
                     note: this block of code is evaluated in the same 
                     scope as the .tcl page that uses this procedure

    @author simon

    @see template::multirow
} {

  upvar $name:rowcount rowcount $name:columns columns i i
  upvar running_code running_code

  for { set i 1} {$i <= $rowcount} {incr i} {

      set running_code $code_text
      foreach column_name $columns {

	  # first change all references to a column to the proper
	  # rownum-dependent identifier, ie the array value identified
	  # by $<multirow_name>:<rownum>(<column_name>)
	  regsub -all "($name).($column_name)" $running_code "$name:${i}($column_name)" running_code
      }

     regsub -all {@([a-zA-Z0-9_:\(\)]+)@} $running_code {${\1}} running_code

     uplevel {
       eval $running_code
     }

  }
  
}

ad_proc -deprecated -public template::util::get_param { 
    name 
    {section ""} 
    {key ""} 
} {
    Retrieve a stored parameter, or "" if no such parameter
    If section/key are present, read the parameter from the specified
    section.key in the INI file, and cache them under the given name
} {

  if { ![nsv_exists __template_config $name] } {

    # Extract the parameter from the ini file if possible
    if { $section ne "" } {

      # Use the name if no key is specified
      if { $key ne "" } {
        set key $name
      }

      set value [ns_config $section $key ""]
      if {$value eq ""} {
        return ""
      } else {
        # Cache the value and return it
        template::util::set_param $name $value
        return $value
      }

    } else {
      # No such parameter found and no key/section specified
      return ""
    }
  } else {
    return [nsv_get __template_config $name]
  }
}

ad_proc -public -deprecated  template::util::set_param { name value } {
    Set a stored parameter
} {
  nsv_set __template_config $name $value
}

ad_proc -public template::util::nvl { value value_if_null } {
    Analogous to SQL NVL
} {
  if {$value eq ""} {
    return $value_if_null
  }
  return $value
}

ad_proc -public template::util::number_list { last_number {start_at 0} } {
    Return a list of numbers, {1 2 3 ... n}
} {

  set ret [list]
  for {set i $start_at} { $i <= $last_number } {incr i} {
    lappend ret $i
  }
  return $ret
}

ad_proc -public template::util::tcl_to_sql_list { lst } {
    Convert a Tcl list to a SQL list, for use with the "in" statement.
    Uses DoubleApos (similar to ns_dbquotevalue) functionality to escape single quotes
} {

    if { [llength $lst] > 0 } {
        # adding DoubleApos functionality for security reasons.
        regsub -all -- ' "$lst" '' lst2
        set sql "'"
        append sql [join $lst2 "', '"]
        append sql "'"
        return $sql
    } else {
        return ""
    }
}

ad_proc -deprecated template::get_resource_path {} {
    Get the template directory
    The body is doublequoted, so it is interpreted when this file is read
    @see template::resource_path
} "
  return \"[file dirname [file dirname [info script]]]/resources\"
"

ad_proc -public template::themed_template {
    path
} {
    
    Given a path like /packages/acs-admin/www/index pointing to an
    .adp file, this function tries to locate this path in the
    ResourceDir of the subsite (determined by the theme). If found the
    themed template is returned, otherwse the passed template path.

    @param path absolute path within the open acs tree (without extension)
    @return path to themed template or input value (without extension)
    
} {
    if {[string index $path 0] eq "/"} {
	set style [string range $path 1 end]
    } else {
	set style $path
    }
    set stub [template::resource_path -type templates -style $style -relative]
    if {[file readable $::acs::rootdir/$stub.adp]} {
	return $stub
    }
    return $path
}

ad_proc -public template::streaming_template {
    -subsite_id
} {
    Return the path of the streaming template
    @param subsite_id id of the subsite. Defaults to [ad_conn subsite_id]
    @return path to themed template
} {
    if { ![info exists subsite_id] } {
        set subsite_id [ad_conn subsite_id]
    }
    set template [parameter::get -package_id $subsite_id \
                      -parameter StreamingHead \
                      -default "/packages/openacs-default-theme/lib/plain-streaming-head"]
    return [template::resource_path -type masters -style $template -relative]
}

ad_proc -public template::resource_path {
    -type:required
    -style:required
    -relative:boolean
    -subsite_id
    -theme_dir
} {
    
    Process the templating "style" and return the stub (path without
    extensions). When the style is not an abolute path, check if the
    resource can be obtained from the theme, if not fallback to the
    resources directory of acs-templating.

    @param type type of resource (e.g. "forms" or "lists")
    @param style name of the resource within the type (e.g. "standard")
    @param relative return optionally the path relative to the OpenACS root directory
    @param theme_dir theming directory (alternative to determination via subsite), higher priority
    @param subsite_id subsite_id to determine theming information

    @return path of the resource (without extension)
    @author Gustaf Neumann
} {
    
    if {![regexp {^/(.*)} $style path]} {

	if { ![info exists theme_dir] } {
	    if { ![info exists subsite_id] } {
		set subsite_id [ad_conn subsite_id]
	    }
	    set theme_dir [parameter::get -parameter ResourceDir -package_id $subsite_id]
	}

	if {$theme_dir ne ""} {
            if {![file isdir $::acs::rootdir/$theme_dir]} {
                ns_log warning "ResourceDir '$theme_dir' does not exist under '$::acs::rootdir';\
                    ignore parameter setting of subsite $subsite_id"
                set theme_dir ""
            }
        }
        
	if {$theme_dir ne ""} {
	    set path $theme_dir/$type/$style
	    if {![file exists $::acs::rootdir/$path.adp]} {
		unset path
	    }
	}
	if {![info exists path]} {
	    set path /packages/acs-templating/resources/$type/$style
	}
    }
    
    if {$relative_p} {
	return $path
    } else {
	return $::acs::rootdir/$path
    }
}

ad_proc -public stack_frame_values {level} {
    return the variables and arrays of one frame as HTML
} {

  set varlist ""
  foreach i [if {$level} {
    uplevel \#$level {info locals}
  } else {info globals} ] {
    append varlist "    <li><b>$i</b> = "
    if {$i eq "page" && $level == [info level]-1 ||
	$i eq "__adp_output" || $i eq "errorInfo"} {
      append varlist "<em>value withheld to avoid messy page</em>\n"
    } elseif {[string match -nocase "*secret*" $i]} {
      append varlist "<em>value withheld as the name contains \"secret\"</em>\n"
    } else {
      if {[uplevel \#$level array exists $i]} {
	append varlist "<em>ARRAY</em><ul>\n"
	foreach {key value} [uplevel \#$level array get $i] {
	  append varlist "        <li><b>$key</b> = '$value'\n"
	}
	append varlist "        </ul>\n"
      } else {
          if {[catch {append varlist "'[uplevel #$level set $i]'\n"}]} {
	  append varlist "<em>bad string value</em>\n"
	}
      }
    }
  }
  return $varlist
}



ad_proc -public stack_dump {} {
    return the whole call stack as HTML
} {
  append page "<h1>Tcl Call Trace</h1>
  <ul>"
  
  for {set x [info level]} {$x > 0} {incr x -1} {
    append page "<li>$x.  [info level $x]<ul>
[stack_frame_values $x]    </ul>\n"
  }
  
  append page "</ul>
  <h2>Globals</h2>
  <ul> [stack_frame_values 0] </ul>\n"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
