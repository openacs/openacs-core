# Database Query API for the ArsDigita Templating System
# Generic interface (ns_db)

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein (karlg@arsdigita.com)
#          Andrew Grumet (aegrumet@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

proc template::query { name type sql args } {

  template::util::get_opts $args
  set result [query::$type $opts(db) $name $sql] 

  return $result
}

# Process a onevalue query.  Use a scalar to store the results.

proc template::query::onevalue { db name sql } {

  upvar 2 $name result
  set result ""

  set row [ns_db 0or1row $db $sql]

  if { $row != "" } {

    # Set the result in the calling frame.
    set result [ns_set value $row 0]
  }
}

# Process a onerow query.  Use a single array to store the results.

proc template::query::onerow { db name sql } {

  set row [ns_db 0or1row $db $sql]

  if { $row != "" } {

    # Set the results in the calling frame.
    upvar 2 $name result

    set size [ns_set size $row]

    for { set i 0 } { $i < $size } { incr i } {

	set column [ns_set key $row $i]
	set result($column) [ns_set value $row $i]
    }
  }
}

# Process a multirow query.  Use an array for each row row in the
# result.  Arrays are named name0, name1, name2 etc.  The variable
# name.rowcount is also defined for checking and iteration.

proc template::query::multirow { db name sql } {

  upvar opts opts

  set row [ns_db select $db $sql]

  upvar 2 $name:rowcount rowcount

  set rowcount 0

  while { [ns_db getrow $db $row] } {

    incr rowcount

    upvar 2 ${name}:$rowcount result
    set result(rownum) $rowcount

    set size [ns_set size $row]

    for { set i 0 } { $i < $size } { incr i } {
	set column [ns_set key $row $i]
	set result($column) [ns_set value $row $i]
    }  
    
    # Execute custom code for each row
    if { [info exists opts(eval)] } {
      uplevel 2 "upvar 0 ${name}:$rowcount row"
      uplevel 2 $opts(eval)
    }
  }
}