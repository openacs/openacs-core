ad_library {

    Provides a variety of non-ACS-specific utilities

    @author Various (acs@arsdigita.com)
    @date 13 April 2000
    @cvs-id $Id$
}

# Let's define the nsv arrays out here, so we can call nsv_exists
# on their keys without checking to see if it already exists.
# we create the array by setting a bogus key.

proc proc_source_file_full_path {proc_name} {
    if ![nsv_exists proc_source_file $proc_name] {
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

# stuff to process the data that comes 
# back from the users

# if the form looked like
# <input type=text name=yow> and <input type=text name=bar> 
# then after you run this function you'll have Tcl vars 
# $foo and $bar set to whatever the user typed in the form

# this uses the initially nauseating but ultimately delicious
# Tcl system function "uplevel" that lets a subroutine bash
# the environment and local vars of its caller.  It ain't Common Lisp...

# This is an ad-hoc check to make sure users aren't trying to pass in
# "naughty" form variables in an effort to hack the database by passing
# in SQL. It is called in all instances where a Tcl variable
# is set from a form variable.

proc_doc check_for_form_variable_naughtiness { 
    name 
    value 
} {
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
        if [empty_string_p $tmpdir_list] {
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

    if [info exists ad_typed_form_variables] { 

        foreach typed_var_spec $ad_typed_form_variables {
            set typed_var_name [lindex $typed_var_spec 0]
        
            if ![string match $typed_var_name $name] {
                # no match. Go to the next variable in the list
                continue
            }
        
            # the variable matched the pattern
            set typed_var_type [lindex $typed_var_spec 1]
        
            if [string match "" $typed_var_type] {
                # if they don't specify a type, the default is 'integer'
                set typed_var_type integer
            }

            set variable_safe_p [ad_var_type_check_${typed_var_type}_p $value]
        
            if !$variable_safe_p {
                ns_returnerror 500 "variable $name failed '$typed_var_type' type check"
                ns_log Error "[ad_conn url] called with \$$name = $value"
                error "variable $name failed '$typed_var_type' type check"
            }

            # we've found the first element in the list that matches,
            # and we don't want to check against any others
            break
        }
    }
}


proc set_form_variables {{error_if_not_found_p 1}} {
    if { $error_if_not_found_p == 1} {
	uplevel { if { [ns_getform] == "" } {
	    ns_returnerror 500 "Missing form data"
	    return
	}
       }
     } else {
	 uplevel { if { [ns_getform] == "" } {
	     # we're not supposed to barf at the user but we want to return
	     # from this subroutine anyway because otherwise we'd get an error
	     return
	 }
     }
  }

    # at this point we know that the form is legal
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set $Vname $Vvalue
	    incr Vform_counter_i
	}
    }
}

proc DoubleApos {string} {
    regsub -all ' "$string" '' result
    return $result
}

# if the user types "O'Malley" and you try to insert that into an SQL
# database, you will lose big time because the single quote is magic
# in SQL and the insert has to look like 'O''Malley'.  This function
# also trims white space off the ends of the user-typed data.

# if the form looked like
# <input type=text name=yow> and <input type=text name=bar> 
# then after you run this function you'll have Tcl vars 
# $QQfoo and $QQbar set to whatever the user typed in the form
# plus an extra single quote in front of the user's single quotes
# and maybe some missing white space

proc set_form_variables_string_trim_DoubleAposQQ {} {
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	if {$Vform == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set QQ$Vname [DoubleApos [string trim $Vvalue]]
	    incr Vform_counter_i
	}
    }
}

# this one does both the regular and the QQ

proc set_the_usual_form_variables {{error_if_not_found_p 1}} {
    if { [ns_getform] == "" } {
	if $error_if_not_found_p {
	    uplevel { 
		ns_returnerror 500 "Missing form data"
		return
	    }
	} else {
	    return
	}
    }

    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set QQ$Vname [DoubleApos [string trim $Vvalue]]
	    set $Vname $Vvalue
	    incr Vform_counter_i
	}
    }
}

proc set_form_variables_string_trim_DoubleApos {} {
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	if {$Vform == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set $Vname [DoubleApos [string trim $Vvalue]]
	    incr Vform_counter_i
	}
    }
}

proc set_form_variables_string_trim {} {
    # The variable names are prefixed with a V to avoid confusion with the form variables while checking for naughtiness.
    uplevel {
	set Vform [ns_getform] 
	if {$Vform == ""} {
	    ns_returnerror 500 "Missing form data"
	    return;
	}
	set Vform_size [ns_set size $Vform]
	set Vform_counter_i 0
	while {$Vform_counter_i<$Vform_size} {
	    set Vname [ns_set key $Vform $Vform_counter_i]
	    set Vvalue [ns_set value $Vform $Vform_counter_i]
	    check_for_form_variable_naughtiness $Vname $Vvalue
	    set $Vname [string trim $Vvalue]
	    incr Vform_counter_i
	}
    }
}

# debugging kludges

proc NsSettoTclString {set_id} {
    set result ""
    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	append result "[ns_set key $set_id $i] : [ns_set value $set_id $i]\n"
    }
    return $result
}

proc get_referrer {} {
    return [ns_set get [ad_conn headers] Referer]
}

proc post_args_to_query_string {} {
    set arg_form [ns_getform]
    if {$arg_form!=""} {
	set form_counter_i 0
	while {$form_counter_i<[ns_set size $arg_form]} {
	    append query_return "[ns_set key $arg_form $form_counter_i]=[ns_urlencode [ns_set value $arg_form $form_counter_i]]&"
	    incr form_counter_i
	}
	set query_return [string trim $query_return &]
    }
}    

proc get_referrer_and_query_string {} {
    if {[ad_conn method]!="GET"} {
	set query_return [post_args_to_query_string]
	return "[get_referrer]?${query_return}"
    } else {
	return [get_referrer]
    }
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
    if [catch {
	if { ![empty_string_p $bind] } {
	    	db_dml $statement_name $insert_dml -bind $bind
	} else {
	    db_dml $statement_name $insert_dml 
	}
    } errmsg] {
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
	</blockquote>"
	return
    }

    ad_returnredirect $return_url
    return
}

proc nmc_IllustraDatetoPrettyDate {sql_date} {

    regexp {(.*)-(.*)-(.*)$} $sql_date match year month day

    set allthemonths {January February March April May June July August September October November December}

    # we have to trim the leading zero because Tcl has such a 
    # brain damaged model of numbers and decided that "09-1"
    # was "8.0"

    set trimmed_month [string trimleft $month 0]
    set pretty_month [lindex $allthemonths [expr $trimmed_month - 1]]

    return "$pretty_month $day, $year"

}

proc_doc util_AnsiDatetoPrettyDate {sql_date} "Converts 1998-09-05 to September 5, 1998" {
    set sql_date [string range $sql_date 0 9]
    if ![regexp {(.*)-(.*)-(.*)$} $sql_date match year month day] {
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

proc remove_nulls_from_ns_set {old_set_id} {

    set new_set_id [ns_set new "no_nulls$old_set_id"]

    for {set i 0} {$i<[ns_set size $old_set_id]} {incr i} {
	if { [ns_set value $old_set_id $i] != "" } {

	    ns_set put $new_set_id [ns_set key $old_set_id $i] [ns_set value $old_set_id $i]

	}

    }

    return $new_set_id

}

proc merge_form_with_ns_set {form set_id} {

    for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
    }

    return $form

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

    ns_log Notice "statement_name = $statement_name"
    ns_log Notice "sql_qry = $sql_qry"
    ns_log Notice "set_id = $set_id"

    db_0or1row $statement_name $sql_qry -bind $bind -column_set set_id
    
    if { $set_id != "" } {
	
	for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
	    set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
	}
	
    }
    return $form    
}


proc util_prepare_update {table_name primary_key_name primary_key_value form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set column_list [db_columns $table_name]
    set bind_vars [ad_tcl_list_list_to_ns_set [list [list $primary_key_name $primary_key_value]]]

    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { ($form_var_name != $primary_key_name) && ([lsearch $column_list $form_var_name] != -1) } {

	    ad_tcl_list_list_to_ns_set -set_id $bind_vars [list [list $form_var_name $value]]
	    lappend the_sets "$form_var_name = :$form_var_name"

	}

	incr form_counter_i
    }

    return [list "update $table_name\nset [join $the_sets ",\n"] \n where $primary_key_name = :$primary_key_name" $bind_vars]
   
}

proc util_prepare_update_multi_key {table_name primary_key_name_list primary_key_value_list form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set bind_vars [ns_set create]

    while {$form_counter_i<$form_size} {

	set form_var_name [ns_set key $form $form_counter_i]
	set value [string trim [ns_set value $form $form_counter_i]]

	if { [lsearch -exact $primary_key_name_list $form_var_name] == -1 } {

	    # this is not one of the keys
	    ad_tcl_list_list_to_ns_set -set_id $bind_vars [list [list $form_var_name $value]]
	    lappend the_sets "$form_var_name = :$form_var_name"

	}

	incr form_counter_i
    }

    for {set i 0} {$i<[llength $primary_key_name_list]} {incr i} {

	set this_key_name [lindex $primary_key_name_list $i]
	set this_key_value [lindex $primary_key_value_list $i]

	ad_tcl_list_list_to_ns_set -set_id $bind_vars [list [list $this_key_name $this_key_value]]
	lappend key_eqns "$this_key_name = :$this_key_name"

    }

    return [list "update $table_name\nset [join $the_sets ",\n"] \n where [join $key_eqns " AND "]" $bind_vars]
}

proc util_prepare_insert {table_name form} {

    set form_size [ns_set size $form]
    set form_counter_i 0
    set bind_vars [ns_set create]

    while { $form_counter_i < $form_size } {

 	ns_set update $bind_vars [ns_set key $form $form_counter_i] [string trim [ns_set value $form $form_counter_i]]
 	incr form_counter_i

    }

    return [list "insert into $table_name\n([join [ad_ns_set_keys $bind_vars] ", "])\n values ([join [ad_ns_set_keys -colon $bind_vars] ", "])" $bind_vars]
}

proc util_PrettySex {m_or_f { default "default" }} {
    if { $m_or_f == "M" || $m_or_f == "m" } {
	return "Male"
    } elseif { $m_or_f == "F" || $m_or_f == "f" } {
	return "Female"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Unknown (\"$m_or_f\")"
	} else {
	    return $default
	}
    }
}

proc util_PrettySexManWoman {m_or_f { default "default"} } {
    if { $m_or_f == "M" || $m_or_f == "m" } {
	return "Man"
    } elseif { $m_or_f == "F" || $m_or_f == "f" } {
	return "Woman"
    } else {
	# Note that we can't compare default to the empty string as in 
	# many cases, we are going want the default to be the empty
	# string
	if { [string compare $default "default"] == 0 } {
	    return "Person of Unknown Sex"
	} else {
	    return $default
	}
    }
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
    if $zero_or_one {
	return "Yes"
    } else {
	return "No"
    }
}

proc randomInit {seed} {
    nsv_set rand ia 9301
    nsv_set rand ic 49297
    nsv_set rand im 233280
    nsv_set rand seed $seed
}

# initialize the random number generator

randomInit [ns_time]

proc random {} {
    nsv_set rand seed [expr ([nsv_get rand seed] * [nsv_get rand ia] + [nsv_get rand ic]) % [nsv_get rand im]]
    return [expr [nsv_get rand seed]/double([nsv_get rand im])]
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
	    append select_options "<option selected>$option\n"
	} else {
	    append select_options "<option>$option\n"
	}
    }
    return $select_options

}

ad_proc -public db_html_select_value_options {
    { -bind "" }
    { -select_option "" }
    { -value_index 0 }
    { -option_index 1 }
    stmt_name
    sql
} {

    Generate html option tags with values for an html selection widget. if
    select_option is passed and there exists a value for it in the values
    list, this option will be marked as selected. 

    @author yon [yon@arsdigita.com]

} {
    set select_options ""

    if { ![empty_string_p $bind] } {
	set options [db_list_of_lists $stmt_name $sql -bind $bind]
    } else {
	set options [uplevel [list db_list_of_lists $stmt_name $sql]]
    }

    foreach option $options {
	if { [string compare $select_option [lindex $option $value_index]] == 0 } {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\" selected>[lindex $option $option_index]\n"
	} else {
	    append select_options "<option value=\"[util_quote_double_quotes [lindex $option $value_index]]\">[lindex $option $option_index]\n"
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
    {-exclude {}}
    {-override {}}
    vars
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
    
    @param sign Sign all variables.

    @param url Export in URL format. This is the default.
    
    @param form Export in form format. You can't specify both URL and form format.

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

    foreach precedence_type { override exclude vars } {
	foreach var_spec [set $precedence_type] {
	    if { [llength $var_spec] > 2 } {
		return -code error "A varspec must have either one or two elements."
	    }
	    set name_spec [split [lindex $var_spec 0] ":"]
	    set name [lindex $name_spec 0]

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
			set exp_value($name) [uplevel subst \{[lindex $var_spec 1]\}]
		    } else {
			upvar 1 $name upvar_variable
			if { [info exists upvar_variable] } {
			    if { [array exists upvar_variable] } {
				set exp_value($name) [array get upvar_variable]
				set exp_flag($name:array) 1
			    } else {
				set exp_value($name) $upvar_variable
				if { [info exists exp_flag($name:array)] } {
				    return -code error "Variable \"$name\" is not an array"
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
	    append export_string "<input type=\"hidden\" name=\"[ad_quotehtml [ns_set key $export_set $i]]\" value=\"[ad_quotehtml "[ns_set value $export_set $i]"]\">\n"
	}
    }

    if { $quotehtml_p } {
	set export_string [ad_quotehtml $export_string]
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
	    lappend export_list "<input type=hidden name=\"[ad_quotehtml $varname]\"\
		    value=\"[ad_quotehtml $export($varname)]\">"
	}
	return [join $export_list \n]
    }
}





ad_proc export_form_vars { 
    -sign:boolean
    args 
} {
    Exports a number of variables as hidden input fields in a form.
    Specify a list of variable names. The proc will reach up in the caller's name space
    to grab the value of the variables. Variables that are not defined are silently ignored.
    You can append :multiple to the name of a variable. In this case, the value will be treated as a list,
    and each of the elements output separately.

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
			append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $var]\" value=\"[ad_quotehtml $item]\">\n"
		    }
		}
		default {
		    append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $var]\" value=\"[ad_quotehtml $value]\">\n"
		}
	    }
	    if { $sign_p } {
		append hidden "<input type=\"hidden\" name=\"[ad_quotehtml "$var:sig"]\" value=\"[ad_quotehtml [ad_sign $value]]\">\n"
	    }
	}
    }
    return $hidden
}

ad_proc export_entire_form {} {
    Exports everything in ns_getform to the ns_set.
    This should generally not be used. It's much better to explicitly
    name the variables you want to export.  
} {
    set hidden ""
    set the_form [ns_getform]
    if { ![empty_string_p $the_form] } {
	for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
	    set varname [ns_set key $the_form $i]
	    set varvalue [ns_set value $the_form $i]
	    append hidden "<input type=\"hidden\" name=\"[ad_quotehtml $varname]\" value=\"[ad_quotehtml $varvalue]\">\n"
	}
    }
    return $hidden
}

ad_proc export_ns_set_vars {{format "url"} {exclusion_list ""}  {setid ""}} {
    Returns all the params in an ns_set with the exception of those in
    exclusion_list. If no setid is provide, ns_getform is used. If format
    = url, a url parameter string will be returned. If format = form, a
    block of hidden form fragments will be returned.  
}  {

    if [empty_string_p $setid] {
	set setid [ns_getform]
    }

    set return_list [list]
    if ![empty_string_p $setid] {
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
        return "<input type=\"hidden\" [join $return_list ">\n <input type=\"hidden\" "] >"
    }
}

ad_proc export_url_vars {
    -sign:boolean
    args 
} {

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

ad_proc export_entire_form_as_url_vars { 
    {vars_to_passthrough ""}
} {
    Returns a URL parameter string of name-value pairs of all the form
    parameters passed to this page. If vars_to_passthrough is given, it
    should be a list of parameter names that will be the only ones passed
    through.
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




# Perform the dml statements in sql_list in a transaction.
# Aborts the transaction and returns an error message if
# an error occurred for any of the statements, otherwise
# returns null string. -jsc
proc do_dml_transactions {dml_stmt_list} {
    db_transaction {
	foreach dml_stmt $dml_stmt_list {
	    if { [catch {db_dml $dml_stmt} errmsg] } {
		db_abort_transaction
		return $errmsg
	    }
	}
    }
    return ""
}

# Perform body within a database transaction.
# Execute on_error if there was some error caught
# within body, with errmsg bound.
# This procedure will clobber errmsg in the caller.
# -jsc
proc with_transaction {body on_error} {
    upvar errmsg errmsg
    global errorInfo errorCode
    if { [catch {db_transaction { uplevel $body }} errmsg] } {
        db_abort_transaction
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

proc with_catch {error_var body on_error} { 
    upvar 1 $error_var $error_var 
    global errorInfo errorCode 
    if [catch { uplevel $body } $error_var] { 
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

proc_doc string_contains_p {small_string big_string} {Returns 1 if the BIG_STRING contains the SMALL_STRING, 0 otherwise; syntactic sugar for string first != -1} {
    if { [string first $small_string $big_string] == -1 } {
	return 0
    } else {
	return 1
    }
}

proc remove_whitespace {input_string} {
    if [regsub -all "\[\015\012\t \]" $input_string "" output_string] {
	return $output_string 
    } else {
	return $input_string
    }
}

proc util_just_the_digits {input_string} {
    if [regsub -all {[^0-9]} $input_string "" output_string] {
	return $output_string 
    } else {
	return $input_string
    }
}

# putting commas into numbers (thank you, Michael Bryzek)

proc_doc util_commify_number { num } {Returns the number with commas inserted where appropriate. Number can be positive or negative and can have a decimal point. e.g. -1465.98 => -1,465.98} {
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

proc leap_year_p {year} {
    expr ( $year % 4 == 0 ) && ( ( $year % 100 != 0 ) || ( $year % 400 == 0 ) )
}

proc_doc util_search_list_of_lists {list_of_lists query_string {sublist_element_pos 0}} "Returns position of sublist that contains QUERY_STRING at SUBLIST_ELEMENT_POS." {
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

proc_doc util_get_http_status {url {use_get_p 1} {timeout 30}} "Returns the HTTP status code, e.g., 200 for a normal response or 500 for an error, of a URL.  By default this uses the GET method instead of HEAD since not all servers will respond properly to a HEAD request even when the URL is perfectly valid.  Note that this means AOLserver may be sucking down a lot of bits that it doesn't need." { 
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

proc_doc util_link_responding_p {url {list_of_bad_codes "404"}} "Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay)." {
    if [catch { set status [util_get_http_status $url] } errmsg] {
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

proc_doc util_httpopen {method url {rqset ""} {timeout 30} {http_referer ""}} "Like ns_httpopen but works for POST as well; called by util_httppost" {
    
	if ![string match http://* $url] {
		return -code error "Invalid url \"$url\":  _httpopen only supports HTTP"
	}
	set url [split $url /]
	set hp [split [lindex $url 2] :]
	set host [lindex $hp 0]
	set port [lindex $hp 1]
	if [string match $port ""] {set port 80}
	set uri /[join [lrange $url 3 end] /]
	set fds [ns_sockopen -nonblock $host $port]
	set rfd [lindex $fds 0]
	set wfd [lindex $fds 1]
	if [catch {
		_ns_http_puts $timeout $wfd "$method $uri HTTP/1.0\r"
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

    } errMsg] {
		global errorInfo
		#close $wfd
		#close $rfd
		if [info exists rpset] {ns_set free $rpset}
		return -1
	}
	return [list $rfd $wfd ""]
    
}

# httppost; give it a URL and a string with formvars, and it 
# returns the page as a Tcl string
# formvars are the posted variables in the following form: 
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

proc_doc util_httppost {url formvars {timeout 30} {depth 0} {http_referer ""}} "Returns the result of POSTing to another Web server or -1 if there is an error or timeout.  formvars should be in the form \"arg1=value1&arg2=value2\"" {
    if [catch {
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
			if ![string length $line] break
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
	if [string match "" $length] {set length -1}
	set err [catch {
		while 1 {
			set buf [_ns_http_read $timeout $rfd $length]
			append page $buf
			if [string match "" $buf] break
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
    } errmgs ] {return -1}
	return $page
}

proc_doc util_report_successful_library_load {{extra_message ""}} "Should be called at end of private Tcl library files so that it is easy to see in the error log whether or not private Tcl library files contain errors." {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { [string compare $extra_message ""] == 0 } {
	set message "Done... $scrubbed_path"
    } else {
	set message "Done... $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

proc_doc exists_and_not_null { varname } {Returns 1 if the variable name exists in the caller's environment and is not the empty string.} {
    upvar 1 $varname var 
    return [expr { [info exists var] && ![empty_string_p $var] }] 
} 

proc_doc util_httpget {url {headers ""} {timeout 30} {depth 0}} "Just like ns_httpget, but first optional argument is an ns_set of headers to send during the fetch." {
    if {[incr depth] > 10} {
	return -code error "util_httpget:  Recursive redirection:  $url"
    }
    ns_log Notice "Getting {$url} {$headers} {$timeout} {$depth}"
    set http [ns_httpopen GET $url $headers $timeout]
    set rfd [lindex $http 0]
    close [lindex $http 1]
    set headers [lindex $http 2]
    set response [ns_set name $headers]
    set status [lindex $response 1]
    if {$status == 302} {
	set location [ns_set iget $headers location]
	if {$location != ""} {
	    ns_set free $headers
	    close $rfd
	    return [util_httpget $location {} $timeout $depth]
	}
    }
    set length [ns_set iget $headers content-length]
    if [string match "" $length] {set length -1}
    set err [catch {
	while 1 {
	    set buf [_ns_http_read $timeout $rfd $length]
	    append page $buf
	    if [string match "" $buf] break
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
    return $page
}

# some procs to make it easier to deal with CSV files (reading and writing)
# added by philg@mit.edu on October 30, 1999

proc_doc util_escape_quotes_for_csv {string} "Returns its argument with double quote replaced by backslash double quote" {
    regsub -all {"} $string {\"}  result
    return $result
}

proc_doc set_csv_variables_after_query {} {

    You can call this after an ns_db getrow or ns_db 1row to set local
    Tcl variables to values from the database.  You get $foo, $EQfoo
    (the same thing but with double quotes escaped), and $QEQQ
    (same thing as $EQfoo but with double quotes around the entire
    she-bang).

} {
    uplevel {
	    set set_variables_after_query_i 0
	    set set_variables_after_query_limit [ns_set size $selection]
	    while {$set_variables_after_query_i<$set_variables_after_query_limit} {
		set [ns_set key $selection $set_variables_after_query_i] [ns_set value $selection $set_variables_after_query_i]
		set EQ[ns_set key $selection $set_variables_after_query_i] [util_escape_quotes_for_csv [string trim [ns_set value $selection $set_variables_after_query_i]]]
		set QEQQ[ns_set key $selection $set_variables_after_query_i] "\"[util_escape_quotes_for_csv [string trim [ns_set value $selection $set_variables_after_query_i]]]\""
		incr set_variables_after_query_i
	    }
    }
}

#"

proc_doc ad_page_variables {variable_specs} {
<pre>
Current syntax:

    ad_page_variables {var_spec1 [varspec2] ... }

    This proc handles translating form inputs into Tcl variables, and checking
    to see that the correct set of inputs was supplied.  Note that this is mostly a
    check on the proper programming of a set of pages.

Here are the recognized var_specs:

    variable				; means it's required
    {variable default-value}
      Optional, with default value.  If the value is supplied but is null, and the
      default-value is present, that value is used.
    {variable -multiple-list}
      The value of the Tcl variable will be a list containing all of the
      values (in order) supplied for that form variable.  Particularly useful
      for collecting checkboxes or select multiples.
      Note that if required or optional variables are specified more than once, the
      first (leftmost) value is used, and the rest are ignored.
    {variable -array}
      This syntax supports the idiom of supplying multiple form variables of the
      same name but ending with a "_[0-9]", e.g., foo_1, foo_2.... Each value will be
      stored in the array variable variable with the index being whatever follows the
      underscore.

QQ variables are automatically created by ad_page_variables.

Other elements of the var_spec are ignored, so a documentation string
describing the variable can be supplied.

Note that the default value form will become the value form in a "set"

Note that the default values are filled in from left to right, and can depend on
values of variables to their left:
ad_page_variables {
    file
    {start 0}
    {end {[expr $start + 20]}}
}
</pre>
} {
    set exception_list [list]
    set form [ns_getform]
    if { $form != "" } {
	set form_size [ns_set size $form]
	set form_counter_i 0

	# first pass -- go through all the variables supplied in the form
	while {$form_counter_i<$form_size} {
	    set variable [ns_set key $form $form_counter_i]
	    set value [ns_set value $form $form_counter_i]
	    check_for_form_variable_naughtiness $variable $value
	    set found "not"
	    # find the matching variable spec, if any
	    foreach variable_spec $variable_specs {
		if { [llength $variable_spec] >= 2 } {
		    switch -- [lindex $variable_spec 1] {
			-multiple-list {
			    if { [lindex $variable_spec 0] == $variable } {
				# variable gets a list of all the values
				upvar 1 $variable var
				lappend var $value
				set found "done"
				break
			    }
			}
			-array {
			    set varname [lindex $variable_spec 0]
			    set pattern "($varname)_(.+)"
			    if { [regexp $pattern $variable match array index] } {
				if { ![empty_string_p $array] } {
				    upvar 1 $array arr
				    set arr($index) [ns_set value $form $form_counter_i]
				}
				set found "done"
				break
			    }
			}
			default {
			    if { [lindex $variable_spec 0] == $variable } {
				set found "set"
				break
			    }
			}
		    }
		} elseif { $variable_spec == $variable } {
		    set found "set"
		    break
		}
	    }
	    if { $found == "set" } {
		upvar 1 $variable var
		if { ![info exists var] } {
		    # take the leftmost value, if there are multiple ones
		    set var $value
		}
	    }
	    incr form_counter_i
	}
    }

    # now make a pass over each variable spec, making sure everything required is there
    # and doing defaulting for unsupplied things that aren't required
    foreach variable_spec $variable_specs {
	set variable [lindex $variable_spec 0]
	upvar 1 $variable var

	if { [llength $variable_spec] >= 2 } {
	    if { ![info exists var] } {
		set default_value_or_flag [lindex $variable_spec 1]
		
		switch -- $default_value_or_flag {
		    -array {
			# don't set anything
		    }
		    -multiple-list {
			set var [list]
		    }
		    default {
			# Needs to be set.
			uplevel [list eval set $variable "\[subst [list $default_value_or_flag]\]"]
			# This used to be:
			#
			#   uplevel [list eval [list set $variable "$default_value_or_flag"]]
			#
			# But it wasn't properly performing substitutions.
		    }
		}
	    }

	    # no longer needed because we QQ everything by default now
	    #	    # if there is a QQ or qq or any variant after the var_spec,
	    #	    # make a "QQ" variable
	    #	    if { [regexp {^[Qq][Qq]$} [lindex $variable_spec 2]] && [info exists var] } {
	    #		upvar QQ$variable QQvar
	    #		set QQvar [DoubleApos $var]
	    #	    }

	} else {
	    if { ![info exists var] } {
		lappend exception_list "\"$variable\" required but not supplied"
	    }
	}

        # modified by rhs@mit.edu on 1/31/2000
	# to QQ everything by default (but not arrays)
        if {[info exists var] && ![array exists var]} {
	    upvar QQ$variable QQvar
	    set QQvar [DoubleApos $var]
	}

    }

    set n_exceptions [llength $exception_list]
    # this is an error in the HTML form
    if { $n_exceptions == 1 } {
	ns_returnerror 500 [lindex $exception_list 0]
	return -code return
    } elseif { $n_exceptions > 1 } {
	ns_returnerror 500 "<li>[join $exception_list "\n<li>"]\n"
	return -code return
    }
}

proc_doc page_validation {args} {
    This proc allows page arg, etc. validation.  It accepts a bunch of
    code blocks.  Each one is executed, and any error signalled is
    appended to the list of exceptions.
    Note that you can customize the complaint page to match the design of your site,
    by changing the proc called to do the complaining:
    it's [ad_parameter ComplainProc "" ad_return_complaint]

    The division of labor between ad_page_variables and page_validation 
    is that ad_page_variables
    handles programming errors, and does simple defaulting, so that the rest of
    the Tcl code doesn't have to worry about testing [info exists ...] everywhere.
    page_validation checks for errors in user input.  For virtually all such tests,
    there is no distinction between "unsupplied" and "null string input".

    Note that errors are signalled using the Tcl "error" function.  This allows
    nesting of procs which do the validation tests.  In addition, validation
    functions can return useful values, such as trimmed or otherwise munged
    versions of the input.
} {
    if { [info exists {%%exception_list}] } {
	error "Something's wrong"
    }
    # have to put this in the caller's frame, so that sub_page_validation can see it
    # that's because the "uplevel" used to evaluate the code blocks hides this frame
    upvar {%%exception_list} {%%exception_list}
    set {%%exception_list} [list]
    foreach validation_block $args {
	if { [catch {uplevel $validation_block} errmsg] } {
	    lappend {%%exception_list} $errmsg
	}
    }
    set exception_list ${%%exception_list}
    unset {%%exception_list}
    set n_exceptions [llength $exception_list]
    if { $n_exceptions != 0 } {
	set complain_proc [ad_parameter ComplainProc "" ad_return_complaint]
	if { $n_exceptions == 1 } {
	    $complain_proc $n_exceptions [lindex $exception_list 0]
	} else {
	    $complain_proc $n_exceptions "<li>[join $exception_list "\n<li>"]\n"
	}
	return -code return
    }
}

proc_doc sub_page_validation {args} {
    Use this inside a page_validation block which needs to check more than one thing.
    Put this around each part that might signal an error.
} {
    # to allow this to be at any level, we search up the stack for {%%exception_list}
    set depth [info level]
    for {set level 1} {$level <= $depth} {incr level} {
	upvar $level {%%exception_list} {%%exception_list}
	if { [info exists {%%exception_list}] } {
	    break
	}
    }
    if { ![info exists {%%exception_list}] } {
	error "sub_page_validation not inside page_validation"
    }
    foreach validation_block $args {
	if { [catch {uplevel $validation_block} errmsg] } {
	    lappend {%%exception_list} $errmsg
	}
    }
}

proc_doc validate_integer {field_name string} {
    Throws an error if the string isn't a decimal integer; otherwise
    strips any leading zeros (so this won't work for octals) and returns
    the result.  
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

proc_doc validate_zip_code {field_name zip_string country_code} {

    Given a string, signals an error if it's not a legal zip code

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

proc_doc validate_ad_dateentrywidget {field_name column form {allow_null 0}} {
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

proc_doc util_WriteWithExtraOutputHeaders {headers_so_far {first_part_of_page ""}} "Takes in a string of headers to write to an HTTP connection, terminated by a newline.  Checks \[ad_conn outputheaders\] and adds those headers if appropriate.  Adds two newlines at the end and writes out to the connection.  May optionally be used to write the first part of the page as well (saves a packet)" {
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

# we use this when we want to send out just the headers 
# and then do incremental ns_writes.  This way the user
# doesn't have to wait like if you used a single ns_return

proc ReturnHeaders {{content_type text/html}} {
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
     util_WriteWithExtraOutputHeaders $all_the_headers
     ns_startcontent -type $content_type
}

# All the following ReturnHeaders versions are obsolete;
# just set [ad_conn outputheaders].

proc ReturnHeadersNoCache {{content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
pragma: no-cache\r\n"

     ns_startcontent -type $content_type
}

proc ReturnHeadersWithCookie {cookie_content {content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
Set-Cookie:  $cookie_content\r\n"

     ns_startcontent -type $content_type
}

proc ReturnHeadersWithCookieNoCache {cookie_content {content_type text/html}} {

    ns_write "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type
Set-Cookie:  $cookie_content
pragma: no-cache\r\n"

     ns_startcontent -type $content_type
}

proc_doc ad_return_top_of_page {first_part_of_page {content_type text/html}} "Returns HTTP headers plus the top of the user-ivisible page.  Saves a TCP packet (and therefore some overhead) compared to using ReturnHeaders and an ns_write." {
    set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
     util_WriteWithExtraOutputHeaders $all_the_headers

    ns_startcontent -type $content_type

    if ![empty_string_p $first_part_of_page] {
	ns_write $first_part_of_page
    }
}

proc_doc apply {func arglist} {
    Evaluates the first argument with ARGLIST as its arguments, in the
    environment of its caller. Analogous to the Lisp function of the same name.
} {
    set func_and_args [concat $func $arglist]
    return [uplevel $func_and_args]
}

proc_doc safe_eval args {
    Version of eval that checks its arguments for brackets that may be
used to execute unsafe code.
} {
    foreach arg $args {
	if { [regexp {[\[;]} $arg] } {
	    return -code error "Unsafe argument to safe_eval: $arg"
	}
    }
    return [apply uplevel $args]
}

proc_doc lmap {list proc_name} {Applies proc_name to each item of the list, appending the result of each call to a new list that is the return value.} {
    set lmap [list]
    foreach item $list {
	lappend lmap [safe_eval $proc_name $item]
    }
    return $lmap
}

proc_doc ad_decode { args } "this procedure is analogus to sql decode procedure. first parameter is the value we want to decode. this parameter is followed by a list of pairs where first element in the pair is convert from value and second element is convert to value. last value is default value, which will be returned in the case convert from values matches the given value to be decoded" {
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

proc_doc ad_urlencode { string } "same as ns_urlencode except that dash and underscore are left unencoded." {
    set encoded_string [ns_urlencode $string]
    regsub -all {%2d} $encoded_string {-} encoded_string
    regsub -all {%5f} $encoded_string {_} ad_encoded_string
    return $ad_encoded_string
}

ad_proc ad_get_cookie {
    { -include_set_cookies t }
    name { default "" }
} { "Returns the value of a cookie, or $default if none exists." } {
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
	return $value
    }

    return $default
}

ad_proc ad_set_cookie {
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
            append cookie "; Expires=Fri, 01-Jan-2035 01:00:00 GMT"
        }
    } elseif { $max_age != "" } {
	append cookie "; Max-Age=$max_age"
    }

    if { [string equal $expire "t"] } {
        append cookie "; Expires=Fri, 01-Jan-1980 01:00:00 GMT"
    }

    if { $domain != "" } {
	append cookie "; Domain=$domain"
    }

    if { $secure != "f" } {
	append cookie "; Secure"
    }

    ns_set put $headers "Set-Cookie" $cookie
}

proc_doc ad_run_scheduled_proc { proc_info } { Runs a scheduled procedure and updates monitoring information in the shared variables. } {
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

    if { $debug == "t" } {
	ns_log "Notice" "Running scheduled proc $proc..."
    }
    # Actually run the procedure.
    eval [concat [list $proc] $args]
    if { $debug == "t" } {
	ns_log "Notice" "Done running scheduled proc $proc."
    }
}

# Initialize NSVs for ad_schedule_proc.
if { [apm_first_time_loading_p] } {
    nsv_set ad_procs mutex [ns_mutex create]
    nsv_set ad_procs . ""
}

ad_proc ad_schedule_proc {
    {
	-thread f
	-once f
	-debug t
	-all_servers f
    }
    interval
    proc
    args
} { Replacement for ns_schedule_proc, allowing us to track what's going on. Can be monitored via /admin/monitoring/schedule-procs.tcl. The procedure defaults to run on only the canonical server unless the all_servers flag is set to true. } {
    # we don't schedule a proc to run if we have enabled server clustering,
    # we're not the canonical server, and the procedure was not requested to run on all servers.
    if { [server_cluster_enabled_p] && ![ad_canonical_server_p] && $all_servers == "f" } {
        return
    } 

    # Protect the list of scheduled procs with a mutex.
    ns_mutex lock [nsv_get ad_procs mutex]
    set proc_info [list $thread $once $interval $proc $args [ns_time] 0 $debug]
    ns_log "Notice" "Scheduling proc $proc"
    
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
    eval [concat [list ns_schedule_proc] $my_args [list $interval ad_run_scheduled_proc [list $proc_info]]]
}

proc util_ReturnMetaRefresh { url { seconds_delay 0 }} {
    ReturnHeaders
    ns_write "
    <head>
    <META HTTP-EQUIV=\"REFRESH\" CONTENT=\"$seconds_delay;URL=$url\">
    </head>
    <body>
    If your browser does not automatically redirect you, please go <a href=$url>here</a>.
    </body>"
}

# branimir 2000/04/25 ad_returnredirect and helper procs :
#    util_complete_url_p util_absolute_path_p util_current_location
#    util_current_directory   
# See: http://www.arsdigita.com/bboard/q-and-a-fetch-msg.tcl?msg_id=0003eV

ad_proc ad_returnredirect {{} target_url} {
  A replacement for ns_returnredirect.  It uses ns_returnredirect but is better in
  two important aspects:
  <ul>
     <li>When the supplied target_url isn't complete, (e.g. /foo/bar.tcl or foo.tcl)
         the prepended location part is constructed by looking at the HTTP 1.1 Host header.
     <li>If an URL relative to the current directory is supplied (e.g. foo.tcl)
         it prepends location and directory.
  </ul>
} {
  if {[util_complete_url_p $target_url]} {
      # http://myserver.com/foo/bar.tcl style - just pass to ns_returnredirect
      set url $target_url
  } elseif {[util_absolute_path_p $target_url]} {
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
  if {[string match *multipart/form-data* [string tolower $type]]} {
      set user_agent [ns_set get [ad_conn headers] User-Agent]
      set use_metarefresh_p [regexp -nocase "msie" $user_agent match]
  }
  if {$use_metarefresh_p != 0} {
      util_ReturnMetaRefresh $url 
  } else {
      ns_returnredirect $url
  }
}

ad_proc util_complete_url_p {{} string} {
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

ad_proc util_absolute_path_p {{} path} {
   Check whether the path begins with a slash
} {
   set firstchar [string index $path 0]
   if {[string compare $firstchar /]} {
        return 0
   } else {
        return 1
   }
}

ad_proc util_current_location {{}} {
   Like ad_conn location - Returns the location string of the current
   request in the form protocol://hostname[:port] but it looks at the
   Host header, that is, takes into account the host name the client
   used although it may be different from the host name from the server
   configuration file.  If the Host header is missing or empty util_current_location
   falls back to ad_conn location.
} {
   set host_from_header [ns_set iget [ad_conn headers] Host]
   # host_from_header now hopefully contains hostname[:port]
   set location_from_config_file [ad_conn location]
   if {[empty_string_p $host_from_header]} {
      # Hmm, there is no Host header.  This must be
      # an old browser such as MSIE 3.  All we can do is:
      return $location_from_config_file
   } else {
      # Replace the hostname[:port] part of $location_from_config_file with $host_from_header:
      regsub -nocase {(^[a-z]+://).*} \
                $location_from_config_file \\1$host_from_header location_from_host_header
      return $location_from_host_header
   }
}

ad_proc util_current_directory {{}} {
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

proc util_aolserver_2_p {} {
    if {[string index [ns_info version] 0] == "2"} {
	return 1
    } else {
	return 0
    }
}

proc_doc ad_chdir_and_exec { dir arg_list } { chdirs to $dir and executes the command in $arg_list. We'll probably want to improve this to be thread-safe. } {
    cd $dir
    eval exec $arg_list
}

proc_doc ad_call_proc_if_exists { proc args } {

Calls a procedure with particular arguments, only if the procedure is defined.

} {
    if { [llength [info procs $proc]] == 1 } {
	eval $proc $args
    }
}

ad_proc -public ad_get_tcl_call_stack { {level -2} } {
    Returns a stack trace from where the caller was called.

    @param level The level to start from, relative to this
    proc. Defaults to -2, meaning the proc that called this 
    proc's caller.

    @author Lars Pind (lars@pinds.com)
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


ad_proc util_unlist { list args } {

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

    return [regexp "^\[^@<>\"\t ]+@\[^@<>\".\t]+(\\.\[^@<>\".\n ]+)+$" $query_email]
}

ad_proc util_email_unique_p { email } {
    Returns 1 if the email passed in does not yet exist in the system.

    @author yon (yon@openforce.net)
} {
    return [db_string email_unique_p {}]
}

ad_proc util_url_valid_p { query_url } {
    Returns 1 if a URL is a web URL (HTTP or HTTPS).

    @author Philip Greenspun (philg@mit.edu)
} {
    return [regexp {https?://.+} $query_url]
}

ad_proc value_if_exists { var_name } {
    If the specified variable exists in the calling environment,
    returns the value of that variable. Otherwise, returns the
    empty_string.
} {
    upvar $var_name $var_name
    if [info exists $var_name] {
        return [set $var_name]
    }
}

ad_proc max { args } {
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

proc_doc -deprecated ad_check_for_naughty_html {user_submitted_html} {

This proc is deprecated. Please use <a
href="/api-doc/proc-view?proc=ad_html_security_check">ad_html_security_check</a>
instead.

<p>

Returns a human-readable explanation if the user has used any of the
HTML tags marked as naughty in the antispam section of ad.ini, otherwise
returns an empty string.

} {
    set tag_names [list div font]
    # look for a less than sign, zero or more spaces, then the tag
    if { ! [empty_string_p $tag_names]} { 
        if [regexp "< *([join $tag_names "\[ \n\t\r\f\]|"]\[ \n\t\r\f\])" [string tolower $user_submitted_html]] {
            return "<p>For security reasons we do not accept the submission of any HTML 
	    containing the following tags:</p> <code>[join $tag_names " "]</code>" 
        }
    }

    # HTML was okay as far as we know
    return ""
}

# usage: 
#   suppose the variable is called "expiration_date"
#   put "[ad_dateentrywidget expiration_date]" in your form
#     and it will expand into lots of weird generated var names
#   put ns_dbformvalue [ns_getform] expiration_date date expiration_date
#     and whatever the user typed will be set in $expiration_date

proc ad_dateentrywidget {column {default_date "1940-11-03"}} {
    ns_share NS

    set output "<SELECT name=$column.month>\n"
    for {set i 0} {$i < 12} {incr i} {
	append output "<OPTION> [lindex $NS(months) $i]\n"
    }

    append output \
"</SELECT>&nbsp;<INPUT NAME=$column.day\
TYPE=text SIZE=3 MAXLENGTH=2>&nbsp;<INPUT NAME=$column.year\
TYPE=text SIZE=5 MAXLENGTH=4>"

    return [ns_dbformvalueput $output $column date $default_date]
}

proc ad_dateentrywidget_default_to_today {column} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
    return [ad_dateentrywidget $column $today]
}

ad_proc -public util_ns_set_to_list {
    {-set:required}
} {
    Convert an ns_set into a TCL array.

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
