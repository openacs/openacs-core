# Auxiliary Procs for Tag Handlers for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    	  (karlg@arsdigita.com)
#          Stanislav Freidin 	  (sfreidin@arsdigita.com)
#          Christian Brechbuehler (chrisitan@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public template_tag_if_condition { chunk params condition_type } {

  set condition "$condition_type \{"

  # parse simplified conditional expression
  set args [template_tag_if_concat_params $params]

  if [catch {

    while { 1 } { 

      # process the conditional expression
      template_tag_if_interp_expr

      # Stop when we run out of args 
      if { [llength $args] == 0 } { break }

      set conjunction [lindex $args 0]      

      switch $conjunction {
 
	and { append condition " && " }
	or { append condition " || " }

	default { 
	  error "Invalid conjunction <tt>$conjunction</tt> in 
                 $condition_type tag" 
	}
      }
     
      set args [lrange $args 1 end] 
    }

  } errorMsg] {

    set condition "$condition_type \{ 1 "
    set chunk $errorMsg
  }

  append condition "\} \{"

  switch $condition_type {
      if     {template::adp_append_code $condition}
      elseif {template::adp_append_code $condition -nobreak}
  }

  # Done evaluating condition; evaluate body
  template::adp_compile_chunk $chunk

  # Add closing code
  template::adp_append_code "\}"
}

# append all the tags together and then eval as a list to restore
# quotes

ad_proc -public template_tag_if_concat_params { params } {

  set size [ns_set size $params]

  for { set i 0 } { $i < $size } { incr i } {
     set key [ns_set key $params $i]
     set value [ns_set value $params $i]
     if { [string equal $key $value] } {
       lappend tokens $key
     } else {
       lappend tokens "$key=$value"
     }
  }

  set tokens [eval [concat list [join $tokens " "]]]

  return $tokens
}

# Interpret an expression as part of the simplified IF syntax

ad_proc -public template_tag_if_interp_expr {} {

  upvar args args condition condition

  # append condition "\[expr "

  set op [lindex $args 1]

  if { $op == "not" } {
    append condition "! ("
    set close_paren ")"
    set op [lindex $args 2]
    set i 3
  } else {
    set close_paren ""
    set i 2
  }

  set arg1 "\"[lindex $args 0]\""

  # build the conditional expression

  switch $op {

    gt { 
      append condition "$arg1 > \"[lindex $args $i]\"" 
      set next [expr $i + 1]
    }
    ge { 
      append condition "$arg1 >= \"[lindex $args $i]\"" 
      set next [expr $i + 1]
    }
    lt { 
      append condition "$arg1 <  \"[lindex $args $i]\"" 
      set next [expr $i + 1]
    }
    le { 
      append condition "$arg1 <= \"[lindex $args $i]\"" 
      set next [expr $i + 1]
    }
    eq { 
      append condition "\[string equal $arg1 \"[lindex $args $i]\"\]" 
      set next [expr $i + 1]
    }
    ne { 
      append condition "! \[string equal $arg1 \"[lindex $args $i]\"\]" 
      set next [expr $i + 1]
    }

    in { 
      set expr [join [lrange $args $i end] "|"]
      append condition "\[regexp \"$expr\" $arg1\] " 
      set next [llength $args]
    }

    between { 
      set expr1 "$arg1 >= \"[lindex $args $i]\""
      set expr2 "$arg1 <= \"[lindex $args [expr $i + 1]]\""
      append condition "($expr1 && $expr2)" 
      set next [expr $i + 2]
    }

    nil {
      # substitute array variables
      regsub {^"@([a-zA-z0-9_]+)\.([a-zA-z0-9_]+)@"$} $arg1 {\1(\2)} arg1
      # substitute regular variables
      regsub {^"@([a-zA-z0-9_:]+)@"$} $arg1 {\1} arg1
      append condition "\[template::util::is_nil $arg1\]"
      set next $i
    }

    defined {
      # substitute variable references
      regsub {^"@([a-zA-z0-9_]+)\.([a-zA-z0-9_]+)@"$} $arg1 {\1(\2)} arg1
      regsub {^"@([a-zA-z0-9_:]+)@"$} $arg1 {\1} arg1
      append condition "\[info exists $arg1\]"
      set next $i
    }

    odd { 
      append condition "\[expr $arg1 % 2\]" 
      set next $i
    }

    even { 
      append condition "! \[expr $arg1 % 2\]" 
      set next $i
    }
    
    true {
      append condition "\[template::util::is_true $arg1\]"
      set next $i
    }
    
    false {
      append condition "!\[template::util::is_true $arg1\]"
      set next $i
    }

    default { 
      # treat <if @foo_p@> as a shortcut for <if @foo_p@ true>
      append condition "\[template::util::is_true $arg1\]"
      set next [expr $i - 1]
    }
  }

  append condition $close_paren
  # append condition "]"

  set args [lrange $args $next end]
}

# Local Variables:
# tcl-indent-level: 2
# End:
