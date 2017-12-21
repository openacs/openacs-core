ad_library {

    Provides a variety of non-ACS-specific utilities, including
    the procs to support the who's online feature.

    @author Various (acs@arsdigita.com)
    @creation-date 13 April 2000
    @cvs-id $Id$
}

namespace eval util {}


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

ad_proc -deprecated ad_dbclick_check_dml { 
    {-bind  ""}
    statement_name table_name id_column_name generated_id return_url insert_dml 
} {
    This proc is used for pages using double click protection. table_name
    is table_name for which we are checking whether the double click
    occurred. id_column_name is the name of the id table
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
    export_vars is now the preferred interface.
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
            switch -- $type {
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

ad_proc -deprecated export_url_vars {
    -sign:boolean
    args 
} {
    export_vars is now the preferred interface.

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
                switch -- $type {
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

ad_proc -public -deprecated exists_or_null { varname } {
    Returns the contents of the variable if it exists, otherwise returns empty string
} {
    upvar 1 $varname var
    if {[info exists var]} {
        return $var
    }
    return ""
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
        <script type="text/javascript" nonce="$::__csp_nonce">
        window.location.href = "[ns_quotehtml $url]";
        </script>
        </head>
        <body>
        <h2>Loading...</h2>
        If your browser does not automatically redirect you, <a href="[ns_quotethml $url]">please click here</a>.
        </body>}]
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


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
