# Database Query API for the ArsDigita Templating System
# Oracle interface (ns_ora)

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein (karlg@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


proc template::query { name type sql args } {

  template::util::get_opts $args
  
  if { ! [info exists opts(uplevel)] } {
    set opts(uplevel) 2
  } else {
    set opts(uplevel) [expr 2 + $opts(uplevel)]
  }

  if { ! [info exists opts(maxrows)] } {
    set opts(maxrows) 10000
  }

  if { [info exists opts(db)] } {

    set result [query::$type $opts(db) $name $sql] 

  } else {

    db_with_handle db {
      set result [query::$type $db $name $sql] 
    }
  }

  return $result
}

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
  }
}

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
 
    return 1
  } else {
    return 0
  }
}

# Process a multirow query.  Use an array for each row row in the
# result.  Arrays are named name0, name1, name2 etc.  The variable
# name.rowcount is also defined for checking and iteration.

proc template::query::multirow { db name sql } {

  upvar opts opts

  uplevel 2 "set __row \[ns_ora select $db [list $sql]\]"
  upvar 2 __row row

  upvar $opts(uplevel) $name:rowcount rowcount

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
    }

    # Execute custom code for each row
    if { [info exists opts(eval)] } {
      uplevel 2 "upvar $ref_level ${name}:$rowcount row; $opts(eval)"
    }
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
}

proc template::query::iterate { db sql body } {

  set code {

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
  }

  if { [template::util::is_nil db] } {
    db_with_handle db $code
  } else {
    eval $code
  }

}

