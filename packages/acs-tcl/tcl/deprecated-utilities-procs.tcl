ad_library {

    Provides a variety of non-ACS-specific utilities that have been
    deprecated

    @author yon [yon@arsdigita.com]
    @date 9 Jul 2000
    @cvs-id $Id$

}

proc nmc_GetNewIDNumber {id_name} {

    db_transaction {
	db_dml id_number_update "update id_numbers set :id_name = :id_name + 1"
	set id_number [db_string nmc_getnewidnumber "select unique :id_name from id_numbers"]
	return $id_number
    }

}

# if you do a 
#   set selection [ns_db 1row $db "select foo,bar from my_table where key=37"]
#   set_variables_after_query
# then you will find that the Tcl vars $foo and $bar are set to whatever
# the database returned.  If you don't like these var names, you can say
#   set selection [ns_db 1row $db "select count(*) as n_rows from my_table"]
#   set_variables_after_query
# and you will find the Tcl var $n_rows set

# You can also use this in a multi-row loop
#   set selection [ns_db select $db "select *,email from mailing_list order by email"]
#   while { [ns_db getrow $db $selection] } {
#        set_variables_after_query
#         ... your code here ...
#   }
# then the appropriate vars will be set during your loop

#
# CAVEAT NERDOR:  you MUST use the variable name "selection"
# 

#
# we pick long names for the counter and limit vars
# because we don't want them to conflict with names of
# database columns or in parent programs
#

proc set_variables_after_query {} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $selection $set_variables_after_query_i] [ns_set value $selection $set_variables_after_query_i]
		incr set_variables_after_query_i
	    }
    }
}

# as above, but you must use sub_selection

proc set_variables_after_subquery {} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $sub_selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $sub_selection $set_variables_after_query_i] [ns_set value $sub_selection $set_variables_after_query_i]
		incr set_variables_after_query_i
	    }
    }
}

#same as philg's but you can:
#1. specify the name of the "selection" variable
#2. append a prefix to all the named variables

proc set_variables_after_query_not_selection {selection_variable {name_prefix ""}} {
    set set_variables_after_query_i 0
    set set_variables_after_query_limit [ns_set size $selection_variable]
    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
        # NB backslash squarebracket needed since mismatched {} would otherwise mess up value stmt.
	uplevel "
	set ${name_prefix}[ns_set key $selection_variable $set_variables_after_query_i] \[ns_set value $selection_variable $set_variables_after_query_i]
	"
	incr set_variables_after_query_i
    }
}

# takes a query like "select unique short_name from products where product_id = 45"
# and returns the result (only works when you are after a single row/column
# intersection)

proc database_to_tcl_string {db sql} {

    set selection [ns_db 1row $db $sql]

    return [ns_set value $selection 0]

}

proc database_to_tcl_string_or_null {db sql {null_value ""}} {
    set selection [ns_db 0or1row $db $sql]
    if { $selection != "" } {
	return [ns_set value $selection 0]
    } else {
	# didn't get anything from the database
	return $null_value
    }
}

#for commands like set full_name  ["select first_name, last_name..."]

proc database_cols_to_tcl_string {db sql} {
    set string_to_return ""	
    set selection [ns_db 1row $db $sql]
    set size [ns_set size $selection]
    set i 0
    while {$i<$size} {
	append string_to_return " [ns_set value $selection $i]"
        incr i
    }
    return [string trim $string_to_return]
}

proc_doc database_to_tcl_list {db sql} {takes a query like "select product_id from foobar" and returns all the ids as a Tcl list} {
    set selection [ns_db select $db $sql]
    set list_to_return [list]
    while {[ns_db getrow $db $selection]} {
	lappend list_to_return [ns_set value $selection 0]
    }
    return $list_to_return
}

proc_doc database_to_tcl_list_list {db sql} "Returns a list of Tcl lists, with each sublist containing the columns returned by the database; if no rows are returned by the database, returns the empty list (empty string in Tcl 7.x and 8.x)" {
    set selection [ns_db select $db $sql]
    set list_to_return [list]
    while {[ns_db getrow $db $selection]} {
	set row_list ""
	set size [ns_set size $selection]
	set i 0
	while {$i<$size} {
	    lappend row_list [ns_set value $selection $i]
	    incr i
	}
	lappend list_to_return $row_list
    }
    return $list_to_return
}

proc_doc database_1row_to_tcl_list {db sql} "Returns the column values from one row in the database as a Tcl list.  If there isn't exactly one row from this query, throws an error." {
    set selection [ns_db 1row $db $sql]
    set list_to_return [list]
    set size [ns_set size $selection]
    set counter 0
    while {$counter<$size} {
	lappend list_to_return [ns_set value $selection $counter]
	incr counter
    }
    return $list_to_return
}

# Helper procedure for sortable_table.
# column_list is a list of column names optionally followed by " desc".
# Returns a new list with sort_column as the first element, followed
# by the columns in column_list excluding any beginning with sort_column.
proc sortable_table_new_sort_order {column_list sort_column} {
    set new_order [list $sort_column]

    # Relies on string representation of lists. [lindex "colname desc" 0]
    # returns just "colname".
    set just_the_sort_column [lindex $sort_column 0]
    foreach col $column_list {
	if { [lindex $col 0] != $just_the_sort_column } {
	    lappend new_order $col
	}
    }
    return $new_order
}

proc_doc sortable_table {db select_string display_spec vars_to_export sort_var current_sort_order {table_length ""} {extra_table_parameters ""} {stripe_color_list ""} {max_results ""} {header_font_params ""} {row_font_params ""}} {Procedure to format a database query as a table that can be sorted by clicking on the headers.
Arguments are:
<ul>
<li>db: database handle
<li>select_string: SQL statement that selects all columns that will be displayed in the table.
<li>display_spec: a "display specification" that consists of a list of column specs. Column specs are lists with the following elements:
<ol>
<li>primary column name (name of column which determines sorting for this table column)
<li>header (header to display for this column)
<li>display string (optional; if provided, a string with variable references to column names that will be interpolated for each row)
<li>default sort order (optional; really used to say when something needs to sort "desc" by default instead of "asc")</li>
<li>column width (optional).</li>
</ol>
<li>vars_to_export: an ns_set of variables to re-export to the current page. Generally, [ad_conn form]
<li>sort_var: a variable name which stores the sorting information for this table. You can use different sort_vars for multiple sortable tables in the same page.
<li>current_sort_order: a list of column names that determine the current sorting order. Each element is either a column name that can be optionally followed by " desc" to specify descending order. Generally, just the current value of $sort_var.
<li>table_length (optional): where to insert table breaks. Leaving unspecified or empty specifies no table breaks.
<li>extra_table_parameters: Any extra parameters to go in the &lt;table&gt; tag
<li>stripe_color_list: a list of color specifications for table striping. If specified, should specify at least two, unless a single color is desired for every row.
<li>max_results (optional): Indicates to truncate table after so many results are retreived.
<li>header_font_params (optional): Sets the font attributes for the headers.
<li>row_font_params (optional): Sets the font attributes for any old row.
</ul>} {
    # Run the SQL
    set order_clause ""
    if { ![empty_string_p $current_sort_order] } {
	set order_clause " order by [join $current_sort_order ","]"
    }
    
    set selection [ns_db select $db "$select_string$order_clause"]

    # Start generating the table HTML.
    set table_start "<table $extra_table_parameters>\n" 
    set table_html ""
    
    set primary_sort_column [lindex $current_sort_order 0]

    # Put in the headers.
    set headers "<tr>"
    foreach col_desc $display_spec {

	# skip any blank columns
	if { [llength $col_desc] < 1 } { continue }

	set primary_column_name [lindex $col_desc 0]

	# set the default sort order
	set primary_column_sort ""
	if { [llength $col_desc] > 3 } {
	    set primary_column_sort "[lindex $col_desc 3]"
	}

	set column_header [lindex $col_desc 1]

	# Calculate the href for the header link.
	set this_url [ad_conn url]
	set exported_vars [export_ns_set_vars "url" $sort_var $vars_to_export]
	if { ![empty_string_p $exported_vars] } {
	    append exported_vars "&"
	}
	
	set just_the_sort_column [lindex $primary_sort_column 0]
	set sort_icon ""
	if { $primary_column_name == $just_the_sort_column } {
	    # This is the column that is being sorted on. Need to reverse
	    # the direction of the sort by appending or removing " desc".

	    # Relies on the fact that indexing past the end of a list
	    # is not an error, just returns the empty string.
	    # We're treating a string as a list here, since we know that
	    # $primary_sort_column will be a plain column name, or a 
	    # column name followed by " desc".
	    if { [lindex $primary_sort_column 1] == "desc" } {
		append exported_vars "$sort_var=[ns_urlencode [sortable_table_new_sort_order $current_sort_order $just_the_sort_column]]"
		set sort_icon "<img border=0 src=\"/graphics/up.gif\">"
	    } else {
		append exported_vars "$sort_var=[ns_urlencode [sortable_table_new_sort_order $current_sort_order "$just_the_sort_column desc"]]"
		set sort_icon "<img border=0 src=\"/graphics/down.gif\">"
	    }
	} else {
	    # Clicked on some other column.
	    append exported_vars "$sort_var=[ns_urlencode [sortable_table_new_sort_order $current_sort_order "$primary_column_name $primary_column_sort"]]"
	}

	if { [empty_string_p "[lindex $col_desc 4]"] } {
	    append headers "<th>"
	} else {
	    append headers "<th width=\"[lindex $col_desc 4]\">"
	}

	append headers "<a href=\"$this_url?$exported_vars\"><font face=\"helvetica,verdana,arial\" $header_font_params>$column_header</font>$sort_icon</th>"

    }

    append headers "</tr>\n"

    # Do the data rows.
    set i 0
    set color_index 0
    set n_colors [llength $stripe_color_list]
    set n_results 0

    while { [ns_db getrow $db $selection] } {
	set_variables_after_query

	# check to see if we have reached our max results limit
	if { [exists_and_not_null max_results] } {
	    if { $n_results >= $max_results } { break }
	    incr n_results
	}

	# Handle table breaks.
	if { $i == 0 } {
	    append table_html "$table_start$headers"
	} elseif { ![empty_string_p $table_length] } {
	    if { $i % $table_length == 0 } {
		append table_html "</table>\n$table_start$headers"
		set i 0
	    }
	}

	# Handle row striping.
	if { ![empty_string_p $stripe_color_list] } {
	    append table_html "<tr bgcolor=\"[lindex $stripe_color_list $color_index]\">"
	    set color_index [expr ($color_index + 1) % $n_colors]
	} else {
	    append table_html "<tr>"
	}

	# Handle each display column.
	foreach col_desc $display_spec {

	    # skip any blank columns
	    if { [llength $col_desc] < 1 } { continue }

	    set primary_column_name [lindex $col_desc 0]
	    set col_display [lindex $col_desc 2]
	    
	    if { [empty_string_p $col_display] } {
		# Just use the sort column as the value.
		set col_display "\$$primary_column_name"
	    }

	    # Insert &nbsp; for empty rows to avoid empty cells.
	    set value [subst $col_display]
	    if { [empty_string_p $value] } {
		set value "&nbsp;"
	    }

	    append table_html "<td><font face=\"helvetica,verdana,arial\" $row_font_params>$value</font></td>"
	}

	append table_html "</tr>\n"
	incr i
    }

    ns_db flush $db

    if { ![empty_string_p $table_html] } {
        append table_html "</table>"
    }

    return $table_html
}
