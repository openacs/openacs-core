ad_library {

    Provides a variety of non-ACS-specific utilities, including
    the procs to support the who's online feature.

    @author Various (acs@arsdigita.com)
    @creation-date 13 April 2000
    @cvs-id utilities-procs.tcl,v 1.19.2.18 2003/06/06 21:40:37 donb Exp
}

namespace eval util {}

# Let's define the nsv arrays out here, so we can call nsv_exists
# on their keys without checking to see if it already exists.
# we create the array by setting a bogus key.

proc proc_source_file_full_path {proc_name} {
    if { ![nsv_exists proc_source_file $proc_name] } {
	return ""
    } else {
	set tentative_path [nsv_get proc_source_file $proc_name]
	regsub -all {/\./} $tentative_path {/} result
	return $result
    }
}

proc_doc util_report_library_entry {{extra_message ""}} "Should be called at beginning of private Tcl library files so that it is easy to see in the error log whether or not private Tcl library files contain errors." {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Loading $scrubbed_path"
    } else {
	set message "Loading $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

proc_doc check_for_form_variable_naughtiness { 
    name 
    value 
} {
    stuff to process the data that comes 
    back from the users

    if the form looked like
    <input type=text name=yow> and <input type=text name=bar> 
    then after you run this function you'll have Tcl vars 
    $foo and $bar set to whatever the user typed in the form

    this uses the initially nauseating but ultimately delicious
    tcl system function "uplevel" that lets a subroutine bash
    the environment and local vars of its caller.  It ain't Common Lisp...

    This is an ad-hoc check to make sure users aren't trying to pass in
    "naughty" form variables in an effort to hack the database by passing
    in SQL. It is called in all instances where a Tcl variable
    is set from a form variable.

    Checks the given variable for against known form variable exploits.
    If it finds anything objectionable, it throws an error.
} {
    # security patch contributed by michael@cleverly.com
    if { [string match "QQ*" $name] } {
        error "Form variables should never begin with QQ!"
    }

    # contributed by michael@cleverly.com
    if { [string match Vform_counter_i $name] } {
        error "Vform_counter_i not an allowed form variable"
    }

    # The statements below make ACS more secure, because it prevents
    # overwrite of variables from something like set_the_usual_form_variables
    # and it will be better if it was in the system. Yet, it is commented
    # out because it will cause an unstable release. To add this security
    # feature, we will need to go through all the code in the ACS and make
    # sure that the code doesn't try to overwrite intentionally and also
    # check to make sure that when tcl files are sourced from another proc,
    # the appropriate variables are unset.  If you want to install this
    # security feature, then you can look in the release notes for more info.
    # 
    # security patch contributed by michael@cleverly.com,
    # fixed by iwashima@arsdigita.com
    #
    # upvar 1 $name name_before
    # if { [info exists name_before] } {
    # The variable was set before the proc was called, and the
    # form attempts to overwrite it
    # error "Setting the variables from the form attempted to overwrite existing variable $name"
    # }
    
    # no naughtiness with uploaded files (discovered by ben@mit.edu)
    # patch by richardl@arsdigita.com, with no thanks to
    # jsc@arsdigita.com.
    if { [string match "*tmpfile" $name] } {
        set tmp_filename [ns_queryget $name]

        # ensure no .. in the path
        ns_normalizepath $tmp_filename

        set passed_check_p 0

        # check to make sure path is to an authorized directory
        set tmpdir_list [ad_parameter_all_values_as_list TmpDir]
        if { [empty_string_p $tmpdir_list] } {
            set tmpdir_list [list "/var/tmp" "/tmp"]
        }

        foreach tmpdir $tmpdir_list {
            if { [string match "$tmpdir*" $tmp_filename] } {
                set passed_check_p 1
                break
            }
        }

        if { !$passed_check_p } {
            error "You specified a path to a file that is not allowed on the system!"
        }
    
    }

    # integrates with the ad_set_typed_form_variable_filter system
    # written by dvr@arsdigita.com

    # see if this is one of the typed variables
    global ad_typed_form_variables    

    if { [info exists ad_typed_form_variables] } { 

        foreach typed_var_spec $ad_typed_form_variables {
            set typed_var_name [lindex $typed_var_spec 0]
        
            if { ![string match $typed_var_name $name] } {
                # no match. Go to the next variable in the list
                continue
            }
        
            # the variable matched the pattern
            set typed_var_type [lindex $typed_var_spec 1]
        
            if { [string match "" $typed_var_type] } {
                # if they don't specify a type, the default is 'integer'
                set typed_var_type integer
            }

            set variable_safe_p [ad_var_type_check_${typed_var_type}_p $value]
        
            if { !$variable_safe_p } {
                ns_returnerror 500 "variable $name failed '$typed_var_type' type check"
                ns_log Error "check_for_form_variable_naughtiness: [ad_conn url] called with \$$name = $value"
                error "variable $name failed '$typed_var_type' type check"
            }

            # we've found the first element in the list that matches,
            # and we don't want to check against any others
            break
        }
    }
}



ad_proc -private DoubleApos {string} {
    if the user types "O'Malley" and you try to insert that into an SQL
    database, you will lose big time because the single quote is magic
    in SQL and the insert has to look like 'O''Malley'.
    <p>
    You should be using bind variables rather than 
    calling DoubleApos
    
    @return string with single quotes converted to a pair of single quotes
} { 
    regsub -all ' "$string" '' result
    return $result
}



# debugging kludges

ad_proc -public NsSettoTclString {set_id} {
    returns a plain text version of the passed ns_set id
} { 
    set result ""
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	append result "[ns_set key $set_id $i] : [ns_set value $set_id $i]\n"
    }
    return $result
}

ad_proc -public get_referrer {} {
    gets the Referer for the headers
} { 
    return [ns_set get [ad_conn headers] Referer]
}

##
#  Database-related code
##

ad_proc ad_dbclick_check_dml { 
    {
	-bind  ""
    }
    statement_name table_name id_column_name generated_id return_url insert_dml 
} {
    This proc is used for pages using double click protection. table_name
    is table_name for which we are checking whether the double click
    occured. id_column_name is the name of the id table
    column. generated_id is the generated id, which is supposed to have
    been generated on the previous page. return_url is url to which this 
    procedure will return redirect in the case of successful insertion in
    the database. insert_sql is the sql insert statement. if data is ok
    this procedure will insert data into the database in a double click
    safe manner and will returnredirect to the page specified by
    return_url. if database insert fails, this procedure will return a
    sensible error message to the user.
} {
    if { [catch {
	if { ![empty_string_p $bind] } {
	    	db_dml $statement_name $insert_dml -bind $bind
	} else {
	    db_dml $statement_name $insert_dml 
	}
    } errmsg] } {
	# Oracle choked on the insert
	
	# detect double click
        if {
	    [db_0or1row double_click_check "
		
		select 1 as one
		from $table_name
		where $id_column_name = :generated_id
		
	    " -bind [ad_tcl_vars_to_ns_set generated_id]]
	} {
	    ad_returnredirect $return_url
	    return
	}
	
	ns_log Error "[info script] choked. Oracle returned error:  $errmsg"

	ad_return_error "Error in insert" "
	We were unable to do your insert in the database. 
	Here is the error that was returned:
	<p>
	<blockquote>
	<pre>
	$errmsg
	</pre>
	</blockquote>
        </p>"
	return
    }

    ad_returnredirect $return_url
    # should this be ad_script_abort?  Should check how its being used.
    return
}

ad_proc -public util_AnsiDatetoPrettyDate {sql_date} { 
    Converts 1998-09-05 to September 5, 1998
} {
    set sql_date [string range $sql_date 0 9]
    if { ![regexp {(.*)-(.*)-(.*)$} $sql_date match year month day] } {
	return ""
    } else {
	set allthemonths {January February March April May June July August September October November December}

	# we have to trim the leading zero because Tcl has such a 
	# brain damaged model of numbers and decided that "09-1"
	# was "8.0"

	set trimmed_month [string trimleft $month 0]
	set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

	set trimmed_day [string trimleft $day 0]

	return "$pretty_month $trimmed_day, $year"
    }
}

ad_proc -public remove_nulls_from_ns_set {old_set_id} {
    Creates and returns a new ns_set without any null value fields

    @return new ns_set 
} {
    set new_set_id [ns_set new "no_nulls$old_set_id"]

    for {set i 0} {$i<[ns_set size $old_set_id]} {incr i} {
	if { [ns_set value $old_set_id $i] != "" } {

	    ns_set put $new_set_id [ns_set key $old_set_id $i] [ns_set value $old_set_id $i]

	}

    }

    return $new_set_id

}

ad_proc -public merge_form_with_query {
    {
	-bind {}
    }
    form statement_name sql_qry 
} {
    Merges a form with a query string.

    @param form the form to be stuffed.
    @param statement_name An identifier for the sql_qry to be executed.
    @param sql_qry The sql that must be executed.
    @param bind A ns_set stuffed with bind variables for the sql_qry.
} {
    set set_id [ns_set create]

    ns_log debug "merge_form_with_query: statement_name = $statement_name"
    ns_log debug "merge_form_with_query: sql_qry = $sql_qry"
    ns_log debug "merge_form_with_query: set_id = $set_id"

    db_0or1row $statement_name $sql_qry -bind $bind -column_set set_id
    
    if { $set_id != "" } {
	
	for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	    set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
	}
	
    }
    return $form    
}




proc util_PrettyBoolean {t_or_f { default  "default" } } {
    if { $t_or_f == "t" || $t_or_f == "T" } {
	return "Yes"
    } elseif { $t_or_f == "f" || $t_or_f == "F" } {
	return "No"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Unknown (\"$t_or_f\")"
	} else {
	    return $default
	}
    }
}

proc_doc util_PrettyTclBoolean {zero_or_one} "Turns a 1 (or anything else that makes a Tcl IF happy) into Yes; anything else into No" {
  if {$zero_or_one} {
	return "Yes"
    } else {
	return "No"
    }
}

ad_proc -public randomInit {seed} {
    seed the random number generator.
} {
    nsv_set rand ia 9301
    nsv_set rand ic 49297
    nsv_set rand im 233280
    nsv_set rand seed $seed
}


ad_proc -public random {} {
    Return a pseudo-random number between 0 and 1.
} {
    nsv_set rand seed [expr {([nsv_get rand seed] * [nsv_get rand ia] + [nsv_get rand ic]) % [nsv_get rand im]}]
    return [expr {[nsv_get rand seed]/double([nsv_get rand im])}]
}

ad_proc -public randomRange {range} {
    Returns a pseudo-random number between 0 and range.

    @return integer
} {
    return [expr {int([random] * $range)}]
}

ad_proc -public db_html_select_options { 
    { -bind "" }
    { -select_option "" }
    stmt_name
    sql
} {

    Generate html option tags for an html selection widget. If select_option
    is passed, this option will be marked as selected.

    @author yon [yon@arsdigita.com]

} {

    set select_options ""

    if { ![empty_string_p $bind] } {
	set options [db_list $stmt_name $sql -bind $bind]
    } else {
	set options [db_list $stmt_name $sql]
    }

    foreach option $options {
	if { [string compare $option $select_option] == 0 } {
	    append select_options "<option selected=\"selected\">$option</option>\n"
	} else {
	    append select_options "<option>$option</option>\n"
	}
    }
    return $select_options

}

ad_proc -public db_html_select_value_options {
    { -bind "" }
    { -select_option [list] }
    { -value_index 0 }
    { -option_index 1 }
    stmt_name
    sql
} {

    Generate html option tags with values for an html selection widget. if
    select_option is passed and there exists a value for it in the values
    list, this option will be marked as selected. select_option can be passed 
    a list, in which case all options matching a value in the list will be 
    marked as selected. 

    @author yon [yon@arsdigita.com]

} {
    set select_options ""

    if { ![empty_string_p $bind] } {
	set options [db_list_of_lists $stmt_name $sql -bind $bind]
    } else {
	set options [uplevel [list db_list_of_lists $stmt_name $sql]]
    }

    foreach option $options {
	if { [lsearch -exact $select_option [lindex $option $value_index]] >= 0 } {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\" selected=\"selected\">[lindex $option $option_index]</option>\n"
	} else {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\">[lindex $option $option_index]</option>\n"
	}
    }
    return $select_options

}


#####
#
# Export Procs
#
#####



ad_proc -public export_vars {
    -sign:boolean
    -form:boolean
    -url:boolean
    -quotehtml:boolean
    -entire_form:boolean
    -no_empty:boolean
    {-base}
    {-anchor}
    {-exclude {}}
    {-override {}}
    {vars {}}
} {
    Exports variables either in URL or hidden form variable format. It should replace 
    <a
    href="/api-doc/proc-view?proc=export_form_vars"><code>export_form_vars</code></a>,
    <a
    href="/api-doc/proc-view?proc=export_url_vars"><code>export_url_vars</code></a>
    and all their friends.

    <p>

    Example usage: <code>[export_vars -form { foo bar baz }]</code>

    <p>
    
    This will export the three variables <code>foo</code>, <code>bar</code> and <code>baz</code> as 
    hidden HTML form fields. It does exactly the same as <code>[export_form_vars foo bar baz]</code>.

    <p>

    Example usage: <code>[export_vars -url -sign -override {{foo "new value"}} -exclude { bar } { foo bar baz }]</code>

    <p>

    This will export a variable named <code>foo</code> with the value "new value" and a variable named <code>baz</code>
    with the value of <code>baz</code> in the caller's environment. Since we've specified that <code>bar</code> should be 
    excluded, <code>bar</code> won't get exported even though it's specified in the last argument. Additionally, even though 
    <code>foo</code> is specified also in the last argument, the value we use is the one given in the <code>override</code>
    argument. Finally, both variables are signed, because we specified the <code>-sign</code> switch.

    <p>

    You can specify variables with <b>three different precedences</b>, namely
    <b><code>override</code>, <code>exclude</code> or <code>vars</code></b>. If a variable is present in <code>override</code>,
    that's what'll get exported, no matter what. If a variable is in <code>exclude</code> and not in <code>override</code>, 
    then it will <em>not</em> get output. However, if it is in <code>vars</code> and <em>not</em> in either of 
    <code>override</code> or <code>exclude</code>, then it'll get output. In other words, we check <code>override</code>, 
    <code>exclude</code> and <code>vars</code> in that order of precedence.

    <p>

    The two variable specs, <b><code>vars</code> and <code>override</code></b> both look the same: They take a list of 
    variable specs. Examples of variable specs are:

    <ul>
    <li>foo
    <li>foo:multiple,sign
    <li>{foo "the value"}
    <li>{foo {[my_function arg]}}
    <li>{foo:array,sign {[array get my_array]}}
    </ul>

    In general, there's one or two elements. If there are two, the second element is the value we should use. If one, 
    we pull the value from the variable of the same name in the caller's environment. Note that when you specify the 
    value directly here, we call <a href="http://dev.scriptics.com/man/tcl8.3/TclCmd/subst.htm"><code>subst</code></a>
    on it, so backslashes, square brackets and variables will get substituted correctly. Therefore, make sure you use 
    curly braces to surround this instead of the <code>[list]</code> command; otherwise the contents will get substituted 
    twice, and you'll be in trouble.

    <p>

    Right after the name, you may specify a colon and some flags, separated by commas. Valid flags are:

    <dl>
    
    <dt><b>multiple</b></dt>
    <dd>
    Treat the value as a list and output each element separately.
    </dd>

    <dt><b>array</b></dt>
    <dd>
    The value is an array and should be exported in a way compliant with the <code>:array</code> flag of 
    <a href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>, which means
    that each entry will get output as <code>name.key=value</code>.
    <p>
    If you don't specify a value directly, but want it pulled out of the Tcl environment, then you don't 
    need to specify <code>:array</code>. If you do, and the variable is in fact not an array, an error will
    be thrown.
    <p>
    </dd>

    <dt><b>sign</b></dt>
    <dd>
    Sign this variable. This goes hand-in-hand with the <code>:verify</code> flag of
    <a href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a> and 
    makes sure that the value isn't tampered with on the client side. The <code>-sign</code> 
    switch to <code>export_vars</code>, is a short-hand for specifying the <code>:sign</code> switch 
    on every variable.
    </dd>

    </dl>

    The argument <b><code>exclude</code></b> simply takes a list of names of variables that you don't 
    want exported, even though they're specified in <code>vars</code>.

    <p>

    <b>Intended use:</b> A page may have a set of variables that it cares about. You can store this in
    a variable once and pass that to <code>export_vars</code> like this:

    <p><blockquote>
    <code>set my_vars { user_id sort_by filter_by  }<br>
    ... [export_vars $my_vars] ...</code>
    </blockquote><p>

    Then, say one of them contains a column to filter on. When you want to clear that column, you can say
    <code>[export_vars -exclude { filter_by } $my_vars]</code>.

    <p>

    Similarly, if you want to change the sort order, you can say 
    <code>[export_vars -override { { sort_by $column } } $my_vars]</code>, and sorting will be done according to
    the new value of <code>column</code>.

    <p>
  
    If the variable name contains a colon (:), that colon must be escaped with a backslash, 
    so for example "form:id" becomes "form\:id". Sorry.
    
    @param sign Sign all variables.

    @param url Export in URL format. This is the default.
    
    @param form Export in form format. You can't specify both URL and form format.

    @param quotehtml HTML quote the entire resulting string. This is an interim solution 
    while we're waiting for the templating system to do the quoting for us.

    @param entire_form Export the entire form from the GET query string or the POST.

    @option no_empty If specified, variables with an empty string value will be suppressed from being exported.
                     This avoids cluttering up the URLs with lots of unnecessary variables.
    
    @option base The base URL to make a link to. This will be prepended to the query string 
                 along with a question mark (?), if the query is non-empty. so the returned
                 string can be used directly in a link. This is only relevant to URL export.

    @author Lars Pind (lars@pinds.com)
    @creation-date December 7, 2000
} {
    
    if { $form_p && $url_p } {
	return -code error "You must select either form format or url format, not both."
    }

    # default to URL format
    if { !$form_p && !$url_p } {
	set url_p 1
    }

    # 'noprocessing_vars' is yet another container of variables, 
    # only this one doesn't have the values subst'ed
    # and we don't try to find :multiple and :array flags in the namespec
    set noprocessing_vars [list]

    if { $entire_form_p } {
        set the_form [ns_getform]
        if { ![empty_string_p $the_form] } {
            for { set i 0 } { $i < [ns_set size $the_form] } { incr i } {
                set varname [ns_set key $the_form $i]
                set varvalue [ns_set value $the_form $i]
                lappend noprocessing_vars [list $varname $varvalue]
            }
        }
    }
    

    #####
    # 
    # Parse the arguments
    #
    #####
    
    # 1. if they're in override, use those
    # 2. if they're in vars, but not in exclude or override, use those
    
    # There'll always be an entry here if the variable is to be exported
    array set exp_precedence_type [list]

    # This contains entries of the form exp_flag(name:flag) e.g., exp_flag(foo:multiple)
    array set exp_flag [list]

    # This contains the value if provided, otherwise we'll pull it out of the caller's environment
    array set exp_value [list]

    foreach precedence_type { override exclude vars noprocessing_vars } {
	foreach var_spec [set $precedence_type] {
	    if { [llength $var_spec] > 2 } {
		return -code error "A varspec must have either one or two elements."
	    }

            if { ![string equal $precedence_type "noprocessing_vars"] } {
                # Hide escaped colons for below split
                regsub -all {\\:} $var_spec "!!cOlOn!!" var_spec
                
                set name_spec [split [lindex $var_spec 0] ":"]
                
                # Replace escaped colons with single colon
                regsub -all {!!cOlOn!!} $name_spec ":" name_spec

                set name [lindex $name_spec 0]
            } else {
                set name [lindex $var_spec 0]
                # Nothing after the colon, since we don't interpret any colons
                set name_spec [list $name {}]
            }

	    # If we've already encountered this varname, ignore it
	    if { ![info exists exp_precedence_type($name)] } {

		set exp_precedence_type($name) $precedence_type

		if { ![string equal $precedence_type "exclude"] } {

		    set flags [split [lindex $name_spec 1] ","]
		    foreach flag $flags {
			set exp_flag($name:$flag) 1
		    }
		    
		    if { $sign_p } {
			set exp_flag($name:sign) 1
		    }
		    
		    if { [llength $var_spec] > 1 } {
                        if { ![string equal $precedence_type "noprocessing_vars"] } {
                            set value [uplevel subst \{[lindex $var_spec 1]\}]
                        } else {
                            set value [lindex $var_spec 1]
                        }
                        set exp_value($name) $value
                        # If the value is specified explicitly, we include it even if the value is empty
		    } else {
			upvar 1 $name upvar_variable
			if { [info exists upvar_variable] } {
			    if { [array exists upvar_variable] } {
                                if { $no_empty_p } {
                                    # If the no_empty_p flag is set, remove empty string values first
                                    set exp_value($name) [list]
                                    foreach { key value } [array get upvar_variable] {
                                        if { ![empty_string_p $value] } {
                                            lappend exp_value($name) $key $value
                                        }
                                    }
                                } else {
                                    # If no_empty_p isn't set, just do an array get
                                    set exp_value($name) [array get upvar_variable]
                                }
				set exp_flag($name:array) 1
			    } else {
				if { [info exists exp_flag($name:array)] } {
				    return -code error "Variable \"$name\" is not an array"
				}
                                if { !$no_empty_p } {
                                    set exp_value($name) $upvar_variable
                                } else {
                                    # no_empty_p flag set, remove empty strings
                                    if { [info exists exp_flag($name:multiple)] } {
                                        # This is a list, remove empty entries
                                        set exp_value($name) [list]
                                        foreach elm $upvar_variable {
                                            if { ![empty_string_p $elm] } {
                                                lappend exp_value($name) $elm
                                            }
                                        }
                                    } else {
                                        # Simple value, this is easy
                                        if { ![empty_string_p $upvar_variable] } {
                                            set exp_value($name) $upvar_variable
                                        }
                                    }
                                }
			    }
			}
		    }
		}
	    }
	}
    }

    #####
    #
    # Put the variables into the export_set
    #
    #####
    
    # We use an ns_set, because there may be more than one entry with the same name
    set export_set [ns_set create]

    foreach name [array names exp_precedence_type] {
	if { ![string equal $exp_precedence_type($name) "exclude"] } {
	    if { [info exists exp_value($name)] } {
		if { [info exists exp_flag($name:array)] } {
		    if { [info exists exp_flag($name:multiple)] } {
			foreach { key value } $exp_value($name) {
			    foreach item $value {
				ns_set put $export_set "${name}.${key}" $item
			    }
			}
		    } else {
			foreach { key value } $exp_value($name) {
			    ns_set put $export_set "${name}.${key}" $value
			}
		    }
		    if { [info exists exp_flag($name:sign)] } { 

                        # DRB: array get does not define the order in which elements are returned,
                        # meaning that arrays constructed in different ways can have different
                        # signatures unless we sort the returned list.  I ran into this the
                        # very first time I tried to sign an array passed to a page that used
                        # ad_page_contract to verify the veracity of the parameter.

			ns_set put $export_set "$name:sig" [ad_sign [lsort $exp_value($name)]]

		    }
		} else {
		    if { [info exists exp_flag($name:multiple)] } {
			foreach item $exp_value($name) {
			    ns_set put $export_set $name $item
			}
		    } else {
			ns_set put $export_set $name "$exp_value($name)"
		    }
		    if { [info exists exp_flag($name:sign)] } {
			ns_set put $export_set "$name:sig" [ad_sign $exp_value($name)]
		    }
		}
	    }
	}
    }
    
    #####
    #
    # Translate it into the appropriate format
    #
    #####
    
    set export_size [ns_set size $export_set]
    set export_string {}
    
    if { $url_p } {
	set export_list [list]
	for { set i 0 } { $i < $export_size } { incr i } {
	    lappend export_list "[ns_urlencode [ns_set key $export_set $i]]=[ns_urlencode [ns_set value $export_set $i]]"
	}
	set export_string [join $export_list "&"]
    } else {
	for { set i 0 } { $i < $export_size } { incr i } {
	    append export_string "<input type=\"hidden\" name=\"[ad_quotehtml [ns_set key $export_set $i]]\" value=\"[ad_quotehtml "[ns_set value $export_set $i]"]\" >\n"
	}
    }

    if { $quotehtml_p } {
	set export_string [ad_quotehtml $export_string]
    }

    # Prepend with the base URL
    if { [exists_and_not_null base] } {
        if { ![empty_string_p $export_string] } {
            if { [regexp {\?} $base] } {
                # The base already has query vars
                set export_string "${base}&${export_string}"
            } else { 
                # The base has no query vars
                set export_string "$base?$export_string"
            }
        } else {
            set export_string $base
        }
    }
    
    # Append anchor
    if { [exists_and_not_null anchor] } {
        append export_string "\#$anchor"
    }
    
    return $export_string
}



ad_proc -deprecated ad_export_vars { 
    -form:boolean
    {-exclude {}}
    {-override {}}
    {include {}}
} {
    <b><em>Note</em></b> This proc is deprecated in favor of 
    <a href="/api-doc/proc-view?proc=export_vars"><code>export_vars</code></a>. They're very similar, but 
    <code>export_vars</code> have a number of advantages:
    
    <ul>
    <li>It can sign variables (the the <code>:sign</code> flag)
    <li>It can export variables as a :multiple.
    <li>It can export arrays with on-the-fly values (not pulled from the environment)
    </ul>

    It doesn't have the <code>foo(bar)</code> syntax to pull a single value from an array, however, but
    you can do the same by saying <code>export_vars {{foo.bar $foo(bar)}}</code>.

    <p>

    Helps export variables from one page to the next, 
    either as URL variables or hidden form variables.
    It'll reach into arrays and grab either all values or individual values
    out and export them in a way that will be consistent with the 
    ad_page_contract :array flag.
    
    <p>

    Example:

    <blockquote><pre>doc_body_append [ad_export_vars { msg_id user(email) { order_by date } }]</pre></blockquote>
    will export the variable <code>msg_id</code> and the value <code>email</code> from the array <code>user</code>,
    and it will export a variable named <code>order_by</code> with the value <code>date</code>.

    <p>
    
    The args is a list of variable names that you want exported. You can name 

    <ul>
    <li>a scalar varaible, <code>foo</code>,
    <li>the name of an array, <code>bar</code>, 
    in which case all the values in that array will get exported, or
    <li>an individual value in an array, <code>bar(baz)</code>
    <li>a list in [array get] format { name value name value ..}.
    The value will get substituted normally, so you can put a computation in there.
    </ul>

    <p>

    A more involved example:
    <blockquote><pre>set my_vars { msg_id user(email) order_by }
doc_body_append [ad_export_vars -override { order_by $new_order_by } $my_vars]</pre></blockquote>

    @param form set this parameter if you want the variables exported as hidden form variables,
    as opposed to URL variables, which is the default.

    @param exclude takes a list of names of variables you don't want exported, even though 
    they might be listed in the args. The names take the same form as in the args list.

    @param override takes a list of the same format as args, which will get exported no matter
    what you have excluded.

    @author Lars Pind (lars@pinds.com)
    @creation-date 21 July 2000

    @see export_vars
} {

    ####################
    #
    # Build up an array of values to export
    #
    ####################

    array set export [list]

    set override_p 0
    foreach argument { include override } {
	foreach arg [set $argument] {
	    if { [llength $arg] == 1 } { 
		if { $override_p || [lsearch -exact $exclude $arg] == -1 } {
		    upvar $arg var
		    if { [array exists var] } {
			# export the entire array
			foreach name [array names var] {
			    if { $override_p || [lsearch -exact $exclude "${arg}($name)"] == -1 } {
				set export($arg.$name) $var($name)
			    }
			}
		    } elseif { [info exists var] } {
			if { $override_p || [lsearch -exact $exclude $arg] == -1 } {
			    # if the var is part of an array, we'll translate the () into a dot.
			    set left_paren [string first ( $arg]
			    if { $left_paren == -1 } {
				set export($arg) $var
			    } else {
				# convert the parenthesis into a dot before setting
				set export([string range $arg 0 [expr { $left_paren - 1}]].[string \
					range $arg [expr { $left_paren + 1}] end-1]) $var
			    }
			}
		    }
		}
	    } elseif { [llength $arg] %2 == 0 } {
		foreach { name value } $arg {
		    if { $override_p || [lsearch -exact $exclude $name] == -1 } {
			set left_paren [string first ( $name]
			if { $left_paren == -1 } {
			    set export($name) [lindex [uplevel list \[subst [list $value]\]] 0]
			} else {
			    # convert the parenthesis into a dot before setting
			    set export([string range $arg 0 [expr { $left_paren - 1}]].[string \
				    range $arg [expr { $left_paren + 1}] end-1]) \
				    [lindex [uplevel list \[subst [list $value]\]] 0]
			}
		    }
		}
	    } else {
		return -code error "All the exported values must have either one or an even number of elements"
	    }
	}
	incr override_p
    }
    
    ####################
    #
    # Translate this into the desired output form
    #
    ####################

    if { !$form_p } {
	set export_list [list]
	foreach varname [array names export] {
	    lappend export_list "[ns_urlencode $varname]=[ns_urlencode $export($varname)]"
	}
	return [join $export_list &]
    } else {
	set export_list [list]
	foreach varname [array names export] {
	    lappend export_list "<input type=\"hidden\" name=\"[ad_quotehtml $varname]\"\
		    value=\"[ad_quotehtml $export($varname)]\" >"
	}
	return [join $export_list \n]
    }
}





ad_proc -deprecated export_form_vars { 
    -sign:boolean
    args 
} {
    Exports a number of variables as hidden input fields in a form.
    Specify a list of variable names. The proc will reach up in the caller's name space
    to grab the value of the variables. Variables that are not defined are silently ignored.
    You can append :multiple to the name of a variable. In this case, the value will be treated as a list,
    and each of the elements output separately.
    <p>
    export_vars is now the prefered interface.
    <p>

    Example usage: <code>[export_form_vars -sign foo bar:multiple baz]</code>

    @param sign If this flag is set, all the variables output will be
    signed using <a
    href="/api-doc/proc-view?proc=ad_sign"><code>ad_sign</code></a>. These variables should then be
    verified using the :verify flag to <a
    href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>,
    which in turn uses <a
    href="/api-doc/proc-view?proc=ad_verify_signature"><code>ad_verify_signature</code></a>. This
    ensures that the value hasn't been tampered with at the user's end.

    @see export_vars
} { 
    set hidden ""
    foreach var_spec $args {
	set var_spec_pieces [split $var_spec ":"]
	set var [lindex $var_spec_pieces 0]
	set type [lindex $var_spec_pieces 1]
	upvar 1 $var value
	if { [info exists value] } {
	    switch $type {
		multiple {
		    foreach item $value {
			append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $var]\" value=\"[ad_quotehtml $item]\" >\n"
		    }
		}
		default {
		    append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $var]\" value=\"[ad_quotehtml $value]\" >\n"
		}
	    }
	    if { $sign_p } {
		append hidden "<input type=\"hidden\" name=\"[ad_quotehtml "$var:sig"]\" value=\"[ad_quotehtml [ad_sign $value]]\" >\n"
	    }
	}
    }
    return $hidden
}

ad_proc -public export_entire_form {} {

    Exports everything in ns_getform to the ns_set.  This should 
    generally not be used. It's much better to explicitly name 
    the variables you want to export.  

    export_vars is now the prefered interface.

    @see export_vars
} {
    set hidden ""
    set the_form [ns_getform]
    if { ![empty_string_p $the_form] } {
	for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	    set varname [ns_set key $the_form $i]
	    set varvalue [ns_set value $the_form $i]
	    append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $varname]\" value=\"[ad_quotehtml $varvalue]\" >\n"
	}
    }
    return $hidden
}

ad_proc export_ns_set_vars {{format "url"} {exclusion_list ""} {setid ""}} {
    Returns all the params in an ns_set with the exception of those in
    exclusion_list. If no setid is provide, ns_getform is used. If
    format = url, a url parameter string will be returned. If format = form, a
    block of hidden form fragments will be returned.  

    export_vars is now the prefered interface.
    
    @param format either url or form 
    @param exclusion_list list of fields to exclude 
    @param setid if null then it is ns_getform

    @see export_vars
}  {

    if { [empty_string_p $setid] } {
	set setid [ns_getform]
    }

    set return_list [list]
    if { ![empty_string_p $setid] } {
        set set_size [ns_set size $setid]
        set set_counter_i 0
        while { $set_counter_i<$set_size } {
            set name [ns_set key $setid $set_counter_i]
            set value [ns_set value $setid $set_counter_i]
            if {[lsearch $exclusion_list $name] == -1 && ![empty_string_p $name]} {
                if {$format == "url"} {
                    lappend return_list "[ns_urlencode $name]=[ns_urlencode $value]"
                } else {
                    lappend return_list " name=\"[ad_quotehtml $name]\" value=\"[ad_quotehtml $value]\""
                }
            }
            incr set_counter_i
        }
    }
    if {$format == "url"} {
        return [join $return_list "&"]
    } else {
        return "<input type=\"hidden\" [join $return_list " />\n <input type=\"hidden\" "] >"
    }
}

ad_proc export_url_vars {
    -sign:boolean
    args 
} {
    export_vars is now the prefered interface.

    Returns a string of key=value pairs suitable for inclusion in a
    URL; you can pass it any number of variables as arguments.  If any are
    defined in the caller's environment, they are included.  See also
    export_entire_form_as_url_vars.

    <p>

    Instead of naming a variable you can also say name=value. Note that the value here is not 
    the name of a variable but the literal value you want to export e.g.,
    <code>export_url_vars [ns_urlencode foo]=[ns_urlencode $the_value]</code>.

    <p>

    For normal variables, you can say <code>export_url_vars foo:multiple</code>. In this case, 
    the value of foo will be treated as a Tcl list, and each value will be output separately e.g., 
    foo=item0&foo=item1&foo=item2...

    <p>

    You cannot combine the foo=bar syntax with the foo:multiple syntax. Why? Because there's no way we can distinguish 
    between the :multiple being part of the value of foo or being a flag intended for export_url_vars.

    @param sign If this flag is set, all the variables output will be
    signed using <a
    href="/api-doc/proc-view?proc=ad_sign"><code>ad_sign</code></a>. These variables should then be
    verified using the :verify flag to <a
    href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>,
    which in turn uses <a
    href="/api-doc/proc-view?proc=ad_verify_signature"><code>ad_verify_signature</code></a>. This
    ensures that the value hasn't been tampered with at the user's end.

    @see export_vars
} { 
    set params {} 
    foreach var_spec $args { 
	if { [string first "=" $var_spec] != -1 } {
	    # There shouldn't be more than one equal sign, since the value should already be url-encoded.
	    set var_spec_pieces [split $var_spec "="]
	    set var [lindex $var_spec_pieces 0]
	    set value [lindex $var_spec_pieces 1]
	    lappend params "$var=$value"
	    if { $sign_p } {
		lappend params "[ns_urlencode [ns_urldecode $var]:sig]=[ns_urlencode [ad_sign [ns_urldecode $value]]]"
	    }
	} else {
	    set var_spec_pieces [split $var_spec ":"]
	    set var [lindex $var_spec_pieces 0]
	    set type [lindex $var_spec_pieces 1]
	    
	    upvar 1 $var upvar_value
	    if { [info exists upvar_value] } {
		switch $type {
		    multiple {
			foreach item $upvar_value {
			    lappend params "[ns_urlencode $var]=[ns_urlencode $item]"
			}
		    }
		    default {
			lappend params "[ns_urlencode $var]=[ns_urlencode $upvar_value]" 
		    }
		}
		if { $sign_p } {
		    lappend params "[ns_urlencode "$var:sig"]=[ns_urlencode [ad_sign $upvar_value]]"
		}
	    }
	}
    }
    
  return [join $params "&"]
}

ad_proc -public export_entire_form_as_url_vars { 
    {vars_to_passthrough ""}
} {
    export_vars is now the prefered interface.

    Returns a URL parameter string of name-value pairs of all the form
    parameters passed to this page. If vars_to_passthrough is given, it
    should be a list of parameter names that will be the only ones passed
    through.
    
    @see export_vars
} {
    set params [list]
    set the_form [ns_getform]
    if { ![empty_string_p $the_form] } {
	for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	    set varname [ns_set key $the_form $i]
	    set varvalue [ns_set value $the_form $i]
	    if {
		$vars_to_passthrough == "" ||
		([lsearch -exact $vars_to_passthrough $varname] != -1)
	    } {
		lappend params "[ns_urlencode $varname]=[ns_urlencode $varvalue]" 
	    }
	}
	return [join $params "&"]
    }
}

ad_proc -public util_get_current_url {} {
    Returns a URL for re-issuing the current request, with query variables.
    If a form submission is present, that is converted into query vars as well.

    @return URL for the current page

    @author Lars Pind (lars@pinds.com)
    @creation-date February 11, 2003
} {
    set url [ad_conn url]

    set query [ns_getform]
    if { $query != "" } {
        append url "?[export_entire_form_as_url_vars]"
    }

    return $url
}

ad_proc -public with_catch {error_var body on_error} { 
    execute code in body with the catch errorMessage in error_var
    and if there is a non-zero return code from body
    execute the on_error block.
} { 
    upvar 1 $error_var $error_var 
    global errorInfo errorCode 
    if { [catch { uplevel $body } $error_var] } { 
        set code [catch {uplevel $on_error} string] 
        # Return out of the caller appropriately. 
        if { $code == 1 } { 
            return -code error -errorinfo $errorInfo -errorcode $errorCode $string 
        } elseif { $code == 2 } { 
            return -code return $string 
        } elseif { $code == 3 } { 
            return -code break
	} elseif { $code == 4 } {
	    return -code continue
        } elseif { $code > 4 } { 
            return -code $code $string 
        } 
    }         
} 



# putting commas into numbers (thank you, Michael Bryzek)

ad_proc -public util_commify_number { num } {
    Returns the number with commas inserted where appropriate. Number can be 
    positive or negative and can have a decimal point. 
    e.g. -1465.98 => -1,465.98
} {
    while { 1 } {
	# Regular Expression taken from Mastering Regular Expressions (Jeff Friedl)
	# matches optional leading negative sign plus any
	# other 3 digits, starting from end
	if { ![regsub -- {^(-?[0-9]+)([0-9][0-9][0-9])} $num {\1,\2} num] } {
	    break
	}
    }
    return $num
}

ad_proc -public util_search_list_of_lists {list_of_lists query_string {sublist_element_pos 0}} { 
    Returns position of sublist that contains QUERY_STRING at SUBLIST_ELEMENT_POS.
} {
    set sublist_index 0
    foreach sublist $list_of_lists {
	set comparison_element [lindex $sublist $sublist_element_pos]
	if { [string compare $query_string $comparison_element] == 0 } {
	    return $sublist_index
	}
	incr sublist_index
    }
    # didn't find it
    return -1
}

# --- network stuff 

ad_proc -public util_get_http_status {url {use_get_p 1} {timeout 30}} {
    Returns the HTTP status code, e.g., 200 for a normal response 
    or 500 for an error, of a URL.  By default this uses the GET method 
    instead of HEAD since not all servers will respond properly to a 
    HEAD request even when the URL is perfectly valid.  Note that 
    this means AOLserver may be sucking down a lot of bits that it 
    doesn't need.
} { 
    if $use_get_p {
	set http [ns_httpopen GET $url "" $timeout] 
    } else {
	set http [ns_httpopen HEAD $url "" $timeout] 
    }
    set rfd [lindex $http 0] 
    set wfd [lindex $http 1] 
    close $rfd
    close $wfd
    set headers [lindex $http 2] 
    set response [ns_set name $headers] 
    set status [lindex $response 1] 
    ns_set free $headers
    return $status
}

ad_proc -public util_link_responding_p {
    url 
    {list_of_bad_codes "404"}
} {
    Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay).

    @see util_get_http_status 
} {
    if { [catch { set status [util_get_http_status $url] } errmsg] } {
	# got an error; definitely not valid
	return 0
    } else {
	# we got the page but it might have been a 404 or something
	if { [lsearch $list_of_bad_codes $status] != -1 } {
	    return 0
	} else {
	    return 1
	}
    }
}

# system by Tracy Adams (teadams@arsdigita.com) to permit AOLserver to POST 
# to another Web server; sort of like ns_httpget

ad_proc -public util_httpopen {
    method 
    url 
    {rqset ""} 
    {timeout 30} 
    {http_referer ""}
} { 
    Like ns_httpopen but works for POST as well; called by util_httppost
} { 
    
    if { ![string match http://* $url] } {
        return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
    }
    set url [split $url /]
    set hp [split [lindex $url 2] :]
    set host [lindex $hp 0]
    set port [lindex $hp 1]
    if { [string match $port ""] } {set port 80}
    set uri /[join [lrange $url 3 end] /]
    set fds [ns_sockopen -nonblock $host $port]
    set rfd [lindex $fds 0]
    set wfd [lindex $fds 1]
    if { [catch {
        _ns_http_puts $timeout $wfd "$method $uri HTTP/1.0\r"
        _ns_http_puts $timeout $wfd "Host: $host\r"
        if {$rqset != ""} {
            for {set i 0} {$i < [ns_set size $rqset]} {incr i} {
                _ns_http_puts $timeout $wfd \
                    "[ns_set key $rqset $i]: [ns_set value $rqset $i]\r"
            }
        } else {
            _ns_http_puts $timeout $wfd \
                "Accept: */*\r"

            _ns_http_puts $timeout $wfd "User-Agent: Mozilla/1.01 \[en\] (Win95; I)\r"    
            _ns_http_puts $timeout $wfd "Referer: $http_referer \r"    
	}

    } errMsg] } {
        global errorInfo
        #close $wfd
        #close $rfd
        if { [info exists rpset] } {ns_set free $rpset}
        return -1
    }
    return [list $rfd $wfd ""]
    
}

# httppost; give it a URL and a string with formvars, and it 
# returns the page as a Tcl string
# formvars are the posted variables in the following form: 
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

ad_proc -public util_httppost {url formvars {timeout 30} {depth 0} {http_referer ""}} {
    Returns the result of POSTing to another Web server or -1 if there is an error or timeout.  
    formvars should be in the form \"arg1=value1&arg2=value2\".  
    <p> 
    post is encoded as application/x-www-form-urlencoded.  See util_http_file_upload
    for file uploads via post (encoded multipart/form-data).
    <p> 
    @see util_http_file_upload
} {
    if { [catch {
	if {[incr depth] > 10} {
		return -code error "util_httppost:  Recursive redirection:  $url"
	}
	set http [util_httpopen POST $url "" $timeout $http_referer]
	set rfd [lindex $http 0]
	set wfd [lindex $http 1]

	#headers necesary for a post and the form variables

	_ns_http_puts $timeout $wfd "Content-type: application/x-www-form-urlencoded \r"
	_ns_http_puts $timeout $wfd "Content-length: [string length $formvars]\r"
	_ns_http_puts $timeout $wfd \r
	_ns_http_puts $timeout $wfd "$formvars\r"
	flush $wfd
	close $wfd

	set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
		while 1 {
			set line [_ns_http_gets $timeout $rfd]
			if { ![string length $line] } break
			ns_parseheader $rpset $line
		}

	set headers $rpset
	set response [ns_set name $headers]
	set status [lindex $response 1]
	if {$status == 302} {
		set location [ns_set iget $headers location]
		if {$location != ""} {
		    ns_set free $headers
		    close $rfd
		    return [util_httpget $location {}  $timeout $depth]
		}
	}
	set length [ns_set iget $headers content-length]
	if { [string match "" $length] } {set length -1}
	set err [catch {
		while 1 {
			set buf [_ns_http_read $timeout $rfd $length]
			append page $buf
			if { [string match "" $buf] } break
			if {$length > 0} {
				incr length -[string length $buf]
				if {$length <= 0} break
			}
		}
	} errMsg]
	ns_set free $headers
	close $rfd
	if $err {
		global errorInfo
		return -code error -errorinfo $errorInfo $errMsg
	}
    } errmgs ] } {return -1}
	return $page
}

ad_proc -public util_report_successful_library_load {{extra_message ""}} {
    Should be called at end of private Tcl library files so that it is 
    easy to see in the error log whether or not private Tcl library 
    files contain errors.
} {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Done... $scrubbed_path"
    } else {
	set message "Done... $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

ad_proc -public exists_and_not_null { varname } {
    Returns 1 if the variable name exists in the caller's environment and 
    is not the empty string.

    Note you should enter the variable name, and not the variable value 
    (varname not $varname which will pass variable varnames value into this function).
} {
    upvar 1 $varname var 
    return [expr { [info exists var] && ![empty_string_p $var] }] 
} 

ad_proc -public exists_and_equal { varname value } {
    Returns 1 if the variable name exists in the caller's envirnoment
    and is equal to the given value.

    @see exists_and_not_null

    @author Peter Marklund    
} {
    upvar 1 $varname var
    
    return [expr { [info exists var] && [string equal $var $value] } ]
}

ad_proc -public ad_httpget {
    -url 
    {-headers ""} 
    {-timeout 30}
    {-depth 0}
} {
    Just like ns_httpget, but first headers is an ns_set of
    headers to send during the fetch.

    ad_httpget also makes use of Conditional GETs (if called with a 
    Last-Modified header).

    Returns the data in array get form with array elements page status modified.
} {
    ns_log debug "Getting {$url} {$headers} {$timeout} {$depth}"

    if {[incr depth] > 10} {
        return -code error "ad_httpget:  Recursive redirection:  $url"
    }

    set http [ns_httpopen GET $url $headers $timeout]
    set rfd [lindex $http 0]
    close [lindex $http 1]
    set headers [lindex $http 2]
    set response [ns_set name $headers]
    set status [lindex $response 1]
    set last_modified [ns_set iget $headers last-modified]

    if {$status == 302 || $status == 301} {
	set location [ns_set iget $headers location]
	if {![empty_string_p $location]} { 
            ns_set free $headers
            close $rfd
	    return [ad_httpget -url $location -timeout $timeout -depth $depth]
	}
    } elseif { $status == 304 } {
        # The requested variant has not been modified since the time specified
        # A conditional get didn't return anything.  return an empty page and 
        set page {}

        ns_set free $headers
        close $rfd
    } else { 
        set length [ns_set iget $headers content-length]
        if { [string match "" $length] } {set length -1}
    
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { [string match "" $buf] } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd

        if $err {
            global errorInfo
            return -code error -errorinfo $errorInfo $errMsg
        }
    }

    # order matters here since we depend on page content 
    # being element 1 in this list in util_httpget 
    return [list page $page \
                status $status \
                modified $last_modified]
}

ad_proc -public util_httpget {
    url {headers ""} {timeout 30} {depth 0}
} {
    util_httpget simply calls ad_httpget which also returns 
    status and last_modfied
    
    @see ad_httpget
} {
    return [lindex [ad_httpget -url $url -headers $headers -timeout $timeout -depth $depth] 1]
}

# some procs to make it easier to deal with CSV files (reading and writing)
# added by philg@mit.edu on October 30, 1999

proc_doc util_escape_quotes_for_csv {string} "Returns its argument with double quote replaced by backslash double quote" {
    regsub -all \" $string {\"}  result

    return $result
}


ad_proc -deprecated validate_integer {field_name string} {
    Throws an error if the string isn't a decimal integer; otherwise
    strips any leading zeros (so this won't work for octals) and returns
    the result.  
    <p>
    validate via ad_page_contract

    @see ad_page_contract
} {
    if { ![regexp {^[0-9]+$} $string] } {
	error "$field_name is not an integer"
    }
    # trim leading zeros, so as not to confuse Tcl
    set string [string trimleft $string "0"]
    if { [empty_string_p $string] } {
	# but not all of the zeros
	return "0"
    }
    return $string
}

ad_proc -deprecated validate_zip_code {field_name zip_string country_code} {
    Given a string, signals an error if it's not a legal zip code
    <p>
    validate via ad_page_contract

    @see ad_page_contract

} {
    if { $country_code == "" || [string toupper $country_code] == "US" } {
	if { [regexp {^[0-9][0-9][0-9][0-9][0-9](-[0-9][0-9][0-9][0-9])?$} $zip_string] } {
	    set zip_5 [string range $zip_string 0 4]
	    if {
		![db_0or1row zip_code_exists {
		    select 1
		      from dual
		     where exists (select 1
				     from zip_codes
				    where zip_code like :zip_5)
		}]
	    } {
		error "The entry for $field_name, \"$zip_string\" is not a recognized zip code"
	    }
	} else {
	    error "The entry for $field_name, \"$zip_string\" does not look like a zip code"
	}
    } else {
	if { $zip_string != "" } {
	    error "Zip code is not needed outside the US"
	}
    }
    return $zip_string
}

ad_proc -deprecated validate_ad_dateentrywidget {field_name column form {allow_null 0}} {
    <p>
    validate via ad_page_contract

    @see ad_page_contract
} {
    set col $column
    set day [ns_set get $form "$col.day"]
    ns_set update $form "$col.day" [string trimleft $day "0"]
    set month [ns_set get $form "$col.month"]
    set year [ns_set get $form "$col.year"]

    # check that either all elements are blank
    # date value is formated correctly for ns_dbformvalue
    if { [empty_string_p "$day$month$year"] } {
	if { $allow_null == 0 } {
	    error "$field_name must be supplied"
	} else {
	    return ""
	}
    } elseif { ![empty_string_p $year] && [string length $year] != 4 } {
	error "The year must contain 4 digits."
    } elseif { [catch  { ns_dbformvalue $form $column date date } errmsg ] } {
	error "The entry for $field_name had a problem:  $errmsg."
    }

    return $date
}

ad_proc -private util_WriteWithExtraOutputHeaders {headers_so_far {first_part_of_page ""}} {
    Takes in a string of headers to write to an HTTP connection,
    terminated by a newline.  Checks \[ad_conn outputheaders\] and adds
    those headers if appropriate.  Adds two newlines at the end and writes
    out to the connection.  May optionally be used to write the first part
    of the page as well (saves a packet).
} {
    ns_set put [ad_conn outputheaders] Server "[ns_info name]/[ns_info version]"
    set set_headers_i 0
    set set_headers_limit [ns_set size [ad_conn outputheaders]]
    while {$set_headers_i < $set_headers_limit} {
	append headers_so_far "[ns_set key [ad_conn outputheaders] $set_headers_i]: [ns_set value [ad_conn outputheaders] $set_headers_i]\r\n"
	incr set_headers_i
    }
    append entire_string_to_write $headers_so_far "\r\n" $first_part_of_page
    ns_write $entire_string_to_write
}

ad_proc -public ReturnHeaders {{content_type text/html}} {
   We use this when we want to send out just the headers
   and then do incremental writes with ns_write.  This way the user
   doesn't have to wait for streamed output (useful when doing
   bulk uploads, installs, etc.).

   It returns status 200 and all headers including
   any added to outputheaders.
} {
   set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
    util_WriteWithExtraOutputHeaders $all_the_headers
    if {[string match text/* $content_type]} {
      if {![string match *charset=* $content_type]} {
	append content_type \
	    "; charset=[ns_config ns/parameters OutputCharset iso-8859-1]"
      }
      ns_startcontent -type $content_type
    } else {
      ns_startcontent
    }
}

ad_proc -public ad_return_top_of_page {first_part_of_page {content_type text/html}} { 
    Returns HTTP headers plus the top of the user-visible page.  
} {
    ReturnHeaders $content_type
    if { $first_part_of_page ne "" } {
	ns_write $first_part_of_page
    }
}

ad_proc -public apply {func arglist} {
    Evaluates the first argument with ARGLIST as its arguments, in the
    environment of its caller. Analogous to the Lisp function of the same name.
} {
    set func_and_args [concat $func $arglist]
    return [uplevel $func_and_args]
}

ad_proc -public safe_eval args {
    Version of eval that checks its arguments for brackets 
    that may be used to execute unsafe code.
} {
    foreach arg $args {
	if { [regexp {[\[;]} $arg] } {
	    return -code error "Unsafe argument to safe_eval: $arg"
	}
    }
    return [apply uplevel $args]
}

ad_proc -public lmap {list proc_name} {
    Applies proc_name to each item of the list, appending the result of 
    each call to a new list that is the return value.
} {
    set lmap [list]
    foreach item $list {
	lappend lmap [safe_eval $proc_name $item]
    }
    return $lmap
}

ad_proc -public ad_decode { args } {
    this procedure is analogus to sql decode procedure. first parameter is
    the value we want to decode. this parameter is followed by a list of
    pairs where first element in the pair is convert from value and second
    element is convert to value. last value is default value, which will
    be returned in the case convert from values matches the given value to
    be decoded
} {
    set num_args [llength $args]
    set input_value [lindex $args 0]

    set counter 1

    while { $counter < [expr $num_args - 2] } {
	lappend from_list [lindex $args $counter]
	incr counter
	lappend to_list [lindex $args $counter]
	incr counter
    }

    set default_value [lindex $args $counter]

    if { $counter < 2 } {
	return $default_value
    }

    set index [lsearch -exact $from_list $input_value]
    
    if { $index < 0 } {
	return $default_value
    } else {
	return [lindex $to_list $index]
    }
}

ad_proc -public ad_urlencode { string } {
    same as ns_urlencode except that dash and underscore are left unencoded.
} {
    set encoded_string [ns_urlencode $string]
    regsub -all {%2d} $encoded_string {-} encoded_string
    regsub -all {%5f} $encoded_string {_} ad_encoded_string
    return $ad_encoded_string
}

ad_proc -public ad_get_cookie {
    { -include_set_cookies t }
    name { default "" }
} { 
    Returns the value of a cookie, or $default if none exists.
} {
    if { $include_set_cookies == "t" } {
	set headers [ad_conn outputheaders]
	for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
	    if { ![string compare [string tolower [ns_set key $headers $i]] "set-cookie"] && \
		    [regexp "^$name=(\[^;\]*)" [ns_set value $headers $i] "" "value"] } {
		return $value
	    }
	}
    }

    set headers [ad_conn headers]
    set cookie [ns_set iget $headers Cookie]
    if { [regexp " $name=(\[^;\]*)" " $cookie" match value] } {

        # If the cookie was set to a blank value we actually stored two quotes.  We need
        # to undo the kludge on the way out.

        if { $value == "\"\"" } {
              set value ""
        }
	return $value
    }

    return $default
}

ad_proc -public ad_set_cookie {
    {
	-replace f
	-secure f
        -expire f
	-max_age ""
	-domain ""
	-path "/"
    }
    name {value ""}
} { 

    Sets a cookie.

    @param max_age specifies the maximum age of the cookies in
    seconds (consistent with RFC 2109). max_age inf specifies cookies
    that never expire. The default behavior is to issue session
    cookies.
    
    @param expire specifies whether we should expire (clear) the cookie. 
    Setting Max-Age to zero ought to do this, but it doesn't in some browsers
    (tested on IE 6).

    @param path specifies a subset of URLs to which this cookie
    applies. It must be a prefix of the URL being accessed.

    @param domain specifies the domain(s) to which this cookie
    applies. See RFC2109 for the semantics of this cookie attribute.

    @param secure specifies to the user agent that the cookie should
    only be transmitted back to the server of secure transport.
    
    @param replace forces the current output headers to be checked for
    the same cookie. If the same cookie is set for a second time
    without the replace option being specified, the client will
    receive both copies of the cookie.

    @param value is autmatically URL encoded.

    @see ad_get_cookie
} {
    set headers [ad_conn outputheaders]
    if { $replace != "f" } {
	# Try to find an already-set cookie named $name.
	for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
	    if { ![string compare [string tolower [ns_set key $headers $i]] "set-cookie"] && \
		    [regexp "^$name=" [ns_set value $headers $i]] } {
		ns_set delete $headers $i
	    }
	}
    }

    # need to set some value, so we put "" as the cookie value
    if { $value == "" } {
	set cookie "$name=\"\""
    } else {
	set cookie "$name=$value"
    }

    if { $path != "" } {
	append cookie "; Path=$path"
    }

    if { $max_age == "inf" } {
        if { ![string equal $expire "t"] } {
            # netscape seemed unhappy with huge max-age, so we use
            # expires which seems to work on both netscape and IE
            append cookie "; Expires=Mon, 01-Jan-2035 01:00:00 GMT"
        }
    } elseif { $max_age != "" } {
        append cookie "; Max-Age=$max_age; Expires=[util::cookietime [expr [ns_time] + $max_age]]"
    }

    if { [string equal $expire "t"] } {
        append cookie "; Expires=Tue, 01-Jan-1980 01:00:00 GMT"
    }

    if { $domain != "" } {
	append cookie "; Domain=$domain"
    }

    if { $secure != "f" } {
	append cookie "; Secure"
    }

    ns_set put $headers "Set-Cookie" $cookie
}

ad_proc -private ad_run_scheduled_proc { proc_info } { 
    Runs a scheduled procedure and updates monitoring information in the shared variables. 
} {
    if {[ns_info name] eq "NaviServer"} {
      set proc_info [lindex $proc_info 0]
    }

    # Grab information about the scheduled procedure.
    set thread [lindex $proc_info 0]
    set once [lindex $proc_info 1]
    set interval [lindex $proc_info 2]
    set proc [lindex $proc_info 3]
    set args [lindex $proc_info 4]
    set time [lindex $proc_info 5]
    set count 0
    set debug [lindex $proc_info 7]

    ns_mutex lock [nsv_get ad_procs mutex]
    set procs [nsv_get ad_procs .]

    # Find the entry in the shared variable. Splice it out.
    for { set i 0 } { $i < [llength $procs] } { incr i } {
	set other_proc_info [lindex $procs $i]
	for { set j 0 } { $j < 5 } { incr j } {
	    if { [lindex $proc_info $j] != [lindex $other_proc_info $j] } {
		break
	    }
	}
	if { $j == 5 } {
	    set count [lindex $other_proc_info 6]
	    set procs [lreplace $procs $i $i]
	    break
	}
    }

    if { $once == "f" } {
	# The proc will run again - readd it to the shared variable (updating ns_time and
	# incrementing the count).
	lappend procs [list $thread $once $interval $proc $args [ns_time] [expr { $count + 1 }] $debug]
    }
    nsv_set ad_procs . $procs

    ns_mutex unlock [nsv_get ad_procs mutex]

    ns_log debug "Running scheduled proc $proc..."

    # Actually run the procedure.
    eval [concat [list $proc] $args]
    ns_log debug "Done running scheduled proc $proc."
}

# Initialize NSVs for ad_schedule_proc.
if { [apm_first_time_loading_p] } {
    nsv_set ad_procs mutex [ns_mutex create]
    nsv_set ad_procs . ""
}

ad_proc -public ad_schedule_proc {
    {
	-thread f
	-once f
	-debug f
	-all_servers f
        -schedule_proc ""
    }
    interval
    proc
    args
} { 
    Replacement for ns_schedule_proc and friends, allowing us to track what's going
    on. Can be monitored via /admin/monitoring/schedule-procs.tcl. The
    procedure defaults to run on only the canonical server unless the
    all_servers flag is set to true.

    @param thread t/f If true run scheduled proc in its own thread
    @param once t/f. If true only run the scheduled proc once
    @param debug t/f If true log debugging information
    @param all_servers If true run on all servers in a cluster
    @param schedule_proc ns_schedule_daily, ns_schedule_weekly or blank
    @param interval If schedule_proc is empty, the interval to run the proc
           in seconds, otherwise a list of interval arguments to pass to
           ns_schedule_daily or ns_schedule_weekly
    @param proc The proc to schedule
    @param args And the args to pass it

} {
    # we don't schedule a proc to run if we have enabled server clustering,
    # we're not the canonical server, and the procedure was not requested to run on all servers.
    if { [server_cluster_enabled_p] && ![ad_canonical_server_p] && $all_servers == "f" } {
        return
    } 

    # Protect the list of scheduled procs with a mutex.
    ns_mutex lock [nsv_get ad_procs mutex]
    set proc_info [list $thread $once $interval $proc $args [ns_time] 0 $debug]
    ns_log debug "Scheduling proc $proc"
    
    # Add to the list of scheduled procedures, for monitoring.
    set procs [nsv_get ad_procs .]
    lappend procs $proc_info
    nsv_set ad_procs . $procs
    ns_mutex unlock [nsv_get ad_procs mutex]

    set my_args [list]
    if { $thread == "t" } {
	lappend my_args "-thread"
    }
    if { $once == "t" } {
	lappend my_args "-once"
    }

    # Schedule the wrapper procedure (ad_run_scheduled_proc).

    if { [empty_string_p $schedule_proc] } {
        eval [concat [list ns_schedule_proc] $my_args [list $interval ad_run_scheduled_proc [list $proc_info]]]
    } else {
        eval [concat [list $schedule_proc] $my_args $interval [list ad_run_scheduled_proc [list $proc_info]]]
    }
}

ad_proc util_ReturnMetaRefresh { url { seconds_delay 0 } } {
    Ugly workaround to deal with IE5.0 bug handling
    multipart/form-data using                                                                                  
    Meta Refresh page instead of a redirect.                                                                                                                   
    
} {
    ReturnHeaders
    ns_write "
    <head>
    <meta http-equiv=\"refresh\" content=\"$seconds_delay;URL=$url\">
    </head>
    <body>
    If your browser does not automatically redirect you, please go <a href=\"$url\">here</a>.
    </body>"
}

# Brad Duell (bduell@ncacasi.org) 07/10/2003
# User session variables, then redirect
ad_proc -public ad_cache_returnredirect { url { persistent "f" } { excluded_vars "" } } {
    An addition to ad_returnredirect.  It caches all variables in the redirect except those in excluded_vars
    and then calls ad_returnredirect with the resultant string.

    @author Brad Duell (bduell@ncacasi.org)

} {
    util_memoize_flush_regexp [list [ad_conn session_id] [ad_conn package_id]]

    set url_list [split $url "?"]
    set url [lindex $url_list 0]
    set vars [lindex $url_list 1]

    set excluded_vars_list ""
    set excluded_vars_url ""
    for { set i 0 } { $i < [llength $excluded_vars] } { incr i } {
	set item [lindex [lindex $excluded_vars $i] 0]
	set value [lindex [lindex $excluded_vars $i] 1]
	if { [empty_string_p $value] } {
	    # Obtain value from adp level
	    upvar #[template::adp_level] __item item_reference
	    set item_reference $item
	    upvar #[template::adp_level] __value value_reference
	    uplevel #[template::adp_level] {set __value [expr $$__item]}
	    set value $value_reference
	}
	lappend excluded_vars_list $item
	if { ![empty_string_p $value] } {
	    # Value provided
	    if { ![empty_string_p $excluded_vars_url] } {
		append excluded_vars_url "&"
	    }
	    append excluded_vars_url [export_vars -url [list [list "$item" "$value"]]]
	}
    }

    set saved_list ""
    if { ![empty_string_p $vars] } {
	foreach item_value [split $vars "&"] {
	    set item_value_pair [split $item_value "="]
	    set item [lindex $item_value_pair 0]
	    set value [ns_urldecode [lindex $item_value_pair 1]]
	    if { [lsearch -exact $excluded_vars_list $item] == -1 } {
		# No need to save the value if it's being passed ...
		if { [lsearch -exact $saved_list $item] != -1 } {
		    # Allows for multiple values ...
		    append value " [ad_get_client_property [ad_conn package_id] $item]"
		} else {
		    # We'll keep track of who we've saved for this package ...
		    lappend saved_list $item
		}
		ad_set_client_property -persistent $persistent [ad_conn package_id] $item $value
	    }
	}
    }

    ad_returnredirect "$url?$excluded_vars_url"
}

# branimir 2000/04/25 ad_returnredirect and helper procs :
#    util_complete_url_p util_absolute_path_p util_current_location
#    util_current_directory   
# See: http://rhea.redhat.com/bboard-archive/acs_design/0003eV.html

ad_proc -public ad_returnredirect {
    {-message {}}
    {-html:boolean}
    target_url
} {
    Write the HTTP response required to get the browser to redirect to a different page, 
    to the current connection. This does not cause execution of the current page, including serving 
    an ADP file, to stop. If you want to stop execution of the page, you should call ad_script_abort
    immediately following this call.

    <p>

    This proc is a replacement for ns_returnredirect, but improved in two important respects:
    <ul>
      <li>
        When the supplied target_url isn't complete, (e.g. /foo/bar.tcl or foo.tcl)
        the prepended location part is constructed by looking at the HTTP 1.1 Host header.
      </li>
      <li>
        If an URL relative to the current directory is supplied (e.g. foo.tcl)
        it prepends location and directory.
      </li>
    </ul>

    @param message A message to display to the user. See util_user_message.
    @param html Set this flag if your message contains HTML. If specified, you're responsible for proper quoting 
    of everything in your message. Otherwise, we quote it for you.
    
    @see util_user_message
    @see ad_script_abort
} {
    if { [string is false $html_p] } {
      	util_user_message -message $message
    } else {
      	util_user_message -message $message -html
    }

    if { [util_complete_url_p $target_url] } {
        # http://myserver.com/foo/bar.tcl style - just pass to ns_returnredirect
        set url $target_url
    } elseif { [util_absolute_path_p $target_url] } {
        # /foo/bar.tcl style - prepend the current location:
        set url [util_current_location]$target_url
    } else {
        # URL is relative to current directory.
        if {[string equal $target_url "."]} {
            set url [util_current_location][util_current_directory]
        } else {
            set url [util_current_location][util_current_directory]$target_url
        }
    }
    #Ugly workaround to deal with IE5.0 bug handling multipart/form-data using 
    #Meta Refresh page instead of a redirect. 
    # jbank@arsdigita.com 6/7/2000
    set use_metarefresh_p 0
    set type [ns_set iget [ad_conn headers] content-type]
    if { [string match *multipart/form-data* [string tolower $type]] } {
        set user_agent [ns_set get [ad_conn headers] User-Agent]
        set use_metarefresh_p [regexp -nocase "msie 5.0" $user_agent match]
    }
    if { $use_metarefresh_p != 0 } {
        util_ReturnMetaRefresh $url 
    } else {
        ns_returnredirect $url
    }    
}

ad_proc -public util_user_message { 
    {-replace:boolean}
    {-html:boolean}
    {-message {}}
} {
    Sets a message to be displayed on the next page request.

    @param message The message to display.

    @param replace Set this if you want to replace existing messages. Default behavior is to append to a list of messages.

    @param html Set this flag if your message contains HTML. If specified, you're responsible for proper quoting 
    of everything in your message. Otherwise, we quote it for you.
    
    @see util_get_user_messages
} {
    if { ![empty_string_p $message] } {
        if { [string is false $html_p] } {
            set message [ad_quotehtml $message]
        }

        if { !$replace_p } {
            set new_messages [ad_get_client_property -default {} -cache_only t "acs-kernel" "general_messages"]
            lappend new_messages $message
        } else {
            set new_messages [list $message]
        }
        ad_set_client_property "acs-kernel" "general_messages" $new_messages
    } elseif { $replace_p } {
        ad_set_client_property "acs-kernel" "general_messages" {}
    }
}

ad_proc -public util_get_user_messages { 
    {-keep:boolean}
    {-multirow:required}
} {
    Gets and clears the message to be displayed on the next page load.

    @param multirow Name of a multirow in the current template namespace where you want the user messages set. 
    The multirow will have one column, which is 'message'.

    @param keep If set, then we will not clear the list of messages after getting them. Normal behavior is to 
    clear them, so we only display the same messages once.

    @see util_user_message
} {
    set messages [ad_get_client_property -default {} -cache_only t "acs-kernel" "general_messages"]
    if { !$keep_p && ![empty_string_p $messages] } {
        ad_set_client_property "acs-kernel" "general_messages" {}
    }
    template::multirow create $multirow message
    foreach message $messages {
        template::multirow append $multirow $message
    }
}

ad_proc -public util_complete_url_p {{} string} {
  Determine whether string is a complete URL, i.e.
  wheteher it begins with protocol: where protocol
  consists of letters only.
} {
  if {[regexp -nocase {^[a-z]+:} $string]} {
     return 1
  } else {
     return 0
  }
}

ad_proc -public util_absolute_path_p {{} path} {
   Check whether the path begins with a slash
} {
   set firstchar [string index $path 0]
   if {[string compare $firstchar /]} {
        return 0
   } else {
        return 1
   }
}

ad_proc -public util_driver_info {
  {-array:required} 
  {-driver ""}
} {
  Returns the protocol and port for the specified driver.

  @param driver the driver to query (defaults to [ad_conn driver])
  @param array the array to populate with proto and port
} {
    upvar $array result

    if {[string equal $driver ""]} {
        set driver [ad_conn driver]
    }

    switch $driver {
        nssock {
            set result(proto) http
            set result(port) [ns_config -int "ns/server/[ns_info server]/module/nssock" Port]
        }
        nsunix {
            set result(proto) http
            set result(port) {}
        }
        nsssl - nsssle {
            set result(port) [ns_config -int "ns/server/[ns_info server]/module/[ad_conn driver]" Port]
            set result(proto) https
        }
        nsopenssl {
            set result(port) [ns_config -int "ns/server/[ns_info server]/module/[ad_conn driver]" ServerPort]
            set result(proto) https
        }
        default {
            ns_log Error "Unknown driver: [ad_conn driver]. Only know nssock, nsunix, nsssl, nsssle, nsopenssl"
            set result(port) [ns_config -int "ns/server/[ns_info server]/module/nssock" Port]
            set result(proto) http
        }
    }
}

ad_proc -public util_current_location {{}} {
   Like ad_conn location - Returns the location string of the current
   request in the form protocol://hostname[:port] but it looks at the
   Host header, that is, takes into account the host name the client
   used although it may be different from the host name from the server
   configuration file.  If the Host header is missing or empty 
   util_current_location falls back to ad_conn location.

   cro@ncacasi.org 2002-06-07
   Note: IE fouls up the Host header if a server is on a non-standard port; it
    does not change the port number when redirecting to https.  So
    we would get redirects from http://some-host:8000 to
    https://some-host:8000

    @author Lars Pind (lars@collaboraid.biz)
    @author Peter Marklund
} {
    set default_port(http) 80
    set default_port(https) 443
    
    util_driver_info -array driver
    set proto $driver(proto)
    set port $driver(port)

    # This is the host from the browser's HTTP request
    set Host [ns_set iget [ad_conn headers] Host]
    set Hostv [split $Host ":"]
    set Host_hostname [lindex $Hostv 0]
    set Host_port [lindex $Hostv 1]
    
    # Server config location
    if { ![regexp {^([a-z]+://)?([^:]+)(:[0-9]*)?$} [ad_conn location] match location_proto location_hostname location_port] } {
        ns_log Error "util_current_location couldn't regexp '[ad_conn location]'"
    }

    if { [empty_string_p $Host] } {
        # No Host header, return protocol from driver, hostname from [ad_conn location], and port from driver
        set hostname $location_hostname
    } else {
        set hostname $Host_hostname
        if { ![empty_string_p $Host_port] } {
            set port $Host_port
        }    
    }

    if { ![empty_string_p $port] && ![string equal $port $default_port($proto)] } {
        return "$proto://$hostname:$port"
    } else {
        return "$proto://$hostname"
    }
}

ad_proc -public util_current_directory {{}} {
    Returns the directory of the current URL.
    <p>
    We can't just use [file dirname [ad_conn url]] because
    we want /foo/bar/ to return /foo/bar/ and not /foo  .
    <p>
    Also, we want to return directory WITH the trailing slash
    so that programs that use this proc don't have to treat
    the root directory as a special case.
} {
   set path [ad_conn url]

   set lastchar [string range $path [expr [string length $path]-1] end]
   if {![string compare $lastchar /]} {
        return $path
   } else { 
        set file_dirname [file dirname $path]
        # Treat the case of the root directory special
        if {![string compare $file_dirname /]} {
            return /
        } else {
            return  $file_dirname/
        }
   }
}


ad_proc -public ad_call_proc_if_exists { proc args } {
    Calls a procedure with particular arguments, only if the procedure is defined.
} {
    if { [llength [info procs $proc]] == 1 } {
	eval $proc $args
    }
}

ad_proc -public ad_get_tcl_call_stack { {level -2} } {
    Returns a stack trace from where the caller was called.
    See also ad_print_stack_trace which generates a more readable 
    stack trace at the expense of truncating args.

    @param level The level to start from, relative to this
    proc. Defaults to -2, meaning the proc that called this 
    proc's caller.


    @author Lars Pind (lars@pinds.com)

    @see ad_print_stack_trace
 } {
    set stack ""
    for { set x [expr [info level] + $level] } { $x > 0 } { incr x -1 } {
	append stack "    called from [info level $x]\n"
    }
    return $stack
}

ad_proc -public ad_ns_set_to_tcl_vars { 
    {-duplicates overwrite}
    {-level 1}
    set_id
} {
    Takes an ns_set and sets variables in the caller's environment
    correspondingly, i.e. if key is foo and value is bar, the Tcl var
    foo is set to bar.

    @param duplicates This optional switch argument defines what happens if the
    Tcl var already exists, or if there are duplicate entries for the same key.
    <code>overwrites</code> just overwrites the var, which amounts to letting the 
    ns_set win over pre-defined vars, and later entries in the ns_set win over 
    earlier ones. <code>ignore</code> means the variable isn't overwritten.
    <code>fail</code> will make this proc fail with an error. This makes it 
    easier to track subtle errors that could occur because of unpredicted name 
    clashes.

    @param level The level to upvar to.

    @author Lars Pind (lars@pinds.com)
} {
    if { [lsearch -exact {ignore fail overwrite} $duplicates] == -1 } {
	return -code error "The optional switch duplicates must be either overwrite, ignore or fail"
    }
    
    set size [ns_set size $set_id]
    for { set i 0 } { $i < $size } { incr i } {
	set varname [ns_set key $set_id $i]
	upvar $level $varname var
	if { [info exists var] } {
	    switch $duplicates {
		fail {
		    return -code error "ad_ns_set_to_tcl_vars tried to set the var $varname which is already set"
		}
		ignore {
		    # it's already set ... don't overwrite it
		    continue
		}
	    }
	}
	set var [ns_set value $set_id $i]
    }
}

ad_proc -public ad_tcl_vars_to_ns_set { 
    -set_id
    -put:boolean
    args 
} {
    Takes a list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    @param set_id If this switch is specified, it'll use this set instead of 
    creating a new one.
    
    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead 
    of <code>ns_set update</code> (update is default)

    @param args A number of variable names that will be transported into the ns_set.

    @author Lars Pind (lars@pinds.com)

} {
    if { ![info exists set_id] } {
	set set_id [ns_set create]
    }

    if { $put_p } {
	set command put
    } else {
	set command update
    }

    foreach varname $args {
	upvar $varname var
	ns_set $command $set_id $varname $var
    }
    return $set_id
}

ad_proc -public ad_tcl_vars_list_to_ns_set { 
    -set_id
    -put:boolean
    vars_list
} {
    Takes a TCL list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    @param set_id If this switch is specified, it'll use this set instead of 
    creating a new one.
    
    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead 
    of <code>ns_set update</code> (update is default)

    @param args A TCL list of variable names that will be transported into the ns_set.

    @author Lars Pind (lars@pinds.com)

} {
    if { ![info exists set_id] } {
	set set_id [ns_set create]
    }

    if { $put_p } {
	set command put
    } else {
	set command update
    }

    foreach varname $vars_list {
	upvar $varname var
	ns_set $command $set_id $varname $var
    }
    return $set_id
}

ad_proc -public util_sets_equal_p { list1 list2 } {
    Tests whether each unique string in list1 occurs as many
    times in list1 as in list2 and vice versa (regarless of order).

    @return 1 if the lists have identical sets and 0 otherwise

    @author Peter Marklund
} {
    if { [llength $list1] != [llength $list2] } {
        return 0
    }

    set sorted_list1 [lsort $list1]
    set sorted_list2 [lsort $list2]

    for { set index1 0 } { $index1 < [llength $sorted_list1] } { incr index1 } {
        if { ![string equal [lindex $sorted_list1 $index1] [lindex $sorted_list2 $index1]] } {
            return 0
        }
    }

    return 1    
}

ad_proc -public util_subset_p { 
    list1
    list2
} {
    Tests whether list1 is a subset of list2. 

    @return 1 if list1 is a subset of list2.

    @author Peter Marklund
} {
    if { [llength $list1] == 0 } {
        # The empty list is always a subset of any list
        return 1
    }

    set sorted_list1 [lsort $list1]
    set sorted_list2 [lsort $list2]
        
    set len1 [llength $sorted_list1]
    set len2 [llength $sorted_list2]

    # Loop over list1 and list2 in sort order, comparing the elements
    
    set index1 0
    set index2 0
    while { $index1 < $len1 && $index2 < $len2 } { 
        set elm1 [lindex $sorted_list1 $index1]
        set elm2 [lindex $sorted_list2 $index2]
        set compare [string compare $elm1 $elm2]
        
        switch -exact -- $compare {
            -1 { 
                # elm1 < elm2
                # The first element in list1 is smaller than any element in list2, 
                # therefore this element cannot exist in list2, and therefore list1 is not a subset of list2
                return 0
            }
            0 {
                # A match, great, next element
                incr index1
                incr index2
                continue
            }
            1 {
                # elm1 > elm2
                # Move to the next element in list2, knowing that this will be larger, and therefore 
                # potentially equal to the element in list1
                incr index2
            }
        }
    }

    if { $index1 == $len1 } {
        # We've reached the end of list1, finding all elements along the way, we're done
        return 1
    } else {
        # One or more elements in list1 not found in list2
        return 0
    }
}

ad_proc -public util_get_subset_missing { 
    list1
    list2
} {
    Returns the elements in list1 that are not in list2. Ignores duplicates.

    @return The list of elements from list1 that could not be found in list2.

    @author Peter Marklund
} {
    if { [llength $list1] == 0 } {
        # The empty list is always a subset of any list
        return [list]
    }

    set sorted_list1 [list]
    foreach elm [lsort $list1] {
        if { [llength $sorted_list1] == 0 || ![string equal [lindex $sorted_list1 end] $elm] } {
            lappend sorted_list1 $elm
        }
    }
    set sorted_list2 [lsort $list2]
        
    set len1 [llength $sorted_list1]
    set len2 [llength $sorted_list2]

    set missing_elms [list]

    # Loop over list1 and list2 in sort order, comparing the elements
    
    set index1 0
    set index2 0
    while { $index1 < $len1 && $index2 < $len2 } { 
        set elm1 [lindex $sorted_list1 $index1]
        set elm2 [lindex $sorted_list2 $index2]
        set compare [string compare $elm1 $elm2]
        
        switch -exact -- $compare {
            -1 { 
                # elm1 < elm2
                # The first element in list1 is smaller than any element in list2, 
                # therefore this element cannot exist in list2, and therefore list1 is not a subset of list2
                lappend missing_elms $elm1
                incr index1
            }
            0 {
                # A match, great, next element
                incr index1
                incr index2
                continue
            }
            1 {
                # elm1 > elm2
                # Move to the next element in list2, knowing that this will be larger, and therefore 
                # potentially equal to the element in list1
                incr index2
            }
        }
    }

    if { $index1 == $len1 } {
        # We've reached the end of list1, finding all elements along the way, we're done
        return [list]
    } else {
        # One or more elements in list1 not found in list2
        return [concat $missing_elms [lrange $sorted_list1 $index1 end]]
    }
}

ad_proc -public ad_tcl_list_list_to_ns_set { 
    -set_id
    -put:boolean
    kv_pairs 
} {

    Takes a list of lists of key/value pairs and <code>ns_set update</code>s
    values in an ns_set.

    @param set_id If this switch is specified, it'll use this set instead of
    creating a new one.

    @param put If this boolean switch is specified, it'll use
    <code>ns_set put</code> instead of <code>ns_set update</code>
    (update is default)

    @param kv_pairs A list of lists containing key/value pairs to be stuffed into
    the ns_set

    @author Yonatan Feldman (yon@arsdigita.com)

} {

    if { ![info exists set_id] } {
	set set_id [ns_set create]
    }

    if { $put_p } {
	set command put
    } else {
	set command update
    }

    foreach kv_pair $kv_pairs {
	ns_set $command $set_id [lindex $kv_pair 0] [lindex $kv_pair 1]
    }

    return $set_id
}

ad_proc -public ad_ns_set_keys {
    -colon:boolean
    {-exclude ""}
    set_id
} {
    Returns the keys of a ns_set as a Tcl list, like <code>array names</code>.
    
    @param colon If set, will prepend all the keys with a colon; useful for bind variables
    @param exclude Optional Tcl list of key names to exclude

    @author Lars Pind (lars@pinds.com)
    
} {
    set keys [list]
    set size [ns_set size $set_id]
    for { set i 0 } { $i < $size } { incr i } {
	set key [ns_set key $set_id $i]
	if { [lsearch -exact $exclude $key] == -1 } {
	    if { $colon_p } { 
		lappend keys ":$key"
	    } else {
		lappend keys $key
	    }
	}
    }
    return $keys
}

ad_proc -public util_wrap_list {
    { -eol " \\" }
    { -indent 4 }
    { -length 70 }
    items
} {

    Wraps text to a particular line length.

    @param eol the string to be used at the end of each line.
    @param indent the number of spaces to use to indent all lines after the
        first.
    @param length the maximum line length.
    @param items the list of items to be wrapped. Items are
        HTML-formatted. An individual item will never be wrapped onto separate
        lines.

} {
    set out "<pre>"
    set line_length 0
    foreach item $items {
	regsub -all {<[^>]+>} $item "" item_notags
	if { $line_length > $indent } {
	    if { $line_length + 1 + [string length $item_notags] > $length } {
		append out "$eol\n"
		for { set i 0 } { $i < $indent } { incr i } {
		    append out " "
		}
		set line_length $indent
	    } else {
		append out " "
		incr line_length
	    }
	}
	append out $item
	incr line_length [string length $item_notags]
    }
    append out "</pre>"
    return $out
}

ad_proc -public util_text_to_url { 
    {-existing_urls {}}
    {-no_resolve:boolean}
    {-replacement "-"}
    {-text ""}
    {_text ""}
} {
    Modify a string so that it is suited as a well formatted URL path element.
    Also, if given a list of existing urls it can catch duplicate or optionally 
    create an unambiguous url by appending a dash and a digit.

    <p>

    Examples:<br>
    <code>util_text_to_url -text "Foo Bar"</code> returns <code>foo-bar</code><br>
    <code>util_text_to_url -existing_urls {foo-bar some-other-item} -text "Foo Bar"</code> returns <code>foo-bar-2</code><br>


    @param text the text to modify, e.g. "Foo Bar"
    @param _text the text to modify, e.g. "Foo Bar" (Deprecated, use -text instead. Fails when the value starts with a dash.)

    @param existing_urls a list of URLs that already exist on the same level and would cause a conflict

    @param no_resolve Specify this flag if you do not want util_text_to_url to automatically generate 
    "foo-bar-2" if "foo-bar" is already in existing_urls, and would rather have an error thrown.

    @param replacement the character that is used to replace illegal characters

    @author Tilmann Singer
} {
    if { [empty_string_p $text] } {
        set text $_text
    }

    set original_text $text
    set text [string trim [string tolower $original_text]]

    # Save some german and french characters from removal by replacing
    # them with their ascii counterparts.
    set text [string map { \x00e4 ae \x00f6 oe \x00fc ue \x00df ss \x00f8 o \x00e0 a \x00e1 a \x00e8 e \x00e9 e } $text]

    # here's the Danish ones (hm. the o-slash conflicts with the definition above, which just says 'o')
    set text [string map { \x00e6 ae \x00f8 oe \x00e5 aa \x00C6 Ae \x00d8 Oe \x00c5 Aa } $text]

    # substitute all non-word characters
    regsub -all {([^a-z0-9])+} $text $replacement text

    set text [string trim $text $replacement]

    # throw an error when the resulting string is empty
    if { [empty_string_p $text] } {
        error "Cannot compute a URL of this string: \"$original_text\" because after removing all illegal characters it's an empty string."
    }

    # check if the resulting url is already present
    if { [lsearch -exact $existing_urls $text] > -1 } {
        
        if { $no_resolve_p } {
            # URL is already present in the existing_urls list and we
            # are asked to not automatically resolve the collision
            error "The url $text is already present"
        } else {
            # URL is already present in the existing_urls list -
            # compute an unoccupied replacement using a pattern like
            # this: if foo is taken, try foo-2, then foo-3 etc.

            # Holes will not be re-occupied. E.g. if there's foo-2 and
            # foo-4, a foo-5 will be created instead of foo-3. This
            # way confusion through replacement of deleted content
            # with new stuff is avoided.
            
            set number 2

            foreach url $existing_urls {

                if { [regexp "${text}${replacement}(\\d+)\$" $url match n] } {
                    # matches the foo-123 pattern
                    if { $n >= $number } { set number [expr $n + 1] }
                }
            }
            
            set text "$text$replacement$number"
        }
    }

    return $text

}

ad_proc -public util_unlist { list args } {

    Places the <i>n</i>th element of <code>list</code> into the variable named by
    the <i>n</i>th element of <code>args</code>.

} {
    for { set i 0 } { $i < [llength $args] } { incr i } {
	upvar [lindex $args $i] val
	set val [lindex $list $i]
    }
}

ad_proc util_email_valid_p { query_email } {
    Returns 1 if an email address has more or less the correct form.
    The regexp was taken from Jeff Friedls book "Mastering Regular Expressions".

    @author Philip Greenspun (philg@mit.edu)
    @author Jeff Friedl (jfriedl@oreilly.com)
    @author Lars Pind (lars@arsdigita.com)
} {
    # This regexp was very kindly contributed by Jeff Friedl, author of 
    # _Mastering Regular Expressions_ (O'Reilly 1997).

    return [regexp "^\[^@<>\"\t ]+@\[^@<>\".\t ]+(\\.\[^@<>\".\n ]+)+$" $query_email]
}

ad_proc -public util_email_unique_p { email } {
    Returns 1 if the email passed in does not yet exist in the system.

    @author yon (yon@openforce.net)
} {
    return [db_string email_unique_p {}]
}

ad_proc -public util_url_valid_p { query_url } {
    Returns 1 if a URL is a web URL (HTTP, HTTPS or FTP).

    @author Philip Greenspun (philg@mit.edu)
} {
    return [regexp -nocase {^(http|https|ftp)://[^ ].+} [string trim $query_url]]
}

ad_proc -public value_if_exists { var_name } {
    If the specified variable exists in the calling environment,
    returns the value of that variable. Otherwise, returns the
    empty_string.
} {
    upvar $var_name $var_name
    if { [info exists $var_name] } {
        return [set $var_name]
    }
}

ad_proc -public min { args } {
    Returns the minimum of a list of numbers. Example: <code>min 2 3 1.5</code> returns 1.5.
    
    @author Ken Mayer (kmayer@bitwrangler.com)
    @creation-date 26 September 2002
} {
    set min [lindex $args 0]
    foreach arg $args {
	if { $arg < $min } {
	    set min $arg
	}
    }
    return $min
}


ad_proc -public max { args } {
    Returns the maximum of a list of numbers. Example: <code>max 2 3 1.5</code> returns 3.
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
} {
    set max [lindex $args 0]
    foreach arg $args {
	if { $arg > $max } {
	    set max $arg
	}
    }
    return $max
}

# usage: 
#   suppose the variable is called "expiration_date"
#   put "[ad_dateentrywidget expiration_date]" in your form
#     and it will expand into lots of weird generated var names
#   put ns_dbformvalue [ns_getform] expiration_date date expiration_date
#     and whatever the user typed will be set in $expiration_date

proc ad_dateentrywidget {column {default_date "1940-11-03"}} {
    ns_share NS

    set output "<select name=\"$column.month\">\n"
    for {set i 0} {$i < 12} {incr i} {
	append output "<option> [lindex $NS(months) $i]</option>\n"
    }

    append output "</select>&nbsp;<input name=\"$column.day\" type=\"text\" size=\"3\" maxlength=\"2\">&nbsp;<input name=\"$column.year\" type=\"text\" size=\"5\" maxlength=\"4\">"


    return [ns_dbformvalueput $output $column date $default_date]
}

ad_proc -public util_ns_set_to_list {
    {-set:required}
} {
    Convert an ns_set into a list suitable for passing in to the "array set" command (key value key value ...).

    @param set The ns_set to convert

    @return An array of equivalent keys and values as the ns_set specified.
} {
    set result [list]

    for {set i 0} {$i < [ns_set size $set]} {incr i} {
        lappend result [ns_set key $set $i]
        lappend result [ns_set value $set $i]
    }

    return $result
}


ad_proc -public util_list_to_ns_set { aList } {
    Convert a list in the form "key value key value ..." into a ns_set.

    @param aList The list to convert

    @return The id of a (non-persistent) ns_set
} {
    set setid [ns_set create]
    foreach {k v} $aList {
        ns_set put $setid $k $v
    }

    return $setid
}

ad_proc -public util_sets_equal_p { list1 list2 } {
    Tests whether each unique string in list1 occurs as many
    times in list1 as in list2 and vice versa (regarless of order).

    @return 1 if the lists have identical sets and 0 otherwise

    @author Peter Marklund
} {
    if { [llength $list1] != [llength $list2] } {
        return 0
    }

    set sorted_list1 [lsort $list1]
    set sorted_list2 [lsort $list2]

    for { set index1 0 } { $index1 < [llength $sorted_list1] } { incr index1 } {
        if { ![string equal [lindex $sorted_list1 $index1] [lindex $sorted_list2 $index1]] } {
            return 0
        }
    }

    return 1    
}

ad_proc -public util_http_file_upload { -file -data -binary:boolean -filename 
                               -name {-mime_type */*} {-mode formvars} 
                               {-rqset ""} url {formvars {}} {timeout 30} 
                               {depth 10} {http_referer ""}
} {
    Implement client-side HTTP file uploads as multipart/form-data as per 
    RFC 1867.
    <p>

    Similar to <a href="proc-view?proc=util_httppost">util_httppost</a>, 
    but enhanced to be able to upload a file as <tt>multipart/form-data</tt>.  
    Also useful for posting to forms that require their input to be encoded 
    as <tt>multipart/form-data</tt> instead of as 
    <tt>application/x-www-form-urlencoded</tt>.

    <p>

    The switches <tt>-file /path/to/file</tt> and <tt>-data $raw_data</tt>
    are mutually exclusive.  You can specify one or the other, but not
    both.  NOTE: it is perfectly valid to not specify either, in which
    case no file is uploaded, but form variables are encoded using
    <tt>multipart/form-data</tt> instead of the usual encoding (as
    noted aboved).

    <p>

    If you specify either <tt>-file</tt> or <tt>-data</tt> you 
    <strong>must</strong> supply a value for <tt>-name</tt>, which is
    the name of the <tt>&lt;INPUT TYPE="file" NAME="..."&gt;</tt> form
    tag.

    <p>

    Specify the <tt>-binary</tt> switch if the file (or data) needs
    to be base-64 encoded.  Not all servers seem to be able to handle
    this.  (For example, http://mol-stage.usps.com/mml.adp, which
    expects to receive an XML file doesn't seem to grok any kind of
    Content-Transfer-Encoding.)

    <p>

    If you specify <tt>-file</tt> then <tt>-filename</tt> is optional
    (it can be infered from the name of the file).  However, if you
    specify <tt>-data</tt> then it is mandatory.

    <p>

    If <tt>-mime_type</tt> is not specified then <tt>ns_guesstype</tt>
    is used to try and find a mime type based on the <i>filename</i>.  
    If <tt>ns_guesstype</tt> returns <tt>*/*</tt> the generic value
    of <tt>application/octet-stream</tt> will be used.
   
    <p>

    Any form variables may be specified in one of four formats:
    <ul>
    <li><tt>array</tt> (list of key value pairs like what [array get] returns)
    <li><tt>formvars</tt> (list of url encoded formvars, i.e. foo=bar&x=1)
    <li><tt>ns_set</tt> (an ns_set containing key/value pairs)
    <li><tt>vars</tt> (a list of tcl vars to grab from the calling enviroment)
    </ul>

    <p>

    <tt>-rqset</tt> specifies an ns_set of extra headers to send to
    the server when doing the POST.

    <p>

    timeout, depth, and http_referer are optional, and are included
    as optional positional variables in the same order they are used
    in <tt>util_httppost</tt>.  NOTE: <tt>util_http_file_upload</tt> does
    not (currently) follow any redirects, so depth is superfulous.

    @author Michael A. Cleverly (michael@cleverly.com)
    @creation-date 3 September 2002
} {

    # sanity checks on switches given
    if {[lsearch -exact {formvars array ns_set vars} $mode] == -1} {
        error "Invalid mode \"$mode\"; should be one of: formvars,\
            array, ns_set, vars"
    }
 
    if {[info exists file] && [info exists data]} {
        error "Both -file and -data are mutually exclusive; can't use both"
    }

    if {[info exists file]} {
        if {![file exists $file]} {
            error "Error reading file: $file not found"
        }

        if {![file readable $file]} {
            error "Error reading file: $file permission denied"
        }

        set fp [open $file]
        fconfigure $fp -translation binary
        set data [read $fp]
        close $fp

        if {![info exists filename]} {
            set filename [file tail $file]
        }

        if {[string equal */* $mime_type] || [empty_string_p $mime_type]} {
            set mime_type [ns_guesstype $file]
        }
    }

    set boundary [ns_sha1 [list [clock clicks -milliseconds] [clock seconds]]]
    set payload {}

    if {[info exists data] && [string length $data]} {
        if {![info exists name]} {
            error "Cannot upload file without specifing form variable -name"
        }
    
        if {![info exists filename]} {
            error "Cannot upload file without specifing -filename"
        }
    
        if {[string equal $mime_type */*] || [empty_string_p $mime_type]} {
            set mime_type [ns_guesstype $filename]
    
            if {[string equal $mime_type */*] || [empty_string_p $mime_type]} {
                set mime_type application/octet-stream
            }
        }

        if {$binary_p} {
            set data [base64::encode base64]
            set transfer_encoding base64
        } else {
            set transfer_encoding binary
        }

        append payload --$boundary \
                       \r\n \
                       "Content-Disposition: form-data; " \
                       "name=\"$name\"; filename=\"$filename\"" \
                       \r\n \
                       "Content-Type: $mime_type" \
                       \r\n \
                       "Content-transfer-encoding: $transfer_encoding" \
                       \r\n \
                       \r\n \
                       $data \
                       \r\n
    }


    set variables [list]
    switch -- $mode {
        array {
            set variables $formvars 
        }

        formvars {
            foreach formvar [split $formvars &] {
                set formvar [split $formvar  =]
                set key [lindex $formvar 0]
                set val [join [lrange $formvar 1 end] =]
                lappend variables $key $val
            }
        }

        ns_set {
            for {set i 0} {$i < [ns_set size $formvars]} {incr i} {
                set key [ns_set key $formvars $i]
                set val [ns_set value $formvars $i]
                lappend variables $key $val
            }
        }

        vars {
            foreach key $formvars {
                upvar 1 $key val
                lappend variables $key $val
            }
        }
    }

    foreach {key val} $variables {
        append payload --$boundary \
                       \r\n \
                       "Content-Disposition: form-data; name=\"$key\"" \
                       \r\n \
                       \r\n \
                       $val \
                       \r\n
    }

    append payload --$boundary-- \r\n

    if { [catch {
        if {[incr depth -1] <= 0} {
            return -code error "util_http_file_upload:\
                Recursive redirection: $url"
        }

        set http [util_httpopen POST $url $rqset $timeout $http_referer]
        set rfd  [lindex $http 0]
        set wfd  [lindex $http 1]

        _ns_http_puts $timeout $wfd \
            "Content-type: multipart/form-data; boundary=$boundary\r"
        _ns_http_puts $timeout $wfd "Content-length: [string length $payload]\r"
        _ns_http_puts $timeout $wfd \r
        _ns_http_puts $timeout $wfd "$payload\r"
        flush $wfd
        close $wfd
        
        set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
        while 1 {
            set line [_ns_http_gets $timeout $rfd]
            if { ![string length $line] } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        set length [ns_set iget $headers content-length]
        if { [string match "" $length] } { set length -1 }
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { [string match "" $buf] } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]

        ns_set free $headers
        close $rfd

        if $err {
            global errorInfo
            return -code error -errorinfo $errorInfo $errMsg
        }
    } errmsg] } {return -1}
    
    return $page
}

ad_proc -public util_list_of_ns_sets_to_list_of_lists {
    {-list_of_ns_sets:required}
} {
    Transform a list of ns_sets (most likely produced by db_list_of_ns_sets)
    into a list of lists that match the array set format in the sublists
    (key value key value ...) 
    
    @param -list_of_ns_sets A list of ns_set ids
    
    @author Ola Hansson (ola@polyxena.net)
    @creation-date September 27, 2002
} {
    set result [list]
    
    foreach ns_set $list_of_ns_sets {
	lappend result [util_ns_set_to_list -set $ns_set]
    }
    
    return $result
}

ad_proc -public xml_get_child_node_content_by_path {
    node
    path_list
} {
    Return the first non-empty contents of a child node down a given path from the current node.

    <p>
    
    Example:<pre>
set tree [xml_parse -persist {
    &lt;enterprise&gt;
      &lt;properties&gt;
        &lt;datasource&gt;Dunelm Services Limited&lt;/datasource&gt;
        &lt;target&gt;Telecommunications LMS&lt;/target&gt;
        &lt;type&gt;DATABASE UPDATE&lt;/type&gt;
        &lt;datetime&gt;2001-08-08&lt;/datetime&gt;
      &lt;/properties&gt;
      &lt;person recstatus = &quot;1&quot;&gt;
        &lt;comments&gt;Add a new Person record.&lt;/comments&gt;
        &lt;sourcedid&gt;
          &lt;source&gt;Dunelm Services Limited&lt;/source&gt;
          &lt;id&gt;CK1&lt;/id&gt;
        &lt;/sourcedid&gt;
        &lt;name&gt;
          &lt;fn&gt;Clark Kent&lt;/fn&gt;
          &lt;sort&gt;Kent, C&lt;/sort&gt;
          &lt;nickname&gt;Superman&lt;/nickname&gt;
        &lt;/name&gt;
        &lt;demographics&gt;
          &lt;gender&gt;2&lt;/gender&gt;
        &lt;/demographics&gt;
        &lt;adr&gt;
          &lt;extadd&gt;The Daily Planet&lt;/extadd&gt;
          &lt;locality&gt;Metropolis&lt;/locality&gt;
          &lt;country&gt;USA&lt;/country&gt;
        &lt;/adr&gt;
      &lt;/person&gt;
    &lt;/enterprise&gt;
}]

set root_node [xml_doc_get_first_node $tree]

aa_equals &quot;person -&gt; name -&gt; nickname is Superman&quot; \
    [xml_get_child_node_content_by_path $root_node { { person name nickname } }] &quot;Superman&quot;

aa_equals &quot;Same, but after trying a couple of non-existent paths or empty notes&quot; \
    [xml_get_child_node_content_by_path $root_node { { does not exist } { properties } { person name nickname } { person sourcedid id } }] &quot;Superman&quot;
aa_equals &quot;properties -&gt; datetime&quot; \
    [xml_get_child_node_content_by_path $root_node { { person commments foo } { person name first_names } { properties datetime } }] &quot;2001-08-08&quot;
</pre>

    @param node        The node to start from
    @param path_list   List of list of nodes to try, e.g. 
                       { { user_id } { sourcedid id } }, or { { name given } { name fn } }.

    @author Lars Pind (lars@collaboraid.biz)
} {
    set result {}
    foreach path $path_list {
        set current_node $node
        foreach element_name $path {
            set current_node [xml_node_get_first_child_by_name $current_node $element_name]

            if { [empty_string_p $current_node] } {
                # Try the next path
                break
            }
        }
        if { ![empty_string_p $current_node] } {
            set result [xml_node_get_content $current_node]
            if { ![empty_string_p $result] } {
                # Found the value, we're done
                break
            }
        }
    }
    return $result
}


ad_proc -public xml_get_child_node_attribute_by_path {
    node
    path_list
    attribute_name
} {

    Return the attribute of a child node down a give path from the current node.

    <p>

    Example:<pre>
    set tree [xml_parse -persist "
&lt;enterprise&gt;
  &lt;properties&gt;
    &lt;datasource&gt;University of Durham: SIS&lt;/datasource&gt;
    &lt;target&gt;University of Durham: LMS&lt;/target&gt;
    &lt;type&gt;CREATE&lt;/type&gt;
    &lt;datetime&gt;2001-08-08&lt;/datetime&gt;
  &lt;/properties&gt;
  &lt;group recstatus = "1"&gt;
    &lt;sourcedid&gt;
      &lt;source&gt;University of Durham&lt;/source&gt;
      &lt;id&gt;CS1&lt;/id&gt;
    &lt;/sourcedid&gt;
    &lt;grouptype&gt;
      &lt;scheme&gt;University of Durham&lt;/scheme&gt;
      &lt;typevalue level = "2"/&gt;
    &lt;/grouptype&gt;

    .....

  &lt;/group&gt;
&lt;/enterprise&gt;

"]
    set root_node [xml_doc_get_first_node $tree]
    set group_node [xml_node_get_children_by_name $root_node "group"] 
    set typevalue [xml_get_child_node_attribute_by_path $group_node {grouptype typevalue} "level"]

    @param node        The node to start from
    @param path_list   List of the node to try, e.g. 
                         { grouptype typevalue }.
    @param attribute_name   Attribute name at the very end of the very botton of the tree route at path_list.

    @author Rocael Hernandez (roc@viaro.net)

} {

    set attribute {}
    set current_node $node
    foreach element_name $path_list {
	set current_node [xml_node_get_first_child_by_name $current_node $element_name]
	if { [empty_string_p $current_node] } {
	    # Try the next path
	    break
	}
    }

    if { ![empty_string_p $current_node] } {
	set attribute [xml_node_get_attribute $current_node $attribute_name ""]
    }

    return $attribute

}


ad_proc -public ad_generate_random_string {{length 8}} {
    Generates a random string made of numbers and letters
} {
    return [string range [sec_random_token] 0 $length]
}

ad_proc -public with_finally {
    -code:required
    -finally:required
} {
    Execute CODE, then execute cleanup code FINALLY.
    If CODE completes normally, its value is returned after
    executing FINALLY.
    If CODE exits non-locally (as with error or return), FINALLY
    is executed anyway.

    @param code Code to be executed that could throw and error
    @param finally Cleanup code to be executed even if an error occurs
} {
    global errorInfo errorCode

    # Execute CODE.
    set return_code [catch {uplevel $code} string]
    set s_errorInfo $errorInfo
    set s_errorCode $errorCode

    # As promised, always execute FINALLY.  If FINALLY throws an
    # error, Tcl will propagate it the usual way.  If FINALLY contains
    # stuff like break or continue, the result is undefined.
    uplevel $finally

    switch $return_code {
	0 {
	    # CODE executed without a non-local exit -- return what it
	    # evaluated to.
	    return $string
	}
	1 {
	    # Error
	    return -code error -errorinfo $s_errorInfo -errorcode $s_errorCode $string
	}
	2 {
	    # Return from the caller.
	    return -code return $string
	}
	3 {
	    # break
	    return -code break
	}
	4 {
	    # continue
	    return -code continue
	}
	default {
	    return -code $return_code $string
	}
    }
}

ad_proc util_background_exec {
    {-pass_vars ""}
    {-name:required}
    code_chunk
} {
    Executes a chunk of code in the background. The code is run exclusively, 
    meaning that no two threads with the same name can run at the same time.
    
    @param name The name of the thread. No two chunks with the same name can run at the same time.

    @param pass_vars Names of variables which you want passed to the code chunk

    @param code_chunk The chunk you want executed
} {
    ns_log Debug "util_background_exec: Starting, waiting for mutex"

#    ns_mutex lock [nsv_get util_background_exec_mutex .]

    ns_log Debug "util_background_exec: Got mutex"

    set running_p [nsv_exists util_background_exec $name]
    if { !$running_p } {
        nsv_set util_background_exec [list $name] 1
    }

#    ns_mutex unlock [nsv_get util_background_exec_mutex .]
    ns_log Debug "util_background_exec: Released mutex"

    if { $running_p } {
        ns_log Notice "util_background_exec: $name is already running, exiting"
        return
    }

    set code {}
    foreach var $pass_vars {
        upvar 1 $var the_var
        if { [array exists the_var] } {
            append code "array set [list $var] [list [array get the_var]]\n"
        } else {
            append code "set [list $var] [list $the_var]\n"
        }
    }

    append code "
        set errno \[catch {
            $code_chunk
        } errmsg\]

        set errinfo {}
        set errcode {}
        if { \$errno == 1 } {
            global errorInfo errorCode
            set errinfo \$errorInfo
            set errcode \$errorCode
        }

        if { \$errno == 1 } {
            \# This is an error
            ns_log Error \"util_background_exec: Error in thread named '$name': \$errorInfo\"
        }

        \# errno = 0 (TCL_OK) or 2 (TCL_RETURN) is considered normal, i.e. first elm is true
        set success_p \[expr { \$errno == 0 || \$errno == 2 }\]
        set result \[list \$success_p \$errmsg \$errno \$errinfo \$errcode]

        ns_log debug \"util_background_exec: Thread named '$name' returned \$result\"

        nsv_unset util_background_exec [list $name]
        nsv_set util_background_exec_result [list $name] \$result

    "
    ns_log Debug "util_background_exec: Scheduling code\n$code"

    ns_schedule_proc -thread -once 1 $code
}

ad_proc util_background_running_p {
    {-name:required}
} {
    
} { 
    set running_p [nsv_exists util_background_exec $name]
    return $running_p
}

ad_proc util_background_get_result {
    {-name:required}
} {
    Gets the result of a completed background thread execution.
} { 
    return [nsv_get util_background_exec_result $name]
}

ad_proc util_background_reset {
    {-name:required}
} {
    Gets the result of a completed background thread execution.
} { 
    nsv_unset util_background_exec $name
}



#####
#
# This is some old security crud from before we had ad_page_contract
#
#####


# michael@arsdigita.com: A better name for this proc would be
# "ad_block_sql_fragment_form_data", since "form data" is the
# official term for query string (URL) variables and form input
# variables.
#
ad_proc -public -deprecated ad_block_sql_urls {
    conn
    args
    why
} {

    A filter that detect attempts to smuggle in SQL code through form data
    variables. The use of bind variables and ad_page_contract input 
    validation to prevent SQL smuggling is preferred.

    @see ad_page_contract
} {
    set form [ns_getform]
    if { [empty_string_p $form] } { return filter_ok }

    # Check each form data variable to see if it contains malicious
    # user input that we don't want to interpolate into our SQL
    # statements.
    #
    # We do this by scanning the variable for suspicious phrases; at
    # this time, the phrases we look for are: UNION, UNION ALL, and
    # OR.
    #
    # If one of these phrases is found, we construct a test SQL query
    # that incorporates the variable into its WHERE clause and ask
    # the database to parse it. If the query does parse successfully,
    # then we know that the suspicious user input would result in a
    # executing SQL that we didn't write, so we abort processing this
    # HTTP request.
    #
    set n_form_vars [ns_set size $form]
    for { set i 0 } { $i < $n_form_vars } { incr i } {
        set key [ns_set key $form $i]
        set value [ns_set value $form $i]

	# michael@arsdigita.com:
	#
	# Removed 4000-character length check, because that allowed
	# malicious users to smuggle SQL fragments greater than 4000
	# characters in length.
	#
        if {
	    [regexp -nocase {[^a-z_]or[^a-z0-9_]} $value] ||
	    [regexp -nocase {union([^a-z0-9_].*all)?[^a-z0-9_].*select} $value]
	} {
	    # Looks like the user has added "union [all] select" to
	    # the variable, # or is trying to modify the WHERE clause
	    # by adding "or ...".
	    #
            # Let's see if Oracle would accept this variables as part
	    # of a typical WHERE clause, either as string or integer.
	    #
	    # michael@arsdigita.com: Should we grab a handle once
	    # outside of the loop?
	    #
            set parse_result_integer [db_string sql_test_1 "select test_sql('select 1 from dual where 1=[DoubleApos $value]') from dual"]

            if { [string first "'" $value] != -1 } {
		#
		# The form variable contains at least one single
		# quote. This can be a problem in the case that
		# the programmer forgot to QQ the variable before
		# interpolation into SQL, because the variable
		# could contain a single quote to terminate the
		# criterion and then smuggled SQL after that, e.g.:
		#
		#   set foo "' or 'a' = 'a"
		#
		#   db_dml "delete from bar where foo = '$foo'"
		#
		# which would be processed as:
		#
		#   delete from bar where foo = '' or 'a' = 'a'
		#
		# resulting in the effective truncation of the bar
		# table.
		#
                set parse_result_string [db_string sql_test_2 "select test_sql('select 1 from dual where 1=[DoubleApos "'$value'"]') from dual"]
            } else {
                set parse_result_string 1
            }

            if {
		$parse_result_integer == 0 ||
		$parse_result_integer == -904  ||
		$parse_result_integer == -1789 ||
		$parse_result_string == 0 ||
		$parse_result_string == -904 ||
		$parse_result_string == -1789
	    } {
                # Code -904 means "invalid column", -1789 means
		# "incorrect number of result columns". We treat this
		# the same as 0 (no error) because the above statement
		# just selects from dual and 904 or 1789 only occur
		# after the parser has validated that the query syntax
		# is valid.

                ns_log Error "ad_block_sql_urls: Suspicious request from [ad_conn peeraddr]. Parameter $key contains code that looks like part of a valid SQL WHERE clause: [ad_conn url]?[ad_conn query]"

		# michael@arsdigita.com: Maybe we should just return a
		# 501 error.
		#
                ad_return_error "Suspicious Request" "Parameter $key looks like it contains SQL code. For security reasons, the system won't accept your request."

                return filter_return
            }
        }
    }

    return filter_ok
}

ad_proc -public -deprecated ad_set_typed_form_variable_filter {
    url_pattern
    args
} {
    <pre>
    #
    # Register special rules for form variables.
    #
    # Example:
    #
    #    ad_set_typed_form_variable_filter /my_module/* {a_id number} {b_id word} {*_id integer}
    #
    # For all pages under /my_module, set_form_variables would set 
    # $a_id only if it was number, and $b_id only if it was a 'word' 
    # (a string that contains only letters, numbers, dashes, and 
    # underscores), and all other variables that match the pattern
    # *_id would be set only if they were integers.
    #
    # Variables not listed have no restrictions on them.
    #
    # By default, the three supported datatypes are 'integer', 'number',
    # and 'word', although you can add your own type by creating
    # functions named ad_var_type_check_${type_name}_p which should
    # return 1 if the value is a valid $type_name, or 0 otherwise.
    #
    # There's also a special datatype named 'nocheck', which will
    # return success regardless of the value. (See the docs for 
    # ad_var_type_check_${type_name}_p to see how this might be
    # useful.)
    #
    # The default data_type is 'integer', which allows you shorten the
    # command above to:
    #
    #    ad_set_typed_form_variable_filter /my_module/* a_id {b_id word}
    #

    ad_page_contract is the preferred mechanism to do automated
    validation of form variables.
    </pre>
    @see ad_page_contract
} {
    ad_register_filter postauth GET  $url_pattern ad_set_typed_form_variables $args
    ad_register_filter postauth POST $url_pattern ad_set_typed_form_variables $args
}

proc ad_set_typed_form_variables {conn args why} {

    global ad_typed_form_variables

    eval lappend ad_typed_form_variables [lindex $args 0]

    return filter_ok
}

#
# All the ad_var_type_check* procs get called from 
# check_for_form_variable_naughtiness. Read the documentation
# for ad_set_typed_form_variable_filter for more details.

proc_doc ad_var_type_check_integer_p {value} {
    <pre>
    #
    # return 1 if $value is an integer, 0 otherwise.
    #
    <pre>
} {

    if { [regexp {[^0-9]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_safefilename_p {value} {
    <pre>
    #
    # return 0 if the file contains ".."
    #
    <pre>
} {

    if { [string match *..* $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_dirname_p {value} {
    <pre>
    #
    # return 0 if $value contains a / or \, 1 otherwise.
    #
    <pre>
} {

    if { [regexp {[/\\]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_number_p {value} {
    <pre>
    #
    # return 1 if $value is a valid number
    #
    <pre>
} {
    if { [catch {expr 1.0 * $value}] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_word_p {value} {
    <pre>
    #
    # return 1 if $value contains only letters, numbers, dashes, 
    # and underscores, otherwise returns 0.
    #
    </pre>
} {

    if { [regexp {[^-A-Za-z0-9_]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_nocheck_p {{value ""}} {
    <pre>
    #
    # return 1 regardless of the value. This useful if you want to 
    # set a filter over the entire site, then create a few exceptions.
    #
    # For example:
    #
    #   ad_set_typed_form_variable_filter /my-dangerous-page.tcl {user_id nocheck}
    #   ad_set_typed_form_variable_filter /*.tcl user_id
    #
    </pre>
} {
    return 1
}

proc_doc ad_var_type_check_noquote_p {value} {
    <pre>
    #
    # return 1 if $value contains any single-quotes
    #
    <pre>
} {

    if { [string match *'* $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_integerlist_p {value} {
    <pre>
    #
    # return 1 if list contains only numbers, spaces, and commas.
    # Example '5, 3, 1'. Note: it doesn't allow negative numbers,
    # because that could let people sneak in numbers that get
    # treated like math expressions like '1, 5-2'
    #
    #
    <pre>
} {

    if { [regexp {[^ 0-9,]} $value] } {
        return 0
    } else {
        return 1
    }
}

proc_doc ad_var_type_check_fail_p {value} {
    <pre>
    #
    # A check that always returns 0. Useful if you want to disable all access
    # to a page.
    #
    <pre>
} {
    return 0
}

proc_doc ad_var_type_check_third_urlv_integer_p {{args ""}} {
    <pre>
    #
    # Returns 1 if the third path element in the URL is integer.
    #
    <pre>
} {

    set third_url_element [lindex [ad_conn urlv] 3]

    if { [regexp {[^0-9]} $third_url_element] } {
        return 0
    } else {
        return 1
    }
}

####################
#
# Procs in the util namespace
#
####################

ad_proc -public util::backup_file {
    {-file_path:required}
    {-backup_suffix ".bak"}
} {
    Backs up (move) the file or directory with given path to a file/directory with a backup suffix.
    Will avoid overwriting old backup files by adding a number to the filename to make it unique.
    For example, suppose you are backing up /web/my-server/packages/my-package/file.txt and
    the file has already been backed up to /web/my-server/packages/my-package/file.txt.bak. Invoking
    this proc will then generate the backup file /web/my-server/packages/my-package/file.txt.bak.2

    @param backup_suffix The suffix to add to the backup file.

    @author Peter Marklund
} {
    # Keep generating backup paths until we find one that doesn't already exist
    set backup_counter 1
    while 1 {
        if { $backup_counter == "1" } {
            set backup_path "${file_path}${backup_suffix}"
        } else {
            set backup_path "${file_path}${backup_suffix}.${backup_counter}"
        }
        
        if { ![file exists $backup_path] } {
            # We found a non-existing backup path
            break
        }

        incr backup_counter
    }

    exec "mv" "$file_path" "$backup_path"
}



ad_proc -public util::subst_safe { string } {
    Make string safe for subst'ing.
} {
    regsub -all {\$} $string {\$} string
    regsub -all {\[} $string {\[} string
    regsub -all {\]} $string {\]} string
    return $string
}

ad_proc -public util::array_list_spec_pretty { 
    list 
    {indent 0} 
} {
    Pretty-format an array-list spec with proper indentation.
} {
    set output {}
    foreach { elm val } $list {
        if { [llength $val] > 1 && [expr [llength $val] % 2] == 0  } {
            append output [string repeat " " $indent] "$elm \{" \n

            append output [util::array_list_spec_pretty $val [expr $indent + 4]]

            append output [string repeat " " $indent] \} \n
        } else {
            append output [string repeat " " $indent] [list $elm] " " [list $val] \n
        }
    }
    return $output
}

ad_proc -public util::interval_pretty {
    {-seconds 0}
} { 
    Takes a number of seconds and returns a pretty interval of the form "3h 49m 13s"
} {
    set result {}
    if { $seconds > 0 } {
        set hrs [expr $seconds / (60*60)]
        set mins [expr ($seconds / 60) % 60]
        set secs [expr $seconds % 60]
        if { $hrs > 0 } { append result "${hrs}h " }
        if { $hrs > 0 || $mins > 0 } { append result "${mins}m " }
        append result "${secs}s"
    }
    return $result
}

ad_proc -public util::randomize_list {
    list
} {
    Returns a random permutation of the list.
} {
    set len [llength $list]
    set result [list]
    while { [llength $list] > 0 } {
        set index [randomRange [llength $list]]
        lappend result [lindex $list $index]
        set list [lreplace $list $index $index]
    }
    return $result
}

ad_proc -public util::age_pretty {
    -timestamp_ansi:required
    -sysdate_ansi:required
    {-hours_limit 12}
    {-days_limit 3}
    {-mode_2_fmt "%X, %A"}
    {-mode_3_fmt "%X, %d %b %Y"}
    {-locale ""}
} {
    Formats past time intervals in one of three different modes depending on age.  The first mode is "1 hour 3 minutes" and is NOT currently internationalized.  The second mode is e.g. "14:10, Thursday" and is internationalized.  The third mode is "14:10, 01 Mar 2001" and is internationalized.  Both the locale and the exact format string for modes 2 and 3 can be overridden by parameters.  (Once mode 1 is i18nd, the following sentence will be true:'In mode 1, only the locale can be overridden.'  Until then, move along.  These aren't the timestamps you're looking for.)

    @param timestamp_ansi The older timestamp in full ANSI: YYYY-MM-DD HH24:MI:SS
    @param sysdate_ansi The newer timestamp.

    @param hours_limit The upper limit, in hours, for mode 1.
    @param days_limit The upper limit, in days, for mode 2.
    @param mode_2_fmt A formatting string, as per <a href="/api-doc/proc-view?proc=lc_time_fmt">lc_time_fmt</a>, for mode 2
    @param mode_3_fmt A formatting string, as per <a href="/api-doc/proc-view?proc=lc_time_fmt">lc_time_fmt</a>, for mode 3
    @param locale If present, overrides the default locale
    @return Interval between timestamp and sysdate, as localized text string.
} {
    set age_seconds [expr [clock scan $sysdate_ansi] - [clock scan $timestamp_ansi]]

    if { $age_seconds < 30 } {
        # Handle with normal processing below -- otherwise this would require another string to localize
        set age_seconds 60
    }

   if { $age_seconds < [expr $hours_limit * 60 * 60] } {
        set hours [expr abs($age_seconds / 3600)]
        set minutes [expr round(($age_seconds% 3600)/60.0)]
        if {[expr $hours < 24]} {
            switch $hours {
                0 { set result "" }
                1 { set result "One hour " }
                default { set result "$hours hours "}
            }
            switch $minutes {
                0 {}
                1 { append result "$minutes minute " }
                default { append result "$minutes minutes " }
            }
        } else {
            set days [expr abs($hours / 24)]
            switch $days {
                1 { set result "One day " }
                default { set result "$days days "}
            }
        }

        append result "ago"
    } elseif { $age_seconds < [expr $days_limit * 60 * 60 * 24] } {
        set result [lc_time_fmt $timestamp_ansi $mode_2_fmt $locale]
    } else {
        set result [lc_time_fmt $timestamp_ansi $mode_3_fmt $locale]

    }
}


ad_proc -public util::word_diff {
	{-old:required}
	{-new:required}
	{-split_by {}}
	{-filter_proc {ad_quotehtml}}
	{-start_old {<strike><i><font color="blue">}}
	{-end_old {</font></i></strike>}}
	{-start_new {<u><b><font color="red">}}
	{-end_new {</font></b></u>}}
} {
	Does a word (or character) diff on two lines of text and indicates text
	that has been deleted/changed or added by enclosing it in
	start/end_old/new.
	
	@param	old	The original text.
	@param	new	The modified text.
	
	@param	split_by	If split_by is a space, the diff will be made
	on a word-by-word basis. If it is the empty string, it will be made on
	a char-by-char basis.

	@param	filter_proc	A filter to run the old/new text through before
	doing the diff and inserting the HTML fragments below. Keep in mind
	that if the input text is HTML, and the start_old, etc... fragments are
	inserted at arbitrary locations depending on where the diffs are, you
	might end up with invalid HTML unless the original HTML is quoted.

	@param	start_old	HTML fragment to place before text that has been removed.
	@param	end_old		HTML fragment to place after text that has been removed.
	@param	start_new	HTML fragment to place before new text.
	@param	end_new		HTML fragment to place after new text.

	@see ad_quotehtml
	@author Gabriel Burca
} {

	if {$filter_proc != ""} {
		set old [$filter_proc $old]
		set new [$filter_proc $new]
	}

	set old_f [ns_tmpnam]
	set new_f [ns_tmpnam]
	set old_fd [open $old_f "w"]
	set new_fd [open $new_f "w"]
	puts $old_fd [join [split $old $split_by] "\n"]
	puts $new_fd [join [split $new $split_by] "\n"]
	close $old_fd
	close $new_fd

	# Diff output is 1 based, our lists are 0 based, so insert a dummy
	# element to start the list with.
	set old_w [linsert [split $old $split_by] 0 {}]
	set sv 1

#	For debugging purposes:
#	set diff_pipe [open "| diff -f $old_f $new_f" "r"]
#	while {![eof $diff_pipe]} {
#		append res "[gets $diff_pipe]<br>"
#	}

	set diff_pipe [open "| diff -f $old_f $new_f" "r"]
	while {![eof $diff_pipe]} {
		gets $diff_pipe diff
		if {[regexp {^d(\d+)(\s+(\d+))?$} $diff full m1 m2]} {
			if {$m2 != ""} {set d_end $m2} else {set d_end $m1}
			for {set i $sv} {$i < $m1} {incr i} {
				append res "${split_by}[lindex $old_w $i]"
			}
			for {set i $m1} {$i <= $d_end} {incr i} {
				append res "${split_by}${start_old}[lindex $old_w $i]${end_old}"
			}
			set sv [expr $d_end + 1]
		} elseif {[regexp {^c(\d+)(\s+(\d+))?$} $diff full m1 m2]} {
			if {$m2 != ""} {set d_end $m2} else {set d_end $m1}
			for {set i $sv} {$i < $m1} {incr i} {
				append res "${split_by}[lindex $old_w $i]"
			}
			for {set i $m1} {$i <= $d_end} {incr i} {
				append res "${split_by}${start_old}[lindex $old_w $i]${end_old}"
			}
			while {![eof $diff_pipe]} {
				gets $diff_pipe diff
				if {$diff == "."} {
					break
				} else {
					append res "${split_by}${start_new}${diff}${end_new}"
				}
			}
			set sv [expr $d_end + 1]
		} elseif {[regexp {^a(\d+)$} $diff full m1]} {
			set d_end $m1
			for {set i $sv} {$i < $m1} {incr i} {
				append res "${split_by}[lindex $old_w $i]"
			}
			while {![eof $diff_pipe]} {
				gets $diff_pipe diff
				if {$diff == "."} {
					break
				} else {
					append res "${split_by}${start_new}${diff}${end_new}"
				}
			}
			set sv [expr $d_end + 1]
		}
	}
	
	for {set i $sv} {$i < [llength $old_w]} {incr i} {
		append res "${split_by}[lindex $old_w $i]"
	}

	file delete -- $old_f $new_f

	return $res
}

ad_proc -public util::string_length_compare { s1 s2 } {
    String length comparison function for use with lsort's -command switch.
} {
    set l1 [string length $s1]
    set l2 [string length $s2]
    if { $l1 < $l2 } {
	return -1
    } elseif { $l1 > $l2 } {
	return 1
    } else {
	return 0
    }
}

ad_proc -public util::roll_server_log {{}} {
    Invoke the AOLserver ns_logroll command with some bookend log records.  This rolls the error log, not the access log.
} { 
    # This param controlls how many backups of the server log to keep, 
    ns_config -int "ns/parameters" maxbackup 7
    ns_log Notice "util::roll_server_log: Rolling the server log now..." 
    ns_logroll 
    ns_log Notice "util::roll_server_log: Done rolling the server log." 
    return 0
} 

ad_proc -public util::cookietime {time} {
    Return an RFC2109 compliant string for use in "Expires".
} {
    regsub {, (\d+) (\S+) (\d+)} [ns_httptime $time] {, \1-\2-\3} string
    return $string
}

ad_proc -public util::find_all_files {
    {-include_dirs 0}
    {-max_depth 1}
    {-check_file_func ""}
    {-extension ""}
    {-path:required}
} {

    Returns a list of lists with full paths and filename to all files under $path in the directory tree
    (descending the tree to a depth of up to $max_depth).  Clients should not 
    depend on the order of files returned.

    DOES NOT WORK ON WINDOWS (you have to change the splitter and I don't know how to detect a windows system)

    @param include_dirs Should directories be included in the list of files. 
    @param max_depth How many levels of directories should be searched. Defaults to 1 which is the current directory
    @param check_file_func Function which can be executed upon the file to determine if it is worth the effort
    @param extension Only return files with this extension (single value !)
    @param path The path in which to search for the files. Note that this is an absolute Path

    @return list of lists (filename and full_path) of all files found.
} {
    # Use the examined_files array to track files that we've examined.
    array set examined_files [list]

    # A list of files that we will return (in the order in which we
    # examined them).
    set files [list]

    # A list of files that we still need to examine.
    set files_to_examine [list $path]

    # Perform a breadth-first search of the file tree. For each level,
    # examine files in $files_to_examine; if we encounter any directories,
    # add contained files to $new_files_to_examine (which will become
    # $files_to_examine in the next iteration).
    while { [incr max_depth -1] > -2 && [llength $files_to_examine] != 0 } {
	set new_files_to_examine [list]
	foreach file $files_to_examine {
	    # Only examine the file if we haven't already. (This is just a safeguard
	    # in case, e.g., Tcl decides to play funny games with symbolic links so
	    # we end up encountering the same file twice.)
	    if { ![info exists examined_files($file)] } {
		# Remember that we've examined the file.
		set examined_files($file) 1

		if { [empty_string_p $check_file_func] || [eval [list $check_file_func $file]] } {
		    # If it's a file, add to our list. If it's a
		    # directory, add its contents to our list of files to
		    # examine next time.
		    
		    set filename [lindex [split $file "/"] end]
		    set file_extension [lindex [split $filename "."] end]
		    if { [file isfile $file] } {
			if {$extension eq "" || $file_extension eq $extension} {
			    lappend files [list $filename $file]
			}
		    } elseif { [file isdirectory $file] } {
			if { $include_dirs == 1 } {
			    lappend files $file
			}
			set new_files_to_examine [concat $new_files_to_examine [glob -nocomplain "$file/*"]]
		    }
		}
	    }
	}
	set files_to_examine $new_files_to_examine
    }
    return $files
}
