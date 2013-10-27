# /packages/mbryzek-subsite/tcl/plsql-utility-procs.tcl

ad_library {

    Procs to help generate pl/sql dynamically

    @author mbryzek@arsdigita.com
    @creation-date Thu Dec  7 10:31:56 2000
    @cvs-id $Id$
    
}

namespace eval plsql_utility {

    ad_proc -public generate_constraint_name { 
	{ -max_length 30 }
	table 
	column 
	stem 
    } {
	Generates a constraint name adhering to the arsdigita standard
	for naming constraints. Note that this function does not yet ensure
	that the returned constraint name is not already in use, though the
	probability for a collision is pretty low.

	The ideal name is table_column_stem. We trim first table, then
	column to make it fit.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set max_length_without_stem [expr {$max_length - [expr {[string length $stem] + 1}]}]

	set text "${table}_$column"
	if { [string length $text] > $max_length_without_stem } {
	    set text ""
	    # Pull out the initials of the table name
	    foreach piece [split $table "_"] {
		append text [lindex [split $piece ""] 0]
	    }
	    append text "_$column"
	}
	return [string toupper "[string range $text 0 $max_length_without_stem-1]_$stem"]
    }

    ad_proc -public object_type_exists_p { object_type } {
	Returns 1 if the specified object_type exists. 0 otherwise.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000
    } {
	return [db_string object_type_exists_p {
	    select case when exists (select 1 from acs_object_types where object_type=:object_type)
                        then 1
                        else 0
                   end
              from dual
	}]
    }


    ad_proc -public format_pieces {
	{ -indent 6 }
	{ -num_spaces 3 }
	{ -delim "" }
	{ -line_term "," }
	pieces
    } {
	Proc to format a list of elements. This is used to generate
	nice error/debugging messages when we are executing things like
	pl/sql. Pieces is a list of lists where each element is a key
	value pair.

	<p>

	Example:
<pre>plsql_utility::format_pieces -indent 3 -delim " => " \
	[list [list object_type group] [list group_id -2] [list group_name "Reg users"]]
</pre>
returns:
<pre>
object_type    => group,
   group_id       => -2,
   group_name     => Reg users
</pre>

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

        @param pieces a list of lists where each element is a key/value pair

    } {
	# Find max length of first column
	set max_length -1
	foreach pair $pieces {
	    if { [string length [lindex $pair 0]] > $max_length } {
		set max_length [string length [lindex $pair 0]]
	    }
	}
	if { $max_length == -1 } {
	    # no elements... return
	    return ""
	}
	set indent_text ""
	for { set i 0 } { $i < $indent } { incr i } {
	    append indent_text " "
	}

	# Generate text
	set text ""
	set col_width [expr {$max_length + $num_spaces}]
	foreach pair $pieces {
	    lassign $pair left right
	    while { [string length $left] < $col_width } {
		append left " "
	    }
	    if { $text ne "" } {
		append text "$line_term\n$indent_text"
	    }
	    append text "${left}${delim}${right}"
	}
	return $text
	

    }



    ad_proc -public generate_oracle_name { 
	{ -max_length 30 }
	{ -include_object_id "f" }
	stem
    } {
	Returns an object name of max_length characters, in lower
	case, beginning with stem but without any unsafe characters. Only
	allowed characters are numbers, letter, underscore, dash and space,
	though the returned word will start with a letter. Throws an
	error if no safe name could be generated.
	
	To almost guarantee uniqueness, you can use the next object_id
	from acs_object_id_seq as the tail of the name we return.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	
	if { $include_object_id == "t" } {
	    set id [db_nextval "acs_object_id_seq"]
	    set suffix "_$id"
	} else {
	    set suffix ""
	}
	# Leave only letters, numbers, underscores, dashes, and spaces
	regsub -all {[^ _\-a-z0-9]} [string tolower $stem] "" stem
	# Make sure it starts with a letter
	regsub {^[^a-z]} $stem "" stem

	# change spaces to underscores
	regsub -all {\s+} $stem "_" stem
	#Trim to fit in $max_length character limit
	set max_length_without_suffix [expr {$max_length - [string length $suffix]}]
	if { [string length $stem] >= $max_length_without_suffix } {
	    set stem [string range $stem 0 $max_length_without_suffix-1]
	}
	if { $stem eq "" } {
	    error "generate_oracle_name failed to generate a safe oracle name from the stem \"$stem\"\n"
	}
	return "$stem$suffix"

    }


    ad_proc -public parse_sql { sql_query } {
	Replaces bind variables with their Double Apos'd values to aid in
	debugging. Throws error if any bind variable is undefined in the
	calling environment.
	
	<p>Limits: Only handles letter, numbers, and _ or - in bind variable names

	<p>Example:
<pre>
set group_id -2
set sql "select acs_group.name(:group_id) from dual"
ns_write [plsql_utility::parse_sql $sql]
</pre>
would write the following to the browser:
<pre>
select acs_group.name('-2') from dual
</pre>

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	
	while { 1 } {
	    if { ![regexp -- {:([a-zA-Z0-9_-]+)} $sql_query match var] } {
		break
	    }
	    # Use $var as the target to get nice error messages
	    upvar 1 $var $var
	    if { ![info exists $var] } {
		error "Cannot find value for bind variable \"$var\"\n\n"
	    }
	    regsub -- "\:$var" $sql_query '[DoubleApos [set $var]]' sql_query
	}
	return $sql_query
    }

    ad_proc -public generate_attribute_parameters { 
	{ -indent "9" }
	attr_list 
    } {
	Generates the arg list to a pl/sql function or procedure

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set pieces [list]
	foreach triple $attr_list {
	    set table [string toupper [string trim [lindex $triple 0]]]
	    set attr [string toupper [string trim [lindex $triple 1]]]
	    if { [lindex $triple 2] eq "" } {
		set default_string ""
	    } else {
		set default_string " DEFAULT [lindex $triple 2]"
	    }
	    lappend pieces [list $attr "IN ${table}.${attr}%TYPE${default_string}"]
	}
	return [format_pieces -indent $indent $pieces]

    }

    ad_proc -public generate_attribute_parameter_call_from_attributes { 
	{ -prepend "" }
	{ -indent "9" }
	attr_list 
    } {
	Wrapper for generate_attribute_parameter_call that formats
	default attribute list to the right format.

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set the_list [list]
	foreach row $attr_list {
	    lappend the_list [list [lindex $row 1] [lindex $row 3]]
	}
	return [generate_attribute_parameter_call -prepend $prepend -indent $indent $the_list]
    }

    ad_proc -public generate_attribute_parameter_call {
	{ -prepend "" }
	{ -indent "9" }
	pairs
    } {
	Generates the arg list for a call to a pl/sql function or procedure

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set pieces [list]
	foreach row $pairs {
	    set attr [string trim [lindex $row 0]]
	    set attr_value [string trim [lindex $row 1]]
	    if { $attr_value eq "" } {
		set attr_value $attr
	    }
	    lappend pieces [list "$attr" "$prepend$attr_value"]
	}
	return [format_pieces -delim " => " -indent $indent $pieces]
    }



    ad_proc -public generate_attribute_dml { 
	{ -start_with_comma "t" }
	{ -prepend "" }
	{ -ignore "" }
	table_name 
	attr_list 
    } {
	Generates the string for a sql insert... e.g. ",col1, col2"

	@author Michael Bryzek (mbryzek@arsdigita.com)
	@creation-date 11/2000

    } {
	set ignore [string toupper $ignore]
	set this_columns [list]
	set table_name [string toupper [string trim $table_name]]
	foreach triple $attr_list {
	    set table [string toupper [string trim [lindex $triple 0]]]
	    set column [string toupper [string trim [lindex $triple 1]]]
	    if {[string toupper $column] in $ignore} {
		# Ignore this column
		continue
	    }
	    if {$table eq $table_name} {
		lappend this_columns "$prepend$column"
	    }
	}

	if { [llength $this_columns] == 0 } {
	    return ""
	}
	set return_value [join $this_columns ", "]
	if { $start_with_comma == "t" } {
	    return ", $return_value"
	}
	return $return_value
    }



}
