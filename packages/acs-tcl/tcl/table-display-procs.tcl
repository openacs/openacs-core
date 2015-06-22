ad_library {
    This is the table, dimensional bar and sort tools.
    an example of their use can be found in /acs-examples
    @cvs-id $Id$
}
    
# Dimensional selection bars.
#
ad_proc ad_dimensional {
    option_list 
    {url {}} 
    {options_set ""} 
    {optionstype url}
} {
    Generate an option bar as in the ticket system; 
    <ul>
      <li> option_list -- the structure with the option data provided 
      <li> url -- url target for select (if blank we set it to ad_conn url).
      <li> options_set -- if not provided defaults to [ns_getform], for hilite of selected options.
      <li> optionstype -- only url is used now, was thinking about extending 
            so we get radio buttons and a form since with a slow select updating one 
            thing at a time would be stupid.
    </ul>
    
    <p>
    option_list structure is 
    <pre>
    { 
        {variable "Title" defaultvalue
            {
                {value "Text" {key clause}}
                ...
            }
        }
        ...
    }

    an example:

    set dimensional_list {
        {visited "Last Visit" 1w {
            {never "Never" {where "last_visit is null"}}
            {1m "Last Month" {where "last_visit + 30 > sysdate"}}
            {1w "Last Week" {where "last_visit + 7 > sysdate"}}
            {1d "Today" {where "last_visit > trunc(sysdate)"}}
        }}
        ..(more of the same)..
    }
    </pre>
} {
    set html {}

    if {$option_list eq ""} {
        return
    }

    if {$options_set eq ""} {
        set options_set [ns_getform]
    }
    
    if {$url eq ""} {
        set url [ad_conn url]
    }

    append html "<table border=\"0\" cellspacing=\"0\" cellpadding=\"3\" width=\"100%\">\n<tr>\n"

    foreach option $option_list { 
        append html " <th style=\"background-color: #ECECEC\">[lindex $option 1]</th>\n"
    }
    append html "</tr>\n"

    append html "<tr>\n"

    foreach option $option_list { 
        append html " <td align='center'>\["

        # find out what the current option value is.
        # check if a default is set otherwise the first value is used
        set option_key [lindex $option 0]
        set option_val {}
        if { $options_set ne ""} {
            set option_val [ns_set get $options_set $option_key]
        }
        if { $option_val eq "" } {
            set option_val [lindex $option 2]
        }
        
        set first_p 1
        foreach option_value [lindex $option 3] { 
            set thisoption [lindex $option_value 0]
            if { $first_p } {
                set first_p 0
            } else {
                append html " | "
            } 
            
            if {$option_val eq $thisoption } {
                append html "<strong>[ns_quotehtml [lindex $option_value 1]]</strong>"
            } else {
		set href $url?[export_ns_set_vars url $option_key $options_set]&[ns_urlencode $option_key]=[ns_urlencode $thisoption]
                append html [subst {<a href="[ns_quotehtml $href]">[ns_quotehtml [lindex $option_value 1]]</a>}]
            }
        }
        append html "\]</td>\n"
    }
    append html "</tr>\n</table>\n"
}

ad_proc ad_dimensional_sql {
    option_list 
    {what "where"} 
    {joiner "and"} 
    {options_set ""}
} {
    see ad_dimensional for the format of option_list
    <p>
    Given what clause we are asking for and the joiner this returns 
    the sql fragment
} {
    set out {}

    if {$option_list eq ""} {
        return
    }

    if {$options_set eq ""} {
        set options_set [ns_getform]
    }

    foreach option $option_list { 
        # find out what the current option value is.
        # check if a default is set otherwise the first value is used
        set option_key [lindex $option 0]
        set option_val {}
        # get the option from the form
        if { $options_set ne ""} {
            set option_val [ns_set get $options_set $option_key]
        }
        #otherwise get from default
        if { $option_val eq "" } {
            set option_val [lindex $option 2]
        }
        
        foreach option_value [lindex $option 3] { 
            set thisoption [lindex $option_value 0]
            if {$option_val eq $thisoption } {
                set code [lindex $option_value 2]
                if {$code ne ""} {
                    if {[lindex $code 0] eq $what } {
                        append out " $joiner [uplevel [list subst [lindex $code 1]]]"
                    }
                }
            }
        }
    }

    return $out
}

ad_proc ad_dimensional_set_variables {option_list {options_set ""}} {
    set the variables defined in option_list from the form provided 
    (form defaults to ad_conn form) or to default value from option_list if 
    not in the form data.
    <p>
    You only really need to call this if you need the variables 
    (for example to pick which select statement and table to actually use)
} {
    set out {}

    if {$option_list eq ""} {
        return
    }

    if {$options_set eq ""} {
        set options_set [ns_getform]
    }

    foreach option $option_list { 
        # find out what the current option value is.
        # check if a default is set otherwise the first value is used
        set option_key [lindex $option 0]
        set option_val {}
        # get the option from the form
        if { $options_set ne "" && [ns_set find $options_set $option_key] != -1} {
            uplevel [list set $option_key [ns_set get $options_set $option_key]]
        } else {
            uplevel [list set $option_key [lindex $option 2]]
        }
    }
}

ad_proc -deprecated ad_table { 
    {-Torder_target_url {}}
    {-Torderby {}}
    {-Tasc_order_img {^}}
    {-Tdesc_order_img {v}}
    {-Tmissing_text "<em>No data found.</em>"}
    {-Tsuffix {}}
    {-Tcolumns {}}
    {-Taudit {}}
    {-Trows_per_band 1}
    {-Tband_colors {{} "#ececec"}}
    {-Tband_classes {{even} {odd}}}
    {-Trows_per_page 0}
    {-Tmax_rows 0}
    {-Ttable_extra_html {cellpadding=3 cellspacing=0 class="table-display"}}
    {-Theader_row_extra {style="background-color:#f8f8f8" class="table-header"}}
    {-Ttable_break_html "<br><br>"}
    {-Tpre_row_code {}}
    {-Trow_code {[subst $Trow_default]}}
    {-Tpost_data_ns_sets {}}
    {-Textra_vars {}}
    {-Textra_rows {}}
    {-bind {}}
    {-dbn {}}
    statement_name sql_qry Tdatadef
} {

    DRB: New code should use the listbuilder.

    Note: all the variables in this function are named Tblah since we could potentially 
    have namespace collisions
    <p>
    build and return an html fragment given an active query and a data definition.
    <ul> 
    <li> sql_qry -- The query that should be executed to generate the table. <br> 
    You can specify an optional -bind argument to specify a ns_set of bind variables.
    <li> Tdatadef -- the table declaration.
    </ul>

    Datadef structure :
    <pre> 
    { 
        {column_id "Column_Heading" order_clause display_info}
        ...
    }
    </pre>
    <ul>
    <li> column_id -- what to set as orderby for sorting and also is 
         the default variable for the table cell.

    <li> the text for the heading to be wrapped in &lt;th&gt; and &lt;/th&gt; tags. 
         I am not entirely happy that things are wrapped automatically since you might not 
         want plain old th tags but I also don;t want to add another field in the structure.

    <li> order_clause -- the order clause for the field.  If null it defaults to 
         "column_id $order".  It is also interpolated, with orderby and order
         defined as variables so that:
         <pre>
             {upper(last_name) $order, upper(first_names) $order}
         </pre>
         would do the right thing.
         <p> 
         the value "no_sort" should be used for columns which should not allow sorting.
	 <p>
	 the value "sort_by_pos" should be used if the columns passed in
	 are column positions rather than column names.

    <li> display_info.  If this is a null string you just default to generating 
         &lt;td&gt;column_id&lt;/td&gt;.  If it is a string in the lookup list
         then special formatting is applied; this is l r c tf 01 for
         align=left right center, Yes/No (from tf), 
         Yes/No from 0/1.
          
         <p>
         if the display stuff is not any of the above then it is interpolated and the results 
         returned (w/o any &lt;td&gt; tags put in).
    An example:
    <pre>
    set table_def { 
        {ffn "Full Name" 
            {upper(last_name) $order, upper(first_names) $order}
            {&lt;td&gt;&lt;a href="/admin/users/one?user_id=$user_id"&gt;$first_names&nbsp;$last_name&lt;/a&gt;&lt;/td&gt;}}
        {email "e-Mail" {} {&lt;td&gt;&lt;a href="mailto:$email"&gt;$email&lt;/a&gt;}}
        {email_bouncing_p "e-Bouncing?" {} tf}
        {user_state "State" {} {}}
        {last_visit "Last Visit" {} r}
        {actions "Actions" no_sort {&lt;td&gt;
                &lt;a href="/admin/users/basic-info-update?user_id=$user_id"&gt;Edit Info&lt;/a&gt; | 
                &lt;a href="/admin/users/password-update?user_id=$user_id"&gt;New Password&lt;/a&gt; |
            [ad_registration_finite_state_machine_admin_links $user_state $user_id]}}
    }
    </pre>
    </ul>

    @param dbn The database name to use.  If empty_string, uses the default database.
} {

    set full_statement_name [db_qd_get_fullname $statement_name]

    # This procedure needs a full rewrite!
    db_with_handle -dbn $dbn Tdb {
	# Execute the query
        set selection [db_exec select $Tdb $full_statement_name $sql_qry]
	set Tcount 0
	set Tband_count 0
	set Tpage_count 0
	set Tband_color 0
	set Tband_class 0
	set Tn_bands [llength $Tband_colors]
	set Tn_band_classes [llength $Tband_classes]
	set Tform [ad_conn form]
	
	# export variables from calling environment
	if {$Textra_vars ne ""} {
	    foreach Tvar $Textra_vars {
		upvar $Tvar $Tvar
	    }
	}
	
	# get the current ordering information
	set Torderbykey {::not_sorted::}
	set Treverse {}
	regexp {^([^*,]+)([*])?} $Torderby match Torderbykey Treverse
	if {$Treverse eq "*"} {
	    set Torder desc
	} else { 
	    set Torder asc
	}
	
	# set up the target url for new sorts
	if {$Torder_target_url eq ""} {
	    set Torder_target_url [ad_conn url]
	}
	set Texport "[uplevel [list export_ns_set_vars url [list orderby$Tsuffix]]]&"
	if {$Texport == "&"} {
	    set Texport {}
	}
	set Tsort_url "$Torder_target_url?${Texport}orderby$Tsuffix="
	
	set Thtml {}
	set Theader {}
	
	# build the list of columns to display...
	set Tcolumn_list [ad_table_column_list $Tdatadef $Tcolumns]
	
	# generate the header code 
	#
	append Theader "<table $Ttable_extra_html>\n"
	if {$Theader_row_extra eq ""} {
	    append Theader "<tr>\n"
	} else {
	    append Theader "<tr $Theader_row_extra>\n"
	}
	foreach Ti $Tcolumn_list {
	    set Tcol [lindex $Tdatadef $Ti]
	    if { ( [ns_set find $selection [lindex $Tcol 0]] < 0
		   && ([lindex $Tcol 2] eq "" || [lindex $Tcol 2] ne "sort_by_pos")
		   )
		 || [lindex $Tcol 2] eq "no_sort" 
	     } {
		
		# not either a column in the select or has sort code
		# then just a plain text header so do not do sorty things
		append Theader " <th>[lindex $Tcol 1]</th>\n"
	    } else {
		if {[lindex $Tcol 0] eq $Torderbykey } {
		    if {$Torder eq "desc"} {
			set Tasord $Tasc_order_img
		    } else {
			set Tasord $Tdesc_order_img
		    }
		} else {
		    set Tasord {}
		}
		set href $Tsort_url[ns_urlencode [ad_new_sort_by [lindex $Tcol 0] $Torderby]]
		append Theader \
		    [subst { <th><a href="[ns_urlencode $href]">}] \
		    "\n[lindex $Tcol 1]</a>&nbsp;$Tasord</th>\n"
	    }
	}
	append Theader "</tr>\n"
	
	#
	# This has gotten kind of ugly.  Here we are looping over the 
	# rows returned and then potentially a list of ns_sets which can 
	# be passed in (grrr.  Richard Li needs for general protections stuff
	# for "fake" public record which does not exist in DB).
	# 
	
	set Tpost_data 0
	
	while { 1 } { 
	    if {!$Tpost_data && [ns_db getrow $Tdb $selection]} {     
		# in all its evil majesty
		set_variables_after_query
	    } else { 
		# move on to fake rows...
		incr Tpost_data
	    } 
	    
	    if { $Tpost_data && $Tpost_data <= [llength $Tpost_data_ns_sets] } { 
		# bind the Tpost_data_ns_sets row of the passed in data
		set_variables_after_query_not_selection [lindex $Tpost_data_ns_sets $Tpost_data-1]
	    } elseif { $Tpost_data } { 
		# past the end of the fake data drop out.
		break
	    }
	    
	    if { $Tmax_rows && $Tcount >= $Tmax_rows } {
		if { ! $Tpost_data } { 
		    # we hit max count and had rows left to read...
		    ns_db flush $Tdb
		}
		break
	    }
	    
	    # deal with putting in the header if need 
	    if { $Tcount == 0 } {
		append Thtml "$Theader"
	    } elseif { $Tpage_count == 0 }  { 
		append Thtml "</table>\n$Ttable_break_html\n$Theader"
	    }

	    # first check if we are in audit mode and if the audit columns have changed
	    set Tdisplay_changes_only 0
	    if {$Taudit ne "" && $Tcount > 0} { 
		# check if the audit key columns changed 
		foreach Taudit_key $Taudit { 
		    if {[set $Taudit_key] eq [set P$Taudit_key] } { 
			set Tdisplay_changes_only 1
		    }
		}
	    }

	    # this is for breaking on sorted field etc.
	    append Thtml [subst $Tpre_row_code]

	    if { ! $Tdisplay_changes_only } {
		# in audit mode a record spans multiple rows.
		incr Tcount
		incr Tband_count
	    }
	    incr Tpage_count

	    if { $Trows_per_page && $Tpage_count >= $Trows_per_page } { 
		set Tband_color 0
		set Tband_class 0
		set Tband_count 0
		set Tpage_count 0

	    }

            set Trow_default {}
	    # generate the row band color 
            if { $Tband_count >= $Trows_per_band } {
                set Tband_count 0
                set Tband_color [expr {($Tband_color + 1) % $Tn_bands} ]
                set Tband_class [expr {($Tband_class + 1) % $Tn_band_classes} ]
            }
            # do this check since we would like the ability to band with
            # page background as well
            if {$Tn_bands && [lindex $Tband_colors $Tband_color] ne ""} {
                append Trow_default " style=\"background-color:[lindex $Tband_colors $Tband_color]\""
            }
            if {$Tn_band_classes && [lindex $Tband_classes $Tband_class] ne ""} {
                append Trow_default " class=\"[lindex $Tband_classes $Tband_class]\""
            }

	    
            set Trow_default "<tr$Trow_default>"

	    append Thtml [subst $Trow_code]
	    
	    foreach Ti $Tcolumn_list {
		set Tcol [lindex $Tdatadef $Ti]
		# If we got some special formatting code we handle it
		# single characters r l c are special for alignment 
		set Tformat [lindex $Tcol 3]
		set Tcolumn [lindex $Tcol 0]
		switch $Tformat {
		    "" {set Tdisplay_field " <td>[set $Tcolumn]</td>\n"}
		    r {set Tdisplay_field " <td align=\"right\">[set $Tcolumn]</td>\n"}
		    l {set Tdisplay_field " <td align=\"left\">[set $Tcolumn]</td>\n"}
		    c {set Tdisplay_field " <td align=\"center\">[set $Tcolumn]</td>\n"}
		    tf {set Tdisplay_field " <td align=\"center\">[util_PrettyBoolean [set $Tcolumn]]</td>\n"}
		    01 {set Tdisplay_field " <td align=\"center\">[util_PrettyTclBoolean [set $Tcolumn]]</td>\n"}
		    bz {set Tdisplay_field " <td align=\"right\">&nbsp;[blank_zero [set $Tcolumn]]</td>\n"}
		    default {set Tdisplay_field " [subst $Tformat]\n"}
		}

		if { $Tdisplay_changes_only 
		     && $Tdisplay_field eq $Tlast_display($Ti) } { 
		    set Tdisplay_field {<td>&nbsp;</td>}
		} else { 
		    set Tlast_display($Ti) $Tdisplay_field
		} 
		append Thtml $Tdisplay_field
	    }

	    append Thtml "</tr>\n"

	    # keep the last row around so we can do fancy things.
	    # so on next row we can say things like if $Pvar != $var not blank
	    if { $Tpost_data && $Tpost_data <= [llength $Tpost_data_ns_sets] } { 
		# bind the Tpost_data_ns_sets row of the passed in data
		set_variables_after_query_not_selection [lindex $Tpost_data_ns_sets $Tpost_data-1] P
	    } else { 
		set_variables_after_query_not_selection $selection P
	    }
	}

	if { $Tcount > 0} {
	    append Thtml "$Textra_rows
</table>\n"
	} else { 
	    append Thtml $Tmissing_text
	}
    }    
    return $Thtml
}

ad_proc -deprecated ad_table_column_list {
    { -sortable all }
    datadef columns
} {
    build a list of pointers into the list of column definitions
    <p>
    returns a list of indexes into the columns one per column it found
    <p>
    -sortable from t/f/all 
} {
    set column_list {}
    if {$columns eq ""} {
        for {set i 0} {$i < [llength $datadef]} {incr i} {
            if {$sortable eq "all" 
                || ($sortable == "t" && [lindex $datadef $i 2] ne "no_sort")
                || ($sortable == "f" && [lindex $datadef $i 2] eq "no_sort")
            } {
                lappend column_list $i
            } 
        }
    } else { 
        set colnames {}
        foreach col $datadef { 
            if {$sortable eq "all" 
                || ($sortable == "t" && [lindex $col 2] ne "no_sort")
                || ($sortable == "f" && [lindex $col 2] eq "no_sort")
            } {
                lappend colnames [lindex $col 0]
            } else {
                # placeholder for invalid column
                lappend colnames "X+X"
            }
        }
        foreach col $columns {
            set i [lsearch $colnames $col]
            if {$i > -1} {
                lappend column_list $i
            }
        }
    }
    
    return $column_list
}

ad_proc -deprecated ad_sort_primary_key {orderby} {
    return the primary (first) key of an order spec
    used by 
} {
    if {[regexp {^([^*,]+)} $orderby match]} {
        return $match
    }
    return $orderby
}

ad_proc -deprecated ad_table_same varname {
    Called from inside ad_table.

    returns true if the variable has same value as
    on the previous row.  Always false for 1st row.

} {
    if { [uplevel set Tcount]
         && [uplevel string compare \$$varname \$P$varname] == 0} {
        return 1
    } else {
        return 0
    }
}
        
ad_proc -deprecated ad_table_span {str {td_html "align=\"left\""}} {
    given string the function generates a row which spans the 
    whole table.
} {
    return "<tr><td colspan=\"[uplevel llength \$Tcolumn_list]\" $td_html>$str</td></tr>"
}

ad_proc -deprecated ad_table_form {
    datadef 
    {type select} 
    {return_url {}} 
    {item_group {}} 
    {item {}} 
    {columns {}} 
    {allowed {}}
} {
    builds a form for chosing the columns to display 
    <p>
    columns is a list of the currently selected columns.
    <p>
    allowed is the list of all the displayable columns, if empty 
    all columns are allowed.
} {
    # first build a map of all available columns 
    set sel_list [ad_table_column_list $datadef $allowed]
    
    # build the map of currently selected columns 
    set sel_columns [ad_table_column_list $datadef $columns]
    
    set max_columns [llength $sel_list]
    set n_sel_columns [llength $sel_columns]

    set html {}
    if {$item eq "CreateNewCustom" } {
        set item {} 
    }
    # now spit out the form fragment.
    if {$item ne ""} {
        append html "<h2>Editing <strong>$item</strong></h2>"
        append html "<form method=\"get\" action=\"/tools/table-custom\">"
        append html "<input type=\"submit\" value=\"Delete this view\">"
        append html "<input type=\"hidden\" name=\"delete_the_view\" value=\"1\">"
        append html "[export_vars -form {item_group item}]"
        if {$return_url ne ""} {
            append html "[export_vars -form {return_url}]"
        }
        append html "</form>"
    }

    append html "<form method=get action=\"/tools/table-custom\">" 
    if {$return_url ne ""} {
        append html "[export_vars -form {return_url}]"
    }
    if {$item_group eq ""} {
        set item_group [ad_conn url]
    }

    append html "[export_vars -form {item_group}]"
    if {$item ne ""} {
        set item_original $item
        append html "[export_vars -form {item_original}]"
        append html "<input type=\"submit\" value=\"Save changes\">"
    } else {
        append html "<input type=\"submit\" value=\"Save new view\">"
    }

    append html "<table>"
    append html "<tr><th>Name:</th><td><input type=\"text\" size=\"60\" name=\"item\" [export_form_value item]></td></tr>"
    if {$item ne ""} {
        set item_original item
        append html "[export_vars -form {item_original}]"
        append html "<tr><td>&nbsp;</td><td><em>Editing the name will rename the view</em></td></tr>"
    }

    if {$type eq "select" } {
        # select table
        set options "<option value=\"\">---</option>"
        foreach opt $sel_list { 
            append options " <option value=\"[lindex $datadef $opt 0]\">[lindex $datadef $opt 1]</option>"
        }
    
        for {set i 0} { $i < $max_columns} {incr i} {
            if {$i < $n_sel_columns} {
                set match [lindex $datadef [lindex $sel_columns $i] 0]
                regsub "(<option )(value=\"$match\">)" $options "\\1 selected=\"selected\" \\2" out
            } else { 
                set out $options
            }
            append html "<tr><th>[expr {$i + 1}]</th><td><select name=\"col\">$out</select></td></tr>\n"
        }
    } else { 
        # radio button table
        append html "<tr><th>Col \#</th>"
        foreach opt $sel_list { 
            append html "<th>[lindex $datadef $opt 1]</th>"
        }
        append html "</tr>"

        foreach opt $sel_list { 
            append options "<td><input name=\"col_@@\" type=\"radio\" value=\"[lindex $datadef $opt 0]\"></td>"
        }
        for {set i 0} { $i < $max_columns} {incr i} {
            if {$i < $n_sel_columns} {
                set match [lindex $datadef [lindex $sel_columns $i] 0]
                regsub "( type=\"radio\" )(value=\"$match\">)" $options "\\1 checked=\"checked\" \\2" out
            } else { 
                set out $options
            }
            regsub -all {@@} $out $i out
            append html "<tr><th>[expr {$i + 1}]</th>$out</tr>\n"
        }
    }
    append html "</table></form>"

    return $html
}

ad_proc -deprecated ad_table_sort_form {
    datadef 
    {type select} 
    {return_url {}} 
    {item_group {}} 
    {item {}} 
    {sort_spec {}} 
    {allowed {}}
} {
    builds a form for setting up custom sorts.
    <p>
    <ul>
      <li> datadef is the table definition as in ad_table.
      <li> type is select or radio (only select is implemented now)
      <li> return_url is the return url passed through to the page that validates and saves the 
         sort customization.
      <li> item_group is a string identifying the customization "ticket_tracker_main_sort" for example.
      <li> item is the user entered identifier
      <li> sort_spec is the sort specifier as in ad_new_sort_by
      <li>  allowed is the list of all the columns allowed, if empty all are allowed.
    </ul>
    <p>
    An example from the ticket system: 
    <pre>
      ad_table_sort_form $tabledef select $return_url ticket_tracker_main_sort $ticket_sort $orderby
    </pre>
} {
    # first build a map of all available columns 
    set sel_list [ad_table_column_list -sortable t $datadef $allowed]
    
    # build the map of currently selected columns 
    set full_column [split $sort_spec ","]
    set sel_columns [list]
    set direction [list]
    foreach col $full_column {
        regexp {([^*,]+)([*])?} $col match coln dirn
        if {$dirn eq "*"} {
            set dirn desc
        } else {
            set dirn asc
        }
        lappend sel_columns $coln
        lappend direction $dirn
    }
    
    set max_columns 4
    set n_sel_columns [llength $sel_columns]

    set html {}
    if {$item eq "CreateNewCustom" } {
        set item {} 
    }
    # now spit out the form fragment.
    if {$item ne ""} {
        append html "<h2>Editing <strong>$item</strong></h2>"
        append html "<form method=\"get\" action=\"/tools/sort-custom\">"
        append html "<input type=\"submit\" value=\"Delete this sort\">"
        append html "<input type=\"hidden\" name=\"delete_the_sort\" value=\"1\">"
        append html "[export_vars -form {item_group item}]"
        if {$return_url ne ""} {
            append html "[export_vars -form {return_url}]"
        }
        append html "</form>"
    }

    append html "<form method=get action=\"/tools/sort-custom\">" 
    if {$return_url ne ""} {
        append html "[export_vars -form {return_url}]"
    }
    if {$item_group eq ""} {
        set item_group [ad_conn url]
    }

    append html "[export_vars -form {item_group}]"
    if {$item ne ""} {
        set item_original $item
        append html "[export_vars -form {item_original}]"
        append html "<input type=\"submit\" value=\"Save changes\">"
    } else {
        append html "<input type=\"submit\" value=\"Save new sort\">"
    }

    append html "<table>"
    append html "<tr><th>Name:</th><td><input type=\"text\" size=\"60\" name=\"item\" [export_form_value item]></td></tr>"
    if {$item ne ""} {
        set item_original item
        append html "[export_vars -form {item_original}]"
        append html "<tr><td>&nbsp;</td><td><em>Editing the name will rename the sort</em></td></tr>"
    }

    set options "<option value=\"\">---</option>"
    foreach opt $sel_list { 
        append options " <option value=\"[lindex $datadef $opt 0]\">[lindex $datadef $opt 1]</option>"
    }
    
    for {set i 0} { $i < $max_columns} {incr i} {
        if {$i < $n_sel_columns} {
            set match [lindex $sel_columns $i]
            regsub "(<option )(value=\"$match\">)" $options "\\1 selected=\"selected\" \\2" out
        } else { 
            set out $options
        }
        append html "<tr><th>[expr {$i + 1}]</th><td><select name=\"col\">$out</select>"
        switch [lindex $direction $i] {
            asc {
                append html "<select name=\"dir\"><option value=\"asc\" selected=\"selected\">increasing</option><option value=\"desc\">decreasing</option></select>"
            }
            default {
                append html "<select name=\"dir\"><option value=\"asc\">increasing</option><option value=\"desc\" selected=\"selected\">decreasing</option></select>"
         
            }
        }
        append html "\n</td></tr>\n"
    }
    append html "</table></form>"

    return $html
}

ad_proc ad_order_by_from_sort_spec {sort_by tabledef} {
    Takes a sort_by spec, and translates it into into an "order by" clause
    with each sort_by key dictated by the sort info in tabledef
} {
    set order_by_clause {}

    foreach sort_key_spec [split $sort_by ","] {
        if { [regexp {^([A-Za-z_0-9]+)(\*?)$} $sort_key_spec match sort_key reverse] } {
            # if there's a "*" after the key, we want to reverse the usual order
            foreach order_spec $tabledef {
                if { $sort_key == [lindex $order_spec 0] } {
                    if { $reverse eq "*" } {
                        set order "desc"
                    } else {
                        set order "asc"
                    }

                    if { $order_by_clause eq "" } {
                        append order_by_clause "\norder by "
                    } else {
                        append order_by_clause ", "
                    }

                    # tack on the order by clause 
                    if {[lindex $order_spec 2] ne "" && [lindex $order_spec 2] ne "sort_by_pos"} {
                        append order_by_clause "[subst [lindex $order_spec 2]]"
                    } else { 
                        append order_by_clause "$sort_key $order"
                    }
                    break
                }
            }
        }
    }
    return $order_by_clause
}

ad_proc -deprecated ad_new_sort_by {key keys} {
    Makes a new sort_by string, sorting by "key".

    If the key is followed by "*", that indicates the ordering should
    be reversed from the default ordering for that key.

    Old sort keys are retained, so the sort appears to be a little more stable.
    That is, suppose two things are sorted into an order, and their values for a
    different column are the same.  If that different column is used as the primary
    sort key to reorder, the things which have the same value for the newly-sorted
    column will remain in the same relative order.
} {
    if { $keys eq "" } {
        return $key

    } elseif { [regexp "^${key}(\\*?)," "$keys," match reverse] } {
        # if this was already the first key, then reverse order
        if { $reverse eq "*" } {
            regsub "\\*," "$keys," "," keys
        } else {
            regsub "," "$keys," "*," keys
        }
        regsub ",$" $keys "" keys
        return $keys
    } else {
        regsub ",$key\\*?," "$keys," "," keys
        regsub ",$" $keys "" keys
        return "$key,$keys"
    }
}

ad_proc ad_same_page_link {variable value text {form ""}} {
    Makes a link to this page, with a new value for "variable".
} {
    if { $form eq "" } {
        set form [ns_getform]
    }
    set url_vars [export_ns_set_vars url $variable $form]
    set href "[ad_conn url]?$variable=[ns_urlencode $value]$url_vars"
    return [subst {<a href="[ns_quotehtml $href]">[ns_quotehtml $text]</a>}]
}

ad_proc ad_reverse order { 
    returns the opposite sort order from the
    one it is given.  Mostly for columns whose natural 
    sort order is not the default.
} { 
    switch [string tolower $order] {
        desc {return asc}
        asc {return desc}
    }
    return $order
}

ad_proc ad_custom_load {user_id item_group item item_type} {
    load a persisted user customization as saved by 
    for example table-custom.tcl.
} { 
    
    if {
	![db_0or1row load_user_customization {
	    select value_type, value 
	    from user_custom 
	    where user_id = :user_id
	    and item_type = :item_type
	    and item_group = :item_group 
	    and  item = :item
	}]
    } {
	set value {}
    } 
    return $value
}
    
ad_proc ad_custom_list {user_id item_group item_set item_type target_url custom_url {new_string "new view"}} {
    Generates the html fragment for choosing, editing and creating
    user customized data
} {

    set items [db_list custom_list {
	select item from user_custom 
	where user_id = :user_id
	and item_type = :item_type
	and item_group = :item_group
    }]
    
    set break {}
    foreach item $items {
        if {$item_set eq $item } {
            append html "$break<strong>$item</strong>&nbsp;(<a href=\"[ns_quotehtml $custom_url$item]\">edit</a>)"
        } else { 
            append html "$break<a href=\"[ns_quotehtml $target_url$item]\">$item</a>"
        }
        set break " | "
    }
    append html "$break (<a href=\"[ns_quotehtml ${custom_url}CreateNewCustom]\">$new_string</a>)\n"
    
    return $html
}
    

ad_proc ad_custom_page_defaults {defaults} { 
    set the page defaults. If the form is 
    empty do a returnredirect with the defaults set
} {
    set form [ns_getform]
    if {$form eq "" 
        && $defaults ne ""} { 
        # we did not get a form so set all the variables 
        # and redirect to set them
        set redirect "[ad_conn url]?"
        set pre {}
        foreach kvp $defaults { 
            append redirect "$pre[lindex $kvp 0]=[ns_urlencode [lindex $kvp 1]]"
            set pre {&}
        }
        ad_returnredirect $redirect
        ad_script_abort
    }
    
    # we have a form so stuff in the ones we dont find.
    # should think about how to support lists and ns_set persist too.
    foreach kvp $defaults { 
        if {[ns_set find $form [lindex $kvp 0]] < 0} { 
            ns_set put $form [lindex $kvp 0] [lindex $kvp 1]
        }
    }
}

ad_proc ad_custom_form {return_url item_group item} { 
    sets up the head of a form to feed to /tools/form-custom.tcl
} {
    append html "<form method=\"get\" action=\"/tools/form-custom\">\n" 
    if {$return_url ne ""} {
        append html "[export_vars -form {return_url}]\n"
    }
    if {$item_group eq ""} {
        set item_group [ad_conn url]
    }
    set item_original $item
    append html "[export_vars -form {item_group item item_original}]\n"
    append html "<input type=\"submit\" value=\"Save settings\">"
}

ad_proc ad_dimensional_settings {define current} {
    given a dimensional slider definition this routine returns a form to set the 
    defaults for the given slider.

    NB...this does not close either the table or the form...
} {
    foreach opt $define { 
        append html "<tr><th align=\"left\">[lindex $opt 1]</th><td>"
        append html "<select name=\"[lindex $opt 0]\">"
        #append html "<option value=\"\">-- Unset --</option>"
        if {$current ne "" 
            && [ns_set find $current [lindex $opt 0]] > -1} { 
            set picked [ns_set get $current [lindex $opt 0]]
        } else {
	    set picked [lindex $opt 2]
	}
        foreach val [lindex $opt 3] { 
            if {$picked eq [lindex $val 0] } { 
                append html "<option selected=\"selected\" value=\"[ad_quotehtml [lindex $val 0]]\">[lindex $val 1]</option>\n"
            } else { 
                append html "<option value=\"[ad_quotehtml [lindex $val 0]]\">[lindex $val 1]</option>\n"
            }
        }
        append html "</select></td></tr>\n"
    }
    return $html
}

ad_proc -deprecated ad_table_orderby_sql {datadef orderby order} {
    create the order by clause consistent with the orderby and order variables
    and the datadef which built the table
} {
    set orderclause "order by $orderby $order"
    foreach col $datadef {
        if {$orderby eq [lindex $col 0] } {
            if {[lindex $col 2] ne ""} {
                set orderclause [subst [lindex $col 2]]
            }
        }
    }
    return $orderclause
}        

