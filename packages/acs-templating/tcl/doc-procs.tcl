ad_library {
    Documentation procedures for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Data source comments have the following form:

# @datasource foo multirow
# Output info about a foo.
# @param column name The name of the foo.
# @param id The ID of the foo passed with the request.

namespace eval template {}

ad_proc -public template::parse_directives {
  code
} {
  Parse out directives embedded in the code parameter.
} {

  # remove carriage returns if present
  regsub -all {\r|\r\n} $code {\n} code

  # remove extra blank lines
  regsub -all {(\n)\n} $code {\1} code

  set lines [split $code "\n"]

  # regular expression for match directive comments
  set direxp {^\#[\s]*@([a-zA-Z0-9\-_]+)[\s]+(.*)$}

  set directives [list]

  foreach line $lines {

    if { [regexp $direxp $line x next_directive next_comment] } {

      # start a new directive

      if { [info exists directive] } {

	# finish last directive
	lappend directives [list $directive $comment]
      }	

      set directive $next_directive 
      set comment $next_comment
      
    } elseif { [info exists directive] } {

      if { [regexp {^\#\s*(.*)$} $line x add_comment] } {

	# append this line to the current directive
	append comment " $add_comment"

      } else {

	# finish directive
	lappend directives [list $directive $comment]
	unset directive
	unset comment
      }
    }
  }

  if { [info exists directive] } {
    lappend directives [list $directive $comment]
  }

  return $directives
}

ad_proc -public template::get_datasources { code } {
    Assemble directives into data source(s) for presentation.
} {

  upvar datasources:rowcount rowcount
  set rowcount 0

  #for debugging purposes
  upvar output text
  set text [parse_directives $code]

  foreach directive [parse_directives $code] {
    
    switch -exact [lindex $directive 0] {

      datasource {

	# directive is a new datasource
	set info [lindex $directive 1]
	set name [lindex $info 0]
	set structure [lindex $info 1]
	set comment [lrange $info 2 end]

	if { [string match "one*" $structure] } {

	  # directive is a onevalue or onelist.  add a row and move on
	  incr rowcount
	  upvar datasources:$rowcount datasource

	  set datasource(rownum) $rowcount
	  set datasource(name) $name
	  set datasource(structure) $structure
	  set datasource(comment) $comment
	}
      }

      data_input {
	# directive is a new form
	set info [lindex $directive 1]
	set name [lindex $info 0]
	set structure [lindex $info 1]
	set comment [lrange $info 2 end]
      }
      
      input {
	set info [lindex $directive 1]
	set input_name [lindex $info 0]
	set input_type [lindex $info 1]
	set input_comment [lrange $info 2 end]
	  
	incr rowcount
	upvar datasources:$rowcount datasource
	  
	set datasource(rownum) $rowcount
	set datasource(structure) $structure
	set datasource(comment) $comment
	set datasource(name) $name

	set datasource(input_name) $input_name
	set datasource(input_type) $input_type
	set datasource(input_comment) $input_comment
      }
 
      column {

	set info [lindex $directive 1]
	set column_name [lindex $info 0]
	set column_comment [lrange $info 1 end]

	incr rowcount
	upvar datasources:$rowcount datasource

	set datasource(rownum) $rowcount
	set datasource(name) $name
	set datasource(structure) $structure
	set datasource(comment) $comment

	set datasource(column_name) $column_name
	set datasource(column_comment) $column_comment
      }	
    }
  }
}

ad_proc -public template::verify_datasources {} {
  @return True (1)
} {
  return 1
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
