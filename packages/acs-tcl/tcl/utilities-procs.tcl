ad_library {

    Provides a variety of non-ACS-specific utilities, including
    the procs to support the who's online feature.

    @author Various (acs@arsdigita.com)
    @creation-date 13 April 2000
    @cvs-id $Id$
}

namespace eval util {}

ad_proc util::zip {
    -source:required
    -destination:required
} {
    Create a zip file.
    
    @param source is the content to be zipped. If it is a directory, archive will 
    contain all files into directory without the trailing directory itself.
    
    @param destination is the name of the created file
} {
    set zip [util::which zip]
    if {$zip eq ""} {
        error "zip command not found on the system."
    }
    set cmd [list exec]
    switch $::tcl_platform(platform) {
        windows {lappend cmd cmd.exe /c}
        default {lappend cmd bash -c}
    }
    if {[file isfile $source]} {
        set filename [file tail $source]
        set in_path  [file dirname $source]
    } else {
        set filename "."
        set in_path  $source
    }
    # To avoid having the full path of the file included in the archive,
    # we must first cd to the source directory. zip doesn't have an option
    # to do this without building a little script...
    set zip_cmd [list]
    lappend zip_cmd "cd $in_path"
    lappend zip_cmd "${zip} -r \"${destination}\" \"${filename}\""
    set zip_cmd [join $zip_cmd " && "]
    
    lappend cmd $zip_cmd
    
    # create the archive
    {*}$cmd
}

ad_proc util::unzip {
    -source:required
    -destination:required
    -overwrite:boolean
} { 
    @param source must be the name of a valid zip file to be decompressed
    
    @param destination must be the name of a valid directory to contain decompressed files
} {
    set unzip [util::which unzip]
    if {$unzip eq ""} {error "unzip command not found on the system."}
    # -n means we don't overwrite existing files
    set cmd [list exec $unzip]
    if {$overwrite_p} {lappend cmd -o
    } else {lappend cmd -n}
    lappend cmd $source -d $destination
    {*}$cmd
}

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

ad_proc util_report_library_entry {
    {extra_message ""}
} {
    Should be called at beginning of private Tcl library files so
    that it is easy to see in the error log whether or not 
    private Tcl library files contain errors.
} {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { $extra_message eq ""  } {
        set message "Loading $scrubbed_path"
    } else {
        set message "Loading $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

ad_proc check_for_form_variable_naughtiness { 
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
    Tcl system function "uplevel" that lets a subroutine bash
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
    if { "Vform_counter_i" eq $name } {
        error "Vform_counter_i not an allowed form variable"
    }

    # The statements below make ACS more secure, because it prevents
    # overwrite of variables from something like set_the_usual_form_variables
    # and it will be better if it was in the system. Yet, it is commented
    # out because it will cause an unstable release. To add this security
    # feature, we will need to go through all the code in the ACS and make
    # sure that the code doesn't try to overwrite intentionally and also
    # check to make sure that when Tcl files are sourced from another proc,
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
        if { $tmpdir_list eq "" } {
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
            
            if { "" eq $typed_var_type } {
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
    return [ns_set get [ns_conn headers] Referer]
}

##
#  Database-related code
##

ad_proc -deprecated ad_dbclick_check_dml { 
    {-bind  ""}
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
        if { $bind ne "" } {
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

ad_proc -public util_AnsiDatetoPrettyDate {
    sql_date
} { 
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
        set pretty_month [lindex $allthemonths $trimmed_month-1]

        set trimmed_day [string trimleft $day 0]

        return "$pretty_month $trimmed_day, $year"
    }
}

ad_proc -public remove_nulls_from_ns_set {
    old_set_id
} {
    Creates and returns a new ns_set without any null value fields

    @return new ns_set 
} {
    set new_set_id [ns_set new "no_nulls$old_set_id"]

    for {set i 0} {$i<[ns_set size $old_set_id]} {incr i} {
        if { [ns_set value $old_set_id $i] ne "" } {

            ns_set put $new_set_id [ns_set key $old_set_id $i] [ns_set value $old_set_id $i]

        }

    }

    return $new_set_id

}

ad_proc -public merge_form_with_query {
    {-bind {}}
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
    
    if { $set_id ne "" } {
        
        for {set i 0} {$i<[ns_set size $set_id]} {incr i} {
            set form [ns_formvalueput $form [ns_set key $set_id $i] [ns_set value $set_id $i]]
        }
        
    }
    return $form    
}




ad_proc -deprecated util_PrettyBoolean {t_or_f { default  "default" } } {
} {
    if { $t_or_f == "t" || $t_or_f eq "T" } {
        return "Yes"
    } elseif { $t_or_f == "f" || $t_or_f eq "F" } {
        return "No"
    } else {
        # Note that we can't compare default to the empty string as in 
        # many cases, we are going want the default to be the empty
        # string
        if { $default eq "default"  } {
            return "Unknown (\"$t_or_f\")"
        } else {
            return $default
        }
    }
}

ad_proc util_PrettyTclBoolean {
    zero_or_one
} {
    Turns a 1 (or anything else that makes a Tcl IF happy) into Yes; anything else into No
} {
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
    incr range
    return [expr {int([random] * $range) % $range}]
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

    if { $bind ne "" } {
        set options [db_list $stmt_name $sql -bind $bind]
    } else {
        set options [db_list $stmt_name $sql]
    }

    foreach option $options {
        if { $option eq $select_option  } {
            append select_options "<option selected=\"selected\">$option</option>\n"
        } else {
            append select_options "<option>$option</option>\n"
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
    list, this option will be marked as selected. select_option can be passed 
    a list, in which case all options matching a value in the list will be 
    marked as selected. 

    @author yon [yon@arsdigita.com]

} {
    set select_options ""

    if { $bind ne "" } {
        set options [db_list_of_lists $stmt_name $sql -bind $bind]
    } else {
        set options [uplevel [list db_list_of_lists $stmt_name $sql]]
    }

    foreach option $options {
        if { [lindex $option $value_index] in $select_option } {
            append select_options "<option value=\"[ns_quotehtml [lindex $option $value_index]]\" selected=\"selected\">[lindex $option $option_index]</option>\n"
        } else {
            append select_options "<option value=\"[ns_quotehtml [lindex $option $value_index]]\">[lindex $option $option_index]</option>\n"
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
    hidden HTML form fields. It does exactly the same as <code>[export_vars -form {foo bar baz}]</code>.

    <p>

    Example usage: <code>[export_vars -sign -override {{foo "new value"}} -exclude { bar } { foo bar baz }]</code>

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
    <p>
    For example, one can use now "user_id:sign(max_age=60)" in
    export_vars to let the exported variable after 60 seconds.
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

    #
    # TODO: At least the parsing of the options should be transformed
    # to produce a single dict, containing the properties of all form
    # vars (probably optionally) and specified arguments. The dict
    # should be the straightforeward source for the genertion of the
    # output set. One should be able to speed the code significantly
    # up (at least for the standard cases).
    #
    # -Gustaf Neumann
    #

    # 'noprocessing_vars' is yet another container of variables, 
    # only this one doesn't have the values subst'ed
    # and we don't try to find :multiple and :array flags in the namespec
    set noprocessing_vars [list]

    if { $entire_form_p } {
        set the_form [ns_getform]
        if { $the_form ne "" } {
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

            if { $precedence_type ne "noprocessing_vars" } {
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

                if { $precedence_type ne "exclude" } {

                    foreach flag [split [lindex $name_spec 1] ","] {
                        set exp_flag($name:$flag) 0
                        if {[regexp {^(\w+)[\(](.+)[\)]$} $flag . flag value]} {
                            set exp_flag($name:$flag) $value
                        }
                    }
                    
                    if { $sign_p } {
                        set exp_flag($name:sign) 0
                    }
                    
                    if { [llength $var_spec] > 1 } {
                        if { $precedence_type ne "noprocessing_vars" } {
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
                                        if { $value ne "" } {
                                            lappend exp_value($name) $key $value
                                        }
                                    }
                                } else {
                                    # If no_empty_p isn't set, just do an array get
                                    set exp_value($name) [array get upvar_variable]
                                }
                                set exp_flag($name:array) 0
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
                                            if { $elm ne "" } {
                                                lappend exp_value($name) $elm
                                            }
                                        }
                                    } else {
                                        # Simple value, this is easy
                                        if { $upvar_variable ne "" } {
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
        if { $exp_precedence_type($name) ne "exclude" } {
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

                        ns_set put $export_set "$name:sig" \
                            [export_vars_sign -params $exp_flag($name:sign) [lsort $exp_value($name)]]
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
                        ns_set put $export_set "$name:sig" \
                            [export_vars_sign -params $exp_flag($name:sign) $exp_value($name)]
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
            lappend export_list [ad_urlencode_query [ns_set key $export_set $i]]=[ad_urlencode_query [ns_set value $export_set $i]]
        }
        set export_string [join $export_list "&"]
    } else {
        for { set i 0 } { $i < $export_size } { incr i } {
            append export_string [subst {<div><input type="hidden"
                name="[ns_quotehtml [ns_set key $export_set $i]]"
                value="[ns_quotehtml [ns_set value $export_set $i]]"></div>
            }]
        }
    }

    if { $quotehtml_p } {
        set export_string [ns_quotehtml $export_string]
    }

    # Prepend with the base URL
    if { [info exists base] && $base ne "" } {
        if { $export_string ne "" } {
            if { [string first ? $base] > -1 } {
                # The base already has query vars
                set export_string "$base&$export_string"
            } else { 
                # The base has no query vars
                set export_string "$base?$export_string"
            }
        } else {
            set export_string $base
        }
    }
    
    # Append anchor
    if { [info exists anchor] && $anchor ne "" } {
        append export_string "\#$anchor"
    }
    
    return $export_string
}

ad_proc -private export_vars_sign {
    {-params ""}
    value
} {
    Call ad_sign parameterized via max_age and secret specified in urlencoding
} {
    set max_age ""
    set secret  [ns_config "ns/server/[ns_info server]/acs" parametersecret ""]
    foreach def [split $params &] {
        lassign [split $def =] key val
        switch $key {
            max_age -
            secret {set $key [ad_urldecode_query $val]}
        }
    }

    return [ad_sign -max_age $max_age -secret $secret $value]
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

    <blockquote><pre>doc_body_append [export_vars { msg_id user(email) { order_by date } }]</pre></blockquote>
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
    doc_body_append [export_vars -override { order_by $new_order_by } $my_vars]</pre></blockquote>

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
                if { $override_p || $arg ni $exclude } {
                    upvar $arg var
                    if { [array exists var] } {
                        # export the entire array
                        foreach name [array names var] {
                            if { $override_p || "${arg}($name)" ni $exclude } {
                                set export($arg.$name) $var($name)
                            }
                        }
                    } elseif { [info exists var] } {
                        if { $override_p || $arg ni $exclude } {
                            # if the var is part of an array, we'll translate the () into a dot.
                            set left_paren [string first "(" $arg]
                            if { $left_paren == -1 } {
                                set export($arg) $var
                            } else {
                                # convert the parenthesis into a dot before setting
                                set export([string range $arg 0 $left_paren-1].[string range $arg $left_paren+1 end-1]) $var
                            }
                        }
                    }
                }
            } elseif { [llength $arg] %2 == 0 } {
                foreach { name value } $arg {
                    if { $override_p || $name ni $exclude } {
                        set left_paren [string first "(" $name]
                        if { $left_paren == -1 } {
                            set export($name) [lindex [uplevel list \[subst [list $value]\]] 0]
                        } else {
                            # convert the parenthesis into a dot before setting
                            set export([string range $arg 0 $left_paren-1].[string range $arg $left_paren+1 end-1]) \
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
            lappend export_list "<input type=\"hidden\" name=\"[ns_quotehtml $varname]\"\
            value=\"[ns_quotehtml $export($varname)]\" >"
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

    Example usage: <code>[export_vars -form -sign {foo bar:multiple baz}]</code>

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
        lassign [split $var_spec ":"] var type
        upvar 1 $var value
        if { [info exists value] } {
            switch $type {
                multiple {
                    foreach item $value {
                        append hidden "<input type=\"hidden\" name=\"[ns_quotehtml $var]\" value=\"[ns_quotehtml $item]\" >\n"
                    }
                }
                default {
                    append hidden "<input type=\"hidden\" name=\"[ns_quotehtml $var]\" value=\"[ns_quotehtml $value]\" >\n"
                }
            }
            if { $sign_p } {
                append hidden "<input type=\"hidden\" name=\"[ns_quotehtml "$var:sig"]\" value=\"[ns_quotehtml [ad_sign $value]]\" >\n"
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
    if { $the_form ne "" } {
        for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
            set varname [ns_set key $the_form $i]
            set varvalue [ns_set value $the_form $i]
            append hidden "<input type=\"hidden\" name=\"[ns_quotehtml $varname]\" value=\"[ns_quotehtml $varvalue]\" >\n"
        }
    }
    return $hidden
}

ad_proc export_ns_set_vars {
    {format "url"} 
    {exclusion_list ""} 
    {setid ""}
} {
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

    if { $setid eq "" } {
        set setid [ns_getform]
    }

    set return_list [list]
    if { $setid ne "" } {
        set set_size [ns_set size $setid]
        set set_counter_i 0
        while { $set_counter_i < $set_size } {
            set name [ns_set key $setid $set_counter_i]
            set value [ns_set value $setid $set_counter_i]
            if {$name ni $exclusion_list && $name ne ""} {
                if {$format eq "url"} {
                    lappend return_list "[ad_urlencode_query $name]=[ad_urlencode_query $value]"
                } else {
                    lappend return_list " name=\"[ns_quotehtml $name]\" value=\"[ns_quotehtml $value]\""
                }
            }
            incr set_counter_i
        }
    }
    if {$format eq "url"} {
        return [join $return_list "&"]
    } else {
        return "<div><input type='hidden' [join $return_list " ></div>\n <div><input type='hidden' "] ></div>"
    }
}

ad_proc -deprecated export_url_vars {
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
            lassign [split $var_spec "="] var value
            lappend params "$var=$value"
            if { $sign_p } {
                lappend params "[ns_urlencode [ns_urldecode $var]:sig]=[ns_urlencode [ad_sign [ns_urldecode $value]]]"
            }
        } else {
            lassign [split $var_spec ":"] var type
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
    if { $the_form ne "" } {
        for {set i 0} {$i<[ns_set size $the_form]} {incr i} {
            set varname [ns_set key $the_form $i]
            set varvalue [ns_set value $the_form $i]
            if {
                $vars_to_passthrough eq "" 
                || ($varname in $vars_to_passthrough)
            } {
                lappend params "[ad_urlencode_query $varname]=[ad_urlencode_query $varvalue]" 
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
    if { $query ne "" } {
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
    if { [catch { uplevel $body } $error_var] } { 
        set code [catch {uplevel $on_error} string] 
        # Return out of the caller appropriately. 
        if { $code == 1 } { 
            return -code error -errorinfo $::errorInfo -errorcode $::errorCode $string 
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
        if { $query_string eq $comparison_element  } {
            return $sublist_index
        }
        incr sublist_index
    }
    # didn't find it
    return -1
}

ad_proc -public util_report_successful_library_load {
    {extra_message ""}
} {
    Should be called at end of private Tcl library files so that it is 
    easy to see in the error log whether or not private Tcl library 
    files contain errors.
} {
    set tentative_path [info script]
    regsub -all {/\./} $tentative_path {/} scrubbed_path
    if { $extra_message eq ""  } {
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
    return [expr { [info exists var] && $var ne "" }] 
} 

ad_proc -public -deprecated exists_or_null { varname } {
    Returns the contents of the variable if it exists, otherwise returns empty string
} {
    upvar 1 $varname var
    if {[info exists var]} {
        return $var
    }
    return ""
}

ad_proc -public exists_and_equal { varname value } {
    Returns 1 if the variable name exists in the caller's envirnoment
    and is equal to the given value.

    @see exists_and_not_null

    @author Peter Marklund    
} {
    upvar 1 $varname var
    
    return [expr { [info exists var] && $var eq $value } ]
}

ad_proc -deprecated -private set_encoding {
    {-text_translation {auto binary}}
    content_type
    channel
} {
    <p>The ad_http* and util_http* machineries depend on the
    AOLserver/NaviServer socket I/O layer provided by [ns_sockopen].
    This proc allows you to request Tcl encoding filtering for
    ns_sockopen channels (i.e., the read and write channels return by
                          [ns_sockopen]), to be applied right before performing socket I/O
    operations (i.e., reads).</p>

    <p>The major task is to resolve the corresponding Tcl encoding
    (e.g.: ascii) for a given IANA/MIME charset name (or alias; e.g.:
                                                      US-ASCII); the main resolution scheme is implemented by
    [ns_encodingfortype] which is available bother under AOLserver and
    NaviServer (see tcl/charsets.tcl). The mappings between Tcl encoding
    names (as shown by [encoding names]) and IANA/MIME charset names
    (i.e., names and aliases in the sense of <a
     href="http://www.iana.org/assignments/character-sets">IANA's
     charater sets registry</a>) is provided by:</p>
    
    <ul>
    <li>A static, built-in correspondence map: see nsd/encoding.c</li>
    <li>An extensible correspondence map (i.e., the ns/charsets
                                          section in config.tcl).</li>
    </ul>
    
    <p>[ns_encodingfortype] introduces several levels of precedence
    when resolving the actual IANA/MIME charset and the corresponding
    Tcl encoding to use:</p>
    
    <ol>
    <li> The "content_type" string contains a charset specification,
    e.g.: "text/xml; charset=UTF-8". This spec fragment takes the
    highest precedence.</li>
    
    <li> The "content_type" string points to a "text/*" media subtype,
    but does not specify a charset (e.g., "text/xml"). In this case, the
    charset defined by ns/parameters/OutputCharset (see config.tcl)
    applies. If this parameter is missing, the default is
    "iso-8859-1" (see tcl/charsets.tcl; this follows from <a
                  href="http://tools.ietf.org/html/rfc2616">RFC 2616 (HTTP 1.1)</a>;
                  Section 3.7.1).</li>
    
    <li>If neither case 1 or case 2 become effective, the encoding is
    resolved to "binary".</li>
    
    <li>If [ns_encodingfortype] fails to resolve any Tcl encoding name
    (i.e., returns an empty string), the general fallback is "iso8859-1"
    for text/* media subtypes and "binary" for any other. This is the
    case in two situations:
    
    <ul>
    <li>Invalid IANA/MIME charsets: The name in the "charset" parameter
    of the content type spec is not a valid name or alias in <a
    href="http://www.iana.org/assignments/character-sets">IANA's
    charater sets registry</a> (a special variant would be an empty
                                charset value, e.g. "text/plain; charset=")</li>
    
    <li>Unknown IANA/MIME charsets: The name in the "charset" parameter
    of the content type spec does not match any known (= registered)
    IANA/MIME charset in the MIME/Tcl mappings.</li>
    </ul>
    
    </li>
    </ol>

    References:
    <ul>
    <li><a href="http://www.mail-archive.com/aolserver@listserv.aol.com/msg07261.html">http://www.mail-archive.com/aolserver@listserv.aol.com/msg07261.html</a></li>
    <li><a href="http://sourceforge.net/tracker/?func=detail&atid=103152&aid=932459&group_id=3152">http://sourceforge.net/tracker/?func=detail&atid=103152&aid=932459&group_id=3152</a></li>
    <li><a href="http://sourceforge.net/tracker/index.php?func=detail&aid=962233&group_id=3152&atid=353152">http://sourceforge.net/tracker/index.php?func=detail&aid=962233&group_id=3152&atid=353152</a></li>
    </ul>
    
    @author stefan.sobernig@wu.ac.at
} {
    set trl [expr {[string match "text/*" $content_type] ? $text_translation : "binary"}]
    set enc [ns_encodingfortype $content_type]
    if {$enc eq ""} {
        set enc [expr {[string match "text/*" $content_type] ? "iso8859-1" : "binary"}]
        ns_log debug "--- Resolving a Tcl encoding for the CONTENT-TYPE '$content_type' failed; falling back to '$enc'."
    }
    fconfigure $channel -translation $trl -encoding $enc
}

# some procs to make it easier to deal with CSV files (reading and writing)
# added by philg@mit.edu on October 30, 1999

ad_proc util_escape_quotes_for_csv {string} {
    Returns its argument with double quote replaced by backslash double quote
} {
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
    if { $string eq "" } {
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
    if { $country_code eq "" || [string toupper $country_code] eq "US" } {
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
        if { $zip_string ne "" } {
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
    if { "$day$month$year" eq "" } {
        if { $allow_null == 0 } {
            error "$field_name must be supplied"
        } else {
            return ""
        }
    } elseif { $year ne "" && [string length $year] != 4 } {
        error "The year must contain 4 digits."
    } elseif { [catch  { ns_dbformvalue $form $column date date } errmsg ] } {
        error "The entry for $field_name had a problem:  $errmsg."
    }

    return $date
}

ad_proc -private util_WriteWithExtraOutputHeaders {
    headers_so_far 
    {first_part_of_page ""}
} {
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

ad_proc -private ReturnHeaders {
    {content_type text/html}
    {content_length ""}
} {
    We use this when we want to send out just the headers
    and then do incremental writes with ns_write.  This way the user
    doesn't have to wait for streamed output (useful when doing
                                              bulk uploads, installs, etc.).

    It returns status 200 and all headers including
    any added to outputheaders.
} {
    set text_p [string match "text/*" $content_type]
    if {$text_p && ![string match "*charset=*" $content_type]} {
        append content_type "; charset=[ns_config ns/parameters OutputCharset iso-8859-1]"
    }

    if {[ns_info name] eq "NaviServer"} {
        set binary [expr {$text_p ? "" : "-binary"}]
        ns_headers {*}$binary 200 $content_type {*}$content_length
    } else {
        set all_the_headers "HTTP/1.0 200 OK
MIME-Version: 1.0
Content-Type: $content_type\r\n"
        util_WriteWithExtraOutputHeaders $all_the_headers
        if {[string match "text/*" $content_type]} {
            ns_startcontent -type $content_type
        } else {
            ns_startcontent
        }
    }
}

ad_proc -public ad_return_top_of_page {
    first_part_of_page 
    {content_type text/html}
} { 
    Returns HTTP headers plus the top of the user-visible page.  
    To be used with streaming HTML output
} {
    ReturnHeaders $content_type
    if { $first_part_of_page ne "" } {
        ns_write $first_part_of_page
    }
}

ad_proc -public ad_apply {func arglist} {
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
        if { [string match {*[\[;]*} $arg] } {
            return -code error "Unsafe argument to safe_eval: $arg"
        }
    }
    return [ad_apply uplevel $args]
}

ad_proc -public -deprecated lmap {list proc_name} {
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

    while { $counter < $num_args - 2 } {
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

if {[ns_info name] eq "NaviServer"} {
    ad_proc -public ad_urlencode_path { string } {
        encode provided string with url-encoding for paths (instead of queries) as defined in RFC 3986
    } { 
        return [ns_urlencode -part path -- $string]
    }
    ad_proc -public ad_urldecode_path { string } {
        decode provided string with url-encoding for paths (instead of queries) as defined in RFC 3986
    } {
        return [ns_urldecode -part path -- $string]
    }
    ad_proc -public ad_urlencode_query { string } {
        encode provided string with url-encoding for query (instead of paths) as defined in RFC 3986
    } { 
        return [ns_urlencode -part query -- $string]
    }
    ad_proc -public ad_urldecode_query { string } {
        decode provided string with url-encoding for query (instead of paths) as defined in RFC 3986
    } {
        return [ns_urldecode -part query -- $string]
    }
} else {
    ad_proc -public ad_urlencode_path { string } {
        encode provided string with url-encodingfor paths; 
        same as ad_urlencode, since aolserver does not support this difference
    } {
        return [ad_urlencode $string]
    }
    ad_proc -public ad_urldecode_path { string } {
        decode provided string with url-encoding for paths; 
        same as ns_urldecode, since aolserver does not support this difference
    } {
        return [ns_urldecode $string]
    }
    ad_proc -public ad_urlencode_query { string } {
        encode provided string with url-encodingfor paths; 
        same as ad_urlencode, since aolserver does not support this difference
    } {
        return [ad_urlencode $string]
    }
    ad_proc -public ad_urldecode_query { string } {
        decode provided string with url-encoding for paths; 
        same as ns_urldecode, since aolserver does not support this difference
    } {
        return [ns_urldecode $string]
    }    
}



if {[ns_info name] eq "NaviServer"} {
    #
    # Use NaviServer primitives
    #
    ad_proc -public ad_unset_cookie {
        {-secure f}
        {-domain ""}
        {-path "/"}
        name
    } {
        Un-sets a cookie.
        
        @see ad_get_cookie
        @see ad_set_cookie
    } {
        ns_deletecookie -domain $domain -path $path -replace t -secure $secure -- $name
    }

    #
    # Get Cookie
    #
    ad_proc -public ad_get_cookie {
        { -include_set_cookies t }
        name 
        { default "" }
    } { 
        Returns the value of a cookie, or $default if none exists.

        @see ad_set_cookie
        @see ad_unset_cookie
    } {
        ns_getcookie -include_set_cookies $include_set_cookies -- $name $default
    }
    #
    # Set Cookie
    #
    ad_proc -public ad_set_cookie {
        {-replace f}
        {-secure f}
        {-expire f}
        {-max_age ""}
        {-domain ""}
        {-path "/"}
        {-discard f}
        {-scriptable t}    
        name 
        {value ""}
    } { 

        Sets a cookie.  Cookies are name/value pairs stored in a client's
        browser and are typically sent back to the server of origin with
        each request.

        @param max_age specifies the maximum age of the cookies in
        seconds (consistent with RFC 2109). max_age "inf" specifies cookies
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

        @param discard instructs the user agent to discard the
        cookie when when the user agent terminates.

        @param scriptable If the scriptable option is false or not
        given the cookie is unavailable to javascript on the
        client. This can prevent cross site scripting attacks (XSS) on
        clients which support the HttpOnly option. Set -scriptable to
        true if you need to access the cookie via javascript. For
        compatibility reasons with earlier versions, OpenACS 5.8 has
        the default set to "true". OpenACS 5.9 will have the flag per
        default set to "false".

        @param value is autmatically URL encoded.

        @see ad_get_cookie
        @see ad_unset_cookie    
    } {


        if { $expire == "f"} {
            set expire -1
        } elseif {$max_age ne ""} {
            if {$max_age eq "inf"} {
                set expire -1
            } else {
                set expire [expr {[ns_time] + $max_age}]
            }
        }

        ns_setcookie -discard $discard -domain $domain -expires $expire -path $path \
            -replace $replace -scriptable $scriptable -secure $secure -- \
            $name $value
    }
    
} else {
    #
    # Use plain AOLserver
    #

    #
    # Unset Cookie
    #
    ad_proc -public ad_unset_cookie {
        {-secure f}
        {-domain ""}
        {-path "/"}
        name
    } {
        Un-sets a cookie.
        
        @see ad_get_cookie
        @see ad_set_cookie
    } {
        ad_set_cookie -replace t -expire t -max_age 0 \
            -secure $secure -domain $domain -path $path \
            $name ""
    }

    #
    # Get Cookie
    #
    ad_proc -public ad_get_cookie {
        { -include_set_cookies t }
        name 
        { default "" }
    } { 
        Returns the value of a cookie, or $default if none exists.

        @see ad_set_cookie
        @see ad_unset_cookie
    } {

        if { $include_set_cookies == "t" } {
            set headers [ns_conn outputheaders]
            set nr_headers [ns_set size $headers]
            for { set i 0 } { $i < $nr_headers } { incr i } {
                if { [string tolower [ns_set key $headers $i]] eq "set-cookie" 
                     && [regexp "^$name=(\[^;\]*)" [ns_set value $headers $i] match value] 
                 } {
                    return $value
                }
            }
        }

        set headers [ns_conn headers]
        set cookie [ns_set iget $headers Cookie]

        if { [regexp " $name=(\[^;\]*)" " $cookie" match value] } {

            # If the cookie was set to a blank value we actually stored two quotes.  We need
            # to undo the kludge on the way out.

            if { $value eq "\"\"" } {
                set value ""
            }
            return $value
        }

        return $default
    }

    #
    # Set Cookie
    #
    ad_proc -public ad_set_cookie {
        {-replace f}
        {-secure f}
        {-expire f}
        {-max_age ""}
        {-domain ""}
        {-path "/"}
        {-discard f}
        {-scriptable t}    
        name 
        {value ""}
    } { 

        Sets a cookie.  Cookies are name/value pairs stored in a client's
        browser and are typically sent back to the server of origin with
        each request.

        @param max_age specifies the maximum age of the cookies in
        seconds (consistent with RFC 2109). max_age "inf" specifies cookies
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

        @param discard instructs the user agent to discard the
        cookie when when the user agent terminates.

        @param scriptable If the scriptable option is false or not
        given the cookie is unavailable to javascript on the
        client. This can prevent cross site scripting attacks (XSS) on
        clients which support the HttpOnly option. Set -scriptable to
        true if you need to access the cookie via javascript. For
        compatibility reasons with earlier versions, OpenACS 5.8 has
        the default set to "true". OpenACS 5.9 will have the flag per
        default set to "false".

        @param value is autmatically URL encoded.

        @see ad_get_cookie
        @see ad_unset_cookie    
    } {
        set headers [ad_conn outputheaders]
        if { $replace } {
            # Try to find an already-set cookie named $name.
            for { set i 0 } { $i < [ns_set size $headers] } { incr i } {
                if { [string tolower [ns_set key $headers $i]] eq "set-cookie" 
                     && [string match "$name=*" [ns_set value $headers $i]] 
                 } {
                    ns_set delete $headers $i
                }
            }
        }

        # need to set some value, so we put "" as the cookie value
        if { $value eq "" } {
            set cookie "$name=\"\""
        } else {
            set cookie "$name=$value"
        }

        if { $path ne "" } {
            append cookie "; Path=$path"
        }

        if { $discard != "f" } {
            append cookie "; Discard"
        } elseif { $max_age eq "inf" } {
            if { $expire == "f"} {
                #
                # netscape seemed unhappy with huge max-age, so we use
                # expires which seems to work on both netscape and IE
                #
                append cookie "; Expires=Mon, 01-Jan-2035 01:00:00 GMT"
            }
        } elseif { $max_age ne "" } {
            #
            # We know $max_age is also not "inf"
            #
            append cookie "; Max-Age=$max_age"
            if {$expire == "f"} {
                # Reinforce Max-Age via "Expires", unless user required
                # immediate expiration
                set expire_time [util::cookietime [expr {[ns_time] + $max_age}]]
                append cookie "; Expires=$expire_time"
            }
        }

        if {$expire != "f"} {
            append cookie "; Expires=Tue, 01-Jan-1980 01:00:00 GMT"
        }

        if { $domain ne "" } {
            append cookie "; Domain=$domain"
        }

        if { $secure == "t" } {
            append cookie "; Secure"
        }

        if { $scriptable == "f" } {
            # Prevent access to this cookie via JavaScript
            append cookie "; HttpOnly"
        }

        ns_log Debug "OACS Set-Cookie: $cookie"
        ns_set put $headers "Set-Cookie" $cookie
    }


}





ad_proc -private ad_run_scheduled_proc { proc_info } { 
    Runs a scheduled procedure and updates monitoring information in the shared variables. 
} {
    if {[ns_info name] eq "NaviServer"} {
        set proc_info [lindex $proc_info 0]
    }

    # Grab information about the scheduled procedure.
    lassign $proc_info thread once interval proc args time . debug
    set count 0

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
    if {$proc ne ""} {$proc {*}$args}

    ns_log debug "Done running scheduled proc $proc."
}

# Initialize NSVs for ad_schedule_proc.
if { [apm_first_time_loading_p] } {
    nsv_set ad_procs mutex [ns_mutex create oacs:sched_procs]
    nsv_set ad_procs . ""
}

ad_proc -public ad_schedule_proc {
    {-thread f}
    {-once f}
    {-debug f}
    {-all_servers f}
    {-schedule_proc ""}
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

    if { $schedule_proc eq "" } {
        ns_schedule_proc {*}$my_args {*}$interval ad_run_scheduled_proc [list $proc_info]
    } else {
        $schedule_proc {*}$my_args {*}$interval ad_run_scheduled_proc [list $proc_info]
    }
}

ad_proc -deprecated util_ReturnMetaRefresh { 
    url 
    { seconds_delay 0 } 
} {
    Ugly workaround to deal with IE5.0 bug handling
    multipart/form-data using                                                                                  
    Meta Refresh page instead of a redirect.                                                                                                                   
    
} {
    ad_return_top_of_page [subst {
        <head>
        <meta http-equiv="refresh" content="$seconds_delay;URL=[ns_quotehtml $url]">
        <script type="text/javascript">
        window.location.href = "[ns_quotehtml $url]";
        </script>
        </head>
        <body>
        <h2>Loading...</h2>
        If your browser does not automatically redirect you, <a href="[ns_quotethml $url]">please click here</a>.
        </body>}]
}

# Brad Duell (bduell@ncacasi.org) 07/10/2003
# User session variables, then redirect
ad_proc -public ad_cache_returnredirect { 
    url 
    { persistent "f" } 
    { excluded_vars "" } 
} {
    An addition to ad_returnredirect.  It caches all variables in the redirect except those in excluded_vars
    and then calls ad_returnredirect with the resultant string.

    @author Brad Duell (bduell@ncacasi.org)

} {
    util_memoize_flush_regexp [list [ad_conn session_id] [ad_conn package_id]]

    lassign [split $url "?"] url vars

    set excluded_vars_list ""
    set excluded_vars_url ""
    for { set i 0 } { $i < [llength $excluded_vars] } { incr i } {

        lassign [lindex $excluded_vars $i] item value

        if { $value eq "" } {
            set level [template::adp_level]
            # Obtain value from adp level
            upvar #$level \
                __item item_reference \
                __value value_reference 
            set item_reference $item
            uplevel #$level {set __value [set $__item]}
            set value $value_reference
        }
        lappend excluded_vars_list $item
        if { $value ne "" } {
            # Value provided
            if { $excluded_vars_url ne "" } {
                append excluded_vars_url "&"
            }
            append excluded_vars_url [export_vars -url [list [list "$item" "$value"]]]
        }
    }

    set saved_list ""
    if { $vars ne "" } {
        foreach item_value [split $vars "&"] {
            lassign [split $item_value "="] item value
            if {$item ni $excluded_vars_list} {
                # No need to save the value if it's being passed ...
                if {$item in $saved_list} {
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
    {-allow_complete_url:boolean}
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
    @param allow_complete_url By default we disallow redirecting to urls outside the current host. This is based on the currently set host header or the host name in the config file if there is no host header. Set allow_complete_url if you are redirecting to a known safe external web site. This prevents redirecting to a site by URL query hacking.
    
    @see util_user_message
    @see ad_script_abort
} {
    if {$message ne ""} {
        #
        # Leave a hint, that we do not want to be consumed on the
        # current page.
        #
        set ::__skip_util_get_user_messages 1
        if { [string is false $html_p] } {
            util_user_message -message $message
        } else {
            util_user_message -message $message -html
        }
    }

    if { [util_complete_url_p $target_url] } {
        # http://myserver.com/foo/bar.tcl style - just pass to ns_returnredirect
        # check if the hostname matches the current host
        if {[util::external_url_p $target_url] && !$allow_complete_url_p} {
            error "Redirection to external hosts is not allowed."
        }
        set url $target_url
    } elseif { [util_absolute_path_p $target_url] } {
        # /foo/bar.tcl style - prepend the current location:
        set url [util_current_location]$target_url
    } else {
        # URL is relative to current directory.
        if {$target_url eq "."} {
            set url [util_current_location][util_current_directory]
        } else {
            set url [util_current_location][util_current_directory]$target_url
        }
    }

    # Sanitize URL to avoid potential injection attack
    regsub -all {[\r\n]} $url "" url

    ns_returnredirect $url    
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
    if { $message ne "" } {
        if { [string is false $html_p] } {
            set message [ns_quotehtml $message]
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

    #
    # If there is a hint on the current page, that we do not want the
    # content to be consumed (e.g. a redirect) the force keep_p.
    #
    if {[info exists ::__skip_util_get_user_messages]} {
        set keep_p 1
    }
    if { !$keep_p && $messages ne "" } {
        ad_set_client_property "acs-kernel" "general_messages" {}
    }
    template::multirow create $multirow message
    foreach message $messages {
        template::multirow append $multirow $message
    }
}

ad_proc -public util_complete_url_p {string} {
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

ad_proc -public util_absolute_path_p {path} {
    Check whether the path begins with a slash
} {
    set firstchar [string index $path 0]
    if {$firstchar ne "/" } {
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

    if {$driver eq ""} {
        set driver [ad_conn driver]
    }

    set section [ns_driversection -driver $driver]

    switch -glob -- $driver {
        nsudp* -
        nssock* {
            set result(proto) http
            set result(port) [ns_config -int $section Port]
        }
        nsunix {
            set result(proto) http
            set result(port) {}
        }
        nsssl* - nsssle {
            set result(port) [ns_config -int $section Port]
            set result(proto) https
        }
        nsopenssl {
            set result(port) [ns_config -int $section ServerPort]
            set result(proto) https
        }
        default {
            ns_log Error "Unknown driver: [ad_conn driver]. Only know nssock, nsunix, nsssl, nsssle, nsopenssl"
            set result(port) [ns_config -int $section Port]
            set result(proto) http
        }
    }
}

ad_proc util::split_location {location protoVar hostnameVar portVar} {
    Split the provided location into "protocol", "hostname" and
    "port".  The results are returned to the provided output
    variables.  The function supports IP-literal notation according to
    RFC 3986 section 3.2.2.
    
    @author Gustaf Neumann
    @return boolean value indicating success
} {
    upvar $protoVar proto $hostnameVar hostname $portVar port
    
    if {
        [regexp {^([a-z]+://)?([^:]+)(:[0-9]*)?$} $location . proto hostname port]
        || [regexp {^([a-z]+://)?(\[[^\]]+\])(:[0-9]*)?$} $location . proto hostname port]
    } {
        if {$proto ne ""} {
            lassign [split $proto :] proto .
        }
        if {$port eq "" && $proto ne ""} {
            set default_port(http) 80
            set default_port(https) 443
            set port $default_port($proto)
        } else {
            # In case there is no proto, the port is set to ""
            set port [string range $port 1 end]
        }
        set success 1
    } else {
        set success 0
    }
    return $success 
}

ad_proc -public util_current_location {} {
    Like ad_conn location - Returns the location string of the current
    request in the form protocol://hostname[:port] but it looks at the
    "Host:" header, that is, takes into account the host name the client
    used although it may be different from the host name from the server
    configuration file.  If the Host header is missing or empty 
    util_current_location falls back to ad_conn location.
} {

    #
    # Compute util_current_location only once per request and cache
    # the result per thread.
    #
    if {[info exists ::__util_current_location]} {
        return $::__util_current_location
    }
    
    set default_port(http) 80
    set default_port(https) 443
    #
    # The package parameter "SuppressHttpPort" might be set when the
    # server is behind a proxy to hide the internal port.
    #
    set suppress_port [parameter::get \
                           -package_id [apm_package_id_from_key acs-tcl] \
                           -parameter SuppressHttpPort \
                           -default 0]
    #
    # Obtain the information from ns_conn based on the actual driver
    # handling the current request.  The obtained variables "proto",
    # "hostname" and "port" will be the default and might be
    # overwritten by more specific information.
    #
    if {![util::split_location [ns_conn location] proto hostname port]} {
        ns_log Error "util_current_location got invalid information from driver '[ns_conn location]'"
        # provide fallback info
        set hostname [ns_info hostname]
        set proto ""
    }
    if {$proto eq ""} {
        set proto http
        set port  $default_port($proto)
    }

    set headers [ns_conn headers]
    if { [ns_config "ns/parameters" ReverseProxyMode false]
         && [ns_set ifind $headers X-Forwarded-For] > -1} {
        #
        # We are running behind a proxy
        #
        if {[ns_set iget $headers X-SSL-Request] == 1} {
            #
            # We know, the request was an https request
            #
            set proto https
        }
        #
        # reset to the default port
        #
        set port $default_port($proto)
    }
    
    #
    # If we want to allow developers to access the backend server
    # directly (not via the proxy), the clause above does not fire,
    # although "ReverseProxyMode" was set, since there is no
    # "X-Forwarded-For".  The usage of "SuppressHttpPort" would not
    # allow this use case.
    #
    
    #
    # In case the "Host:" header field was provided, use the "hostame"
    # and maybe the "port" from there (this has the highest priority)
    #
    set Host [ns_set iget $headers Host]
    if {$Host ne ""} {
        if {[util::split_location $Host .proto hostname Host_port]} {
            if {$Host_port ne ""} {
                set port $Host_port
            }
        }
    }
    
    #
    # We have all information, return the data...
    #
    if {$suppress_port || $port eq $default_port($proto) || $port eq ""} {
        set result ${proto}://${hostname}
    } else {
        set result ${proto}://${hostname}:${port}
    }

    set ::__util_current_location $result
    #ns_log notice "util_current_location returns <$result>"
    return $result
}

ad_proc -public util_current_directory {} {
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

    set lastchar [string range $path end end]
    if {$lastchar eq "/" } {
        return $path
    } else { 
        set file_dirname [file dirname $path]
        # Treat the case of the root directory special
        if {$file_dirname eq "/" } {
            return /
        } else {
            return $file_dirname/
        }
    }
}


ad_proc -public ad_call_proc_if_exists { proc args } {
    Calls a procedure with particular arguments, only if the procedure is defined.
} {
    if { [info commands $proc] ne "" } {
        $proc {*}$args
    }
}

ad_proc -public ad_get_tcl_call_stack { 
    {level -2} 
} {
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
    for { set x [expr {[info level] + $level}] } { $x > 0 } { incr x -1 } {
        set info [info level $x]
        regsub -all \n $info {\\n} info
        if {[string length $info]>200} {
            set arglist ""
            foreach arg $info {
                if {[string length $arg]>40} {set arg [string range $arg 0 40]...}
                lappend arglist $arg
            }
            set info $arglist
        }
        append stack "    called from $info\n"
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
    if { $duplicates ni {ignore fail overwrite} } {
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
    Takes a Tcl list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    @param set_id If this switch is specified, it'll use this set instead of 
    creating a new one.
    
    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead 
    of <code>ns_set update</code> (update is default)

    @param args A Tcl list of variable names that will be transported into the ns_set.

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
        if { [lindex $sorted_list1 $index1] ne [lindex $sorted_list2 $index1] } {
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
        if { [llength $sorted_list1] == 0 || [lindex $sorted_list1 end] ne $elm } {
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
        if {$key ni $exclude} {
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
    set line_number 0
    foreach item $items {
        regsub -all {<[^>]+>} $item "" item_notags
        if { $line_length > $indent } {
            if { $line_length + 1 + [string length $item_notags] > $length } {
                append out "$eol\n"
                incr line_number
                for { set i 0 } { $i < $indent } { incr i } {
                    append out " "
                }
                set line_length $indent
            } else {
                append out " "
                incr line_length
            }
        } elseif {$line_number == 0} {
            append out " "
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
    if { $text eq "" } {
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
    if { $text eq "" } {
        error "Cannot compute a URL of this string: \"$original_text\" because after removing all illegal characters it's an empty string."
    }

    # check if the resulting url is already present
    if {$text in $existing_urls} {
        
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
                    if { $n >= $number } { set number [expr {$n + 1}] }
                }
            }
            
            set text "$text$replacement$number"
        }
    }

    return $text

}

ad_proc -public -deprecated util_unlist { list args } {

    Places the <i>n</i>th element of <code>list</code> into the variable named by
    the <i>n</i>th element of <code>args</code>.

    One should use the built-in Tcl command "lassign" instread of this proc.

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
        if { [lindex $sorted_list1 $index1] ne [lindex $sorted_list2 $index1] } {
            return 0
        }
    }

    return 1    
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

            if { $current_node eq "" } {
                # Try the next path
                break
            }
        }
        if { $current_node ne "" } {
            set result [xml_node_get_content $current_node]
            if { $result ne "" } {
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
        if { $current_node eq "" } {
            # Try the next path
            break
        }
    }

    if { $current_node ne "" } {
        set attribute [xml_node_get_attribute $current_node $attribute_name ""]
    }

    return $attribute

}


ad_proc -public ad_generate_random_string {
    {length 8}
} {
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

    # Execute CODE.
    set return_code [catch {uplevel $code} string]

    if {[info exists ::errorInfo]} {
        set s_errorInfo $::errorInfo
    } else {
        set s_errorInfo ""
    }
    if {[info exists ::errorCode]} {
        set s_errorCode $::errorCode
    } else {
        set s_errorCode ""
    }

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
            if {[lindex $s_errorCode 0 0] eq "CHILDSTATUS"} {
                #
                # GN: In case the errorCode starts with CHILDSTATUS it
                # means that an error was raised from an "exec". In
                # that case the raw error just tells that the "child
                # process exited abnormally", whithout given any
                # details. Therefore we add the exit code to the
                # messages.
                #
                set extra "child process (pid [lindex $s_errorCode 0 1]) exited with exit-code [lindex $s_errorCode 0 end]"
                append string " ($extra)"
                set s_errorInfo $extra\n$s_errorInfo 
            }
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
            set errinfo \$::errorInfo
            set errcode \$::errorCode
        }

        if { \$errno == 1 } {
            \# This is an error
            ns_log Error \"util_background_exec: Error in thread named '$name': \$::errorInfo\"
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
    if { $form eq "" } { return filter_ok }

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
            [regexp -nocase {[^a-z_]or[^a-z0-9_]} $value] 
            || [regexp -nocase {union([^a-z0-9_].*all)?[^a-z0-9_].*select} $value]
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
                $parse_result_integer == 0 
                || $parse_result_integer == -904
                || $parse_result_integer == -1789 
                || $parse_result_string == 0 
                || $parse_result_string == -904 
                || $parse_result_string == -1789
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

    lappend ad_typed_form_variables {*}[lindex $args 0]

    return filter_ok
}

#
# All the ad_var_type_check* procs get called from 
# check_for_form_variable_naughtiness. Read the documentation
# for ad_set_typed_form_variable_filter for more details.

ad_proc ad_var_type_check_integer_p {value} {
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

ad_proc ad_var_type_check_safefilename_p {value} {
    <pre>
    #
    # return 0 if the file contains ".."
    #
    <pre>
} {

    if { [string match "*..*" $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc ad_var_type_check_dirname_p {value} {
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

ad_proc ad_var_type_check_number_p {value} {
    <pre>
    #
    # return 1 if $value is a valid number
    #
    <pre>
} {
    if { [catch {expr {1.0 * $value}}] } {
        return 0
    } else {
        return 1
    }
}

ad_proc ad_var_type_check_word_p {value} {
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

ad_proc ad_var_type_check_nocheck_p {{value ""}} {
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

ad_proc ad_var_type_check_noquote_p {value} {
    <pre>
    #
    # return 1 if $value contains any single-quotes
    #
    <pre>
} {

    if { [string match "*'*" $value] } {
        return 0
    } else {
        return 1
    }
}

ad_proc ad_var_type_check_integerlist_p {value} {
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

ad_proc ad_var_type_check_fail_p {value} {
    <pre>
    #
    # A check that always returns 0. Useful if you want to disable all access
    # to a page.
    #
    <pre>
} {
    return 0
}

ad_proc ad_var_type_check_third_urlv_integer_p {{args ""}} {
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

ad_proc util::name_to_path {
    -name:required
} {
    Transforms a pretty name to a reasonable path name.
} {
    regsub -all -nocase { } [string trim [string tolower $name]] {-} name
    regsub -all {[^[:alnum:]\-]} $name {} name
    return $name
}

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
    while {1} {
        if { $backup_counter == 1 } {
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

    #exec "mv" "$file_path" "$backup_path"
    file rename $file_path $backup_path
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
        if { [llength $val] > 1 && [llength $val] % 2 == 0  } {
            append output [string repeat " " $indent] "$elm \{" \n

            append output [util::array_list_spec_pretty $val [expr {$indent + 4}]]

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
        set hrs [expr {$seconds / (60*60)}]
        set mins [expr {($seconds / 60) % 60}]
        set secs [expr {$seconds % 60}]
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
        set index [randomRange [expr {[llength $list] - 1}]]
        lappend result [lindex $list $index]
        set list [lreplace $list $index $index]
    }
    return $result
}

ad_proc -public util::random_list_element {
    list
} {
    Returns a random element from the list.
} {
    set len [llength $list]
    set idx [expr {int(rand() * $len)}]
    return [lindex $list $idx]
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
    set age_seconds [expr {[clock scan $sysdate_ansi] - [clock scan $timestamp_ansi]}]

    if { $age_seconds < 30 } {
        # Handle with normal processing below -- otherwise this would require another string to localize
        set age_seconds 60
    }

    if { $age_seconds < $hours_limit * 60 * 60 } {
        set hours [expr {abs($age_seconds / 3600)}]
        set minutes [expr {round(($age_seconds% 3600)/60.0)}]
        if {$hours < 24} {
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
            set days [expr {abs($hours / 24)}]
            switch $days {
                1 { set result "One day " }
                default { set result "$days days "}
            }
        }

        append result "ago"
    } elseif { $age_seconds < $days_limit * 60 * 60 * 24 } {
        set result [lc_time_fmt $timestamp_ansi $mode_2_fmt $locale]
    } else {
        set result [lc_time_fmt $timestamp_ansi $mode_3_fmt $locale]

    }
}


ad_proc -public util::word_diff {
    {-old:required}
    {-new:required}
    {-split_by {}}
    {-filter_proc {ns_quotehtml}}
    {-start_old {<strike><i><font color="blue">}}
    {-end_old {</font></i></strike>}}
    {-start_new {<u><b><font color="red">}}
    {-end_new {</font></b></u>}}
} {
    Does a word (or character) diff on two lines of text and indicates text
    that has been deleted/changed or added by enclosing it in
    start/end_old/new.
    
    @param    old    The original text.
    @param    new    The modified text.
    
    @param    split_by    If split_by is a space, the diff will be made
    on a word-by-word basis. If it is the empty string, it will be made on
    a char-by-char basis.

    @param    filter_proc    A filter to run the old/new text through before
    doing the diff and inserting the HTML fragments below. Keep in mind
    that if the input text is HTML, and the start_old, etc... fragments are
    inserted at arbitrary locations depending on where the diffs are, you
    might end up with invalid HTML unless the original HTML is quoted.

    @param    start_old    HTML fragment to place before text that has been removed.
    @param    end_old      HTML fragment to place after text that has been removed.
    @param    start_new    HTML fragment to place before new text.
    @param    end_new      HTML fragment to place after new text.

    @see ns_quotehtml
    @author Gabriel Burca
} {

    if {$filter_proc ne ""} {
        set old [$filter_proc $old]
        set new [$filter_proc $new]
    }

    set old_f [ad_tmpnam]
    set new_f [ad_tmpnam]
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

    #    For debugging purposes:
    #    set diff_pipe [open "| diff -f $old_f $new_f" "r"]
    #    while {![eof $diff_pipe]} {
    #        append res "[gets $diff_pipe]<br>"
    #    }

    set diff_pipe [open "| diff -f $old_f $new_f" "r"]
    while {![eof $diff_pipe]} {
        gets $diff_pipe diff
        if {[regexp {^d(\d+)(\s+(\d+))?$} $diff full m1 m2]} {
            if {$m2 ne ""} {set d_end $m2} else {set d_end $m1}
            for {set i $sv} {$i < $m1} {incr i} {
                append res "${split_by}[lindex $old_w $i]"
            }
            for {set i $m1} {$i <= $d_end} {incr i} {
                append res "${split_by}${start_old}[lindex $old_w $i]${end_old}"
            }
            set sv [expr {$d_end + 1}]
        } elseif {[regexp {^c(\d+)(\s+(\d+))?$} $diff full m1 m2]} {
            if {$m2 ne ""} {set d_end $m2} else {set d_end $m1}
            for {set i $sv} {$i < $m1} {incr i} {
                append res "${split_by}[lindex $old_w $i]"
            }
            for {set i $m1} {$i <= $d_end} {incr i} {
                append res "${split_by}${start_old}[lindex $old_w $i]${end_old}"
            }
            while {![eof $diff_pipe]} {
                gets $diff_pipe diff
                if {$diff eq "."} {
                    break
                } else {
                    append res "${split_by}${start_new}${diff}${end_new}"
                }
            }
            set sv [expr {$d_end + 1}]
        } elseif {[regexp {^a(\d+)$} $diff full m1]} {
            set d_end $m1
            for {set i $sv} {$i < $m1} {incr i} {
                append res "${split_by}[lindex $old_w $i]"
            }
            while {![eof $diff_pipe]} {
                gets $diff_pipe diff
                if {$diff eq "."} {
                    break
                } else {
                    append res "${split_by}${start_new}${diff}${end_new}"
                }
            }
            set sv [expr {$d_end + 1}]
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

ad_proc -public util::roll_server_log {} {
    Invoke the AOLserver ns_logroll command with some bookend log records.  This rolls the error log, not the access log.
} { 
    # This param controlls how many backups of the server log to keep, 
    ns_config -int "ns/parameters" logmaxbackup 10
    ns_log Notice "util::roll_server_log: Rolling the server log now..." 
    ns_logroll 
    ns_log Notice "util::roll_server_log: Done rolling the server log." 
    return 0
} 

ad_proc -private util::cookietime {time} {
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

                if { $check_file_func eq "" || [$check_file_func $file] } {
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

ad_proc -public util::string_check_urlsafe {
    s1
} {
    This proc accepts a string and verifies if it is url safe.
    - make sure there is no space
    - make sure there is no special characters except '-' or '_'
    Returns 1 if yes and 0 if not. 
    Meant to be used in the validation section of ad_form.
} {
    return [regexp {[<>:\"|/@\#%&+\\ ]} $s1]
}

ad_proc -public util::which {prog} {

    @author Gustaf Neumann

    Use environment variable PATH to search for the specified executable
    program. Replacement for UNIX command "which", avoiding exec.

    exec which:    3368.445 microseconds per iteration
    ::util::which:  282.372 microseconds per iteration
    
    In addition of being more than 10 time faster than the 
    version via exec, this version is less platform dependent.

    @param prog   name of the program to be located on the search path
    @return fully qualified name including path, when specified program is found, 
    or otherwise empty string

} {
    switch $::tcl_platform(platform) {
        windows {
            #
            # Notice: Windows has an alternative search environment 
            #         via registry. Maybe it is necessary in the future
            #         to locate the program via registry (sketch below)
            #
            # package require registry
            # set key {HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\App Paths}
            # set entries [registry keys $key $prog.*]
            # if {[llength $entries]>0} {
            #   set fullkey "$key\\[lindex $entries 0]"
            #   return [registry get $fullkey ""]
            # }
            # return ""
            #
            set searchdirs [split $::env(PATH) \;] 
            set exts       [list .exe .dll .com .bat]
        }
        default { 
            set searchdirs [split $::env(PATH) :] 
            set exts       [list ""]
        }
    }
    foreach dir $searchdirs {
        set fullname [file join $dir $prog]
        foreach ext $exts {
            if {[file executable $fullname$ext]} {
                return $fullname$ext
            }
        }
    }
    return ""
}

ad_proc util::catch_exec {command result_var} {
    Catch a call to Tcl exec. Handle shell return codes
    consistently. Works like catch. The result of the exec is put into
    the variable named in result_var. Inspired by
    http://wiki.tcl.tk/1039

    @param command A list of arguments to pass to exec
    @param result_var Variable name in caller's scope to set the result in

    @return 0 or 1. 0 if no error, 1 if an error occured. If an error occured
    the error message will be put into result_var in the caller's scope.

    @author Dave Bauer
    @creation-date 2008-01-28
    
} {
    
    upvar result_var result
    set status [catch [concat exec $command] result]
    if { $status == 0 } {
        
        # The command succeeded, and wrote nothing to stderr.                   
        # $result contains what it wrote to stdout, unless you                  
        # redirected it
        ns_log debug "util::catch_exec: Status == 0 $result"
        
    } elseif {$::errorCode eq "NONE"} {

        # The command exited with a normal status, but wrote something          
        # to stderr, which is included in $result.                              
        ns_log debug "util::catch_exec: Normal Status $result"
        
    } else {

        switch -exact -- [lindex $::errorCode 0] {

            CHILDKILLED {
                lassign $::errorCode  - pid sigName msg 

                # A child process, whose process ID was $pid,                   
                # died on a signal named $sigName.  A human-                    
                # readable message appears in $msg.
                ns_log notice "util::catch_exec: childkilled $pid $sigName $msg $result"
                set result "process $pid died with signal $sigName \"$msg\""
                return 1
            }

            CHILDSTATUS {

                lassign $::errorCode  - pid code 

                # A child process, whose process ID was $pid,                   
                # exited with a non-zero exit status, $code.
                ns_log notice "util::catch_exec: Childstatus $pid $code $result"
            }

            CHILDSUSP {

                lassign $::errorCode  - pid sigName msg 

                # A child process, whose process ID was $pid,                   
                # has been suspended because of a signal named                  
                # $sigName.  A human-readable description of the                
                # signal appears in $msg.                                       
                ns_log notice "util::catch_exec: Child susp $pid $sigName $msg $result"
                set result "process $pid was suspended with signal $sigName \"$msg\""
                return 1
            }

            POSIX {

                lassign $::errorCode  - errName msg 

                # One of the kernel calls to launch the command                 
                # failed.  The error code is in $errName, and a                 
                # human-readable message is in $msg.                            
                ns_log notice "util::catch_exec: posix $errName $msg $result"
                set result "an error occured $errName \"$msg\""
                return 1
            }

        }
    }
    return 0
}

ad_proc util::external_url_p { url } {
    check if this URL is external to the current host or a valid alternative
    valid alternatives include
    HTTPS or HTTP protocol change
    HTTP or HTTPS port number added or removed from current host name    
    or another hostname that the host responds to (from host_node_map)
} {
    set external_url_p [util_complete_url_p $url]
    #
    # Only if the URL is syntactical a URL with a protocol, it might
    # be external.
    #
    if {$external_url_p} {
        set locations_list [security::locations]
        # more valid url pairs with host_node_map
        
        foreach location $locations_list {
            set encoded_location [ns_urlencode $location]
            # ns_log Notice "util::external_url_p location \"$location/*\" url $url match [string match "${encoded_location}/*" $url]"
            set external_url_p [expr { $external_url_p && ![string match "$location/*" $url] } ] 
            set external_url_p [expr { $external_url_p && ![string match "${encoded_location}/*" $url] } ] 
        }
    }
    return $external_url_p
}

ad_proc -public ad_job {
    {-queue jobs}
    {-timeout ""}
    args
} {

    Convenience wrapper for simple usages of ns_job provided by
    AOLServer and NaviServer. The provided command (args) is executed
    in a separate thread of the specified job queue. On success the
    function returns the result of the provided command.

    If the queue does not exist, the queue is generated on the fly
    with default settings. When the timeout is specified and it
    expires, the client side will raise an error. Note that the
    executing job is not canceled but will run to its end.

    @author Gustaf Neumann

    @param queue Name of job queue
    @param timeout timeout for job, might be 1:0 for 1 sec
    @param args the command to be executed
    @return result of the specified command
} {

    if {$timeout ne ""} {
        set timeout "-timeout $timeout"
    }
    if {$queue ni [ns_job queues]} {
        ns_job create $queue
    }
    set j [ns_job queue $queue $args]
    return [ns_job wait {*}$timeout $queue $j]
}

#
# Provide a clean way of handling exceptions in mutexed regions
# (between locking and unlocking of an mutex). Should be used probably
# on more places in OpenACS.
#

if {[ns_info name] eq "NaviServer"} {
    ad_proc -public ad_mutex_eval {mutex script} {

        Compatibility proc for handling differences between NaviServer
        and AOLserver since AOLserver does not support "ns_mutex
    eval".

        @author Gustaf Neumann
        
    } {
        uplevel [list ns_mutex eval $mutex $script]
    }
} else {
    ad_proc -public ad_mutex_eval {mutex script} {

        Compatibility proc for handling differences between NaviServer
        and AOLserver since AOLserver does not support "ns_mutex
    eval".

        @author Gustaf Neumann

    } {
        ns_mutex lock $mutex
        set err [catch {uplevel $script} result]
        ns_mutex unlock $mutex
        if {$err} {
            error $result
        }
        return $result
    }
}

ad_proc ad_tmpnam {{template ""}} {
    A stub function to replace the deprecated "ns_tmpnam", 
    which uses the deprecated C-library function "tmpnam()"
} {
    if {$template eq ""} {
        set template [ns_config ns/parameters tmpdir]/oacs-XXXXXX
    }
    ns_mktemp $template
}

ad_proc ad_tmpdir {} {
    Convenience function to return the tmp directory
} {
    return [ns_config ns/parameters tmpdir]
}


#
# Experimental disk-cache, to test whether this can speed up e.g. openacs.org forums threads....
# Documentation follows
#

if { [apm_first_time_loading_p] } {
    nsv_set ad_disk_cache mutex [ns_mutex create]
}

ad_proc -public util::disk_cache_flush {
    -key:required
    -id:required
} {
} {
    set dir [ad_tmpdir]/$key
    foreach file [flib -nocomplain $dir/$id-*] {
        file delete $file
        ns_log notice "FLUSH file delete $file"
    }
}

ad_proc -public util::disk_cache_eval {
    -call:required
    -key:required
    -id:required
} {
} {
    set cache [::parameter::get_from_package_key \
		 -package_key acs-tcl \
		 -parameter DiskCache \
		 -default 1]
    if {$cache} {
        set hash [ns_sha1 $call]
        set dir [ad_tmpdir]/oacs-cache/$key
        set file_name $dir/$id-$hash
        if {![file isdirectory $dir]} {file mkdir $dir}
        ns_mutex eval [nsv_get ad_disk_cache mutex] {
            if {[file readable $file_name]} {
                set result [template::util::read_file $file_name]
            } else {
                set result [{*}$call]
                template::util::write_file $file_name $result
            }
        }
    } else {
        set result [{*}$call]
    }
    return $result
}

ad_proc -public util::request_info {
    {-with_headers:boolean false}
} {
    
    Produce a string containing the detailed request information.
    This is in particular useful for debugging, when errors are raised.
    
    @param with_headers Include request headers
    @author Gustaf Neumann

} {
    set info ""
    if {[ns_conn isconnected]} {
        #
        # Base information
        #
        append info "    " \
            [ns_conn method] \
            " [util_current_location][ns_conn url]?[ns_conn query]" \
            " referred by '[get_referrer]' peer [ad_conn peeraddr] user_id [ad_conn user_id]"
        
        if {[ns_conn method] eq "POST"} {
            # 
            # POST data info
            #
            if {[ns_conn flags] & 1} {
                append info "\n connection already closed, cooked form-content:"
                foreach {k v} [ns_set array [ns_getform]] {
                    if {[string length $v] > 100} {
                        set v "[string range $v 0 100]..."
                    }
                    append info "\n        $k:\t$v"
                }
            } else {
                set data [ns_conn content]
                if {[string length $data] < 2000} {
                    append info "\n        post-data: $data"
                }
            }
        }

        #
        # Optional header info
        #
        if {$with_headers_p} {
            append info \n
            foreach {k v} [ns_set array [ns_conn headers]] {
                append info "\n $k:\t$v"
            }
        }
    }
    return $info
}



ad_proc -public ad_log {
    level
    message
} {
    Output ns_log message with detailed context. This function is
    intended to be used typically with "error" to ease debugging.
    
    @param level Severity level such as "error" or "warning".
    @param message Log message

    @author Gustaf Neumann
} {
    set with_headers [expr {$level in {error Error}}]
    append request "    " \
        [util::request_info -with_headers=$with_headers]
    
    ns_log $level "${message}\n[uplevel ad_get_tcl_call_stack]${request}\n"
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
