ad_library {

    Provides a collection of deprecated procs to provide backward
    compatibility for sites who have not yet removed calls to the
    deprecated functions.

    In order to skip loading of deprecated code, use the following
    snippet in your config file

        ns_section ns/server/${server}/acs
            ns_param WithDeprecatedCode 0

    @cvs-id $Id$
}

if {![ad_with_deprecated_code_p]} {
    ns_log notice "deprecated-procs: skip deprecated code"
    return
}
ns_log notice "deprecated-procs: load deprecated code"


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
    <li>It can sign variables (the <code>:sign</code> flag)
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
    <li>a scalar variable, <code>foo</code>,
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
     character sets registry</a>) is provided by:</p>

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
    character sets registry</a> (a special variant would be an empty
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
    # date value is formatted correctly for ns_dbformvalue
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
            # Let's see if Oracle would accept these variables as part
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

ad_proc -deprecated ad_present_user {
    user_id
    name
} {
    This function is an alias to acs_community_member_link
    and receives identical parameters, but the former finds out the name
    of the user if a blank is passed. That's why it's marked as deprecated.

    @return the HTML link of the community member page of a particular user

    @author Unknown
    @author Roberto Mello

    @see acs_community_member_link
} {
    return [acs_community_member_link -user_id $user_id -label $name]
}

ad_proc -deprecated ad_admin_present_user {
    user_id
    name
} {
    This function is an alias to acs_community_member_admin_link
    and receives identical parameters, but the former finds out the name
    of the user if a blank is passed. That's why it's marked as deprecated.

    @return the HTML link of the community member page of a particular admin user.

    @author Unknown
    @author Roberto Mello

    @see acs_community_member_admin_link
} {
    return [acs_community_member_admin_link -user_id $user_id -label $name]
}

ad_proc -deprecated ad_header {
    {-focus ""}
    page_title
    {extra_stuff_for_document_head ""}
} {
    writes HEAD, TITLE, and BODY tags to start off pages in a consistent fashion

    @see   Documentation on the site master template for the proper way to standardize page headers
} {
    return [ad_header_with_extra_stuff -focus $focus $page_title $extra_stuff_for_document_head]
}

ad_proc -deprecated ad_header_with_extra_stuff {
    {-focus ""}
    page_title
    {extra_stuff_for_document_head ""}
    {pre_content_html ""}
} {
    This is the version of the ad_header that accepts extra stuff for the document head and pre-page content html

    @see  Documentation on the site master template for the proper way to standardize page headers
} {
    set html "<html>
<head>
$extra_stuff_for_document_head
<title>$page_title</title>
</head>
"
    array set attrs [list]
    set attrs(bgcolor) [parameter::get -package_id [ad_acs_kernel_id] -parameter bgcolor -default "white"]
    set attrs(text)    [parameter::get -package_id [ad_acs_kernel_id] -parameter textcolor -default "black"]

    if { $focus ne "" } {
        template::add_body_script -script [subst {
            window.addEventListener('load', function () {document.${focus}.focus()}, false);
        }]
    }
    foreach attr [array names attrs] {
	lappend attr_list "$attr=\"$attrs($attr)\""
    }
    append html "<body [join $attr_list]>\n"

    append html $pre_content_html
    return $html
}

ad_proc -deprecated ad_footer {
    {signatory ""}
    {suppress_curriculum_bar_p 0}
} {
    Writes a horizontal rule, a mailto address box
    (ad_system_owner if not specified as an argument),
    and then closes the BODY and HTML tags


    @see  Documentation on the site master template for the proper way to standardize page footers
} {
    global sidegraphic_displayed_p
    if { $signatory eq "" } {
	set signatory [ad_system_owner]
    }
    if { [info exists sidegraphic_displayed_p] && $sidegraphic_displayed_p } {
	# we put in a BR CLEAR=RIGHT so that the signature will clear any side graphic
	# from the ad-sidegraphic.tcl package
	set extra_br "<br clear=right>"
    } else {
	set extra_br ""
    }
    if { [parameter::get -package_id [ad_acs_kernel_id] -parameter EnabledP -default 0] && [parameter::get -package_id [ad_acs_kernel_id] -parameter StickInFooterP -default 0] && !$suppress_curriculum_bar_p} {
	set curriculum_bar "<center>[curriculum_bar]</center>"
    } else {
	set curriculum_bar ""
    }
    if { [info commands ds_link] ne "" } {
	set ds_link [ds_link]
    } else {
	set ds_link ""
    }
    return "
$extra_br
$curriculum_bar
<hr>
$ds_link
<a href=\"mailto:$signatory\"><address>$signatory</address></a>
</body>
</html>"
}

# need special headers and footers for admin pages
# notably, we want pages signed by someone different
# (the user-visible pages are probably signed by
# webmaster@yourdomain.com; the admin pages are probably
# used by this person or persons.  If they don't like
# the way a page works, they should see a link to the
# email address of the programmer who can fix the page).

ad_proc -public -deprecated ad_admin_owner {} {
    @return E-mail address of the Administrator of this site.
    @see ad_host_administrator
} {
    return [parameter::get -package_id [ad_acs_kernel_id] -parameter HostAdministrator]
}

ad_proc -deprecated ad_admin_header {
    {-focus ""}
    page_title
} {

    @see  Documentation on the site master template for the proper way to standardize page headers
} {
    return [ad_header_with_extra_stuff -focus $focus $page_title]
}

ad_proc -deprecated ad_admin_footer {} {
    Signs pages with ad_admin_owner (usually a programmer who can fix
    bugs) rather than the signatory of the user pages


    @see  Documentation on the site master template for the proper way to standardize page footers
} {
    if { [info commands ds_link] ne "" } {
	set ds_link [ds_link]
    } else {
	set ds_link ""
    }
    return "<hr>
$ds_link
<a href=\"mailto:[ad_admin_owner]\"><address>[ad_admin_owner]</address></a>
</body>
</html>"
}

ad_proc -deprecated ad_get_user_info {} {
    Sets first_names, last_name, email in the environment of its caller.
    @return ad_return_error if user_id can't be found.

    @author Unknown
    @author Roberto Mello

    @see acs_user::get
} {
    uplevel {
	set user_id [ad_conn user_id]
	if { [catch {
	    db_1row user_name_select {
		select first_names, last_name, email
		from persons, parties
		where person_id = :user_id
		and person_id = party_id
	    }
	} errmsg] } {
	    ad_return_error "Couldn't find user info" "Couldn't find user info."
	    return
	}
    }
}

ad_proc -deprecated ad_parameter {
    -localize:boolean
    -set
    {-package_id ""}
    name
    {package_key ""}
    {default ""}
} {
    Package instances can have parameters associated with them.  This function is used for accessing
    and setting these values.  Parameter values are stored in the database and cached within memory.
    New parameters can be created with the <a href="/acs-admin/apm/">APM</a> and values can be set
    using the <a href="/admin/site-map">Site Map UI.</a>.  Because parameters are specified on an instance
    basis, setting the package_key parameter (preserved from the old version of this function) does not
    affect the parameter retrieved.  If the code that calls ad_parameter is being called within the scope
    of a running server, the package_id will be determined automatically.  However, if you want to use a
    parameter on server startup or access an arbitrary parameter (e.g., you are writing bboard code, but
    want to know an acs-kernel parameter), specify the package_id parameter to the object id of the package
    you want.
    <p>
    Note: <strong>The parameters/ad.ini file is deprecated.</strong>

    @see parameter::set_value
    @see parameter::get

    @param set Use this if you want to indicate a value to set the parameter to.
    @param package_id Specify this if you want to manually specify what object id to use the new parameter.
    @return The parameter of the object or if it doesn't exist, the default.
} {
    if {[info exists set]} {
	set ns_param [parameter::set_value -package_id $package_id -parameter $name -value $set]
    } else {
        set ns_param [parameter::get -localize=$localize_p -package_id $package_id -parameter $name -default $default]
    }

    return $ns_param
}


ad_proc -deprecated doc_serve_template { __template_path } { Serves the document in the environment using a particular template. } {
    upvar #0 doc_properties __doc_properties
    foreach __name [array names __doc_properties] {
	set $__name $__doc_properties($__name)
    }

    set adp [ns_adp_parse -file $__template_path]
    set content_type [ns_set iget [ad_conn outputheaders] "content-type"]
    if { $content_type eq "" } {
	set content_type "text/html"
    }
    doc_return 200 $content_type $adp
}

ad_proc -deprecated doc_serve_document {} { Serves the document currently in the environment. } {
    if { ![doc_exists_p] } {
	error "No document has been built."
    }

    set mime_type [doc_get_property mime_type]
    if { $mime_type eq "" } {
	if { [doc_property_exists_p title] } {
	    set mime_type "text/html;content-pane"
	} else {
	    set mime_type "text/html"
	}
    }

    switch -- $mime_type {
	text/html;content-pane - text/x-html-content-pane {
	    # It's a content pane. Find the appropriate template.
	    set template_path [doc_find_template [ad_conn file]]
	    if { $template_path eq "" } {
		ns_returnerror 500 "Unable to find master template"
	        ns_log error \
		    "Unable to find master template for file '[ad_conn file]'"
	    } else {
	        doc_serve_template $template_path
	    }
	}
	default {
	    # Return a complete document.
	    ns_return 200 $mime_type [doc_get_property body]
	}
    }
}

ad_proc -deprecated doc_tag_ad_document { contents params } {} {
    for { set i 0 } { $i < [ns_set size $params] } { incr i } {
	doc_set_property [ns_set key $params $i] [ns_set value $params $i]
    }
    doc_set_property _adp 1
    return [template::adp_parse_string $contents]
}

ad_proc -deprecated doc_tag_ad_property { contents params } {} {
    set name [ns_set iget $params name]
    if { $name eq "" } {
	return "<em>No <tt>name</tt> property in <tt>AD-PROPERTY</tt> tag</em>"
    }
    doc_set_property $name $contents
}



ad_proc -deprecated doc_init {} { Initializes the global environment for document handling. } {
    global doc_properties
    if { [info exists doc_properties] } {
	unset doc_properties
    }
    array set doc_properties {}
}

ad_proc -deprecated doc_set_property { name value } { Sets a document property. } {
    global doc_properties
    set doc_properties($name) $value
}

ad_proc -deprecated doc_property_exists_p { name } { Return 1 if a property exists, or 0 if not. } {
    global doc_properties
    return [info exists doc_properties($name)]
}

ad_proc -deprecated doc_get_property { name } { Returns a property (or an empty string if no such property exists). } {
    global doc_properties
    if { [info exists doc_properties($name)] } {
	return $doc_properties($name)
    }
    return ""
}

ad_proc -deprecated doc_body_append { str } { Appends $str to the body property. } {
    global doc_properties
    append doc_properties(body) $str
}

ad_proc -deprecated doc_set_mime_type { mime_type } { Sets the mime-type property. } {
    doc_set_property mime_type $mime_type
}

ad_proc -deprecated doc_exists_p {} { Returns 1 if there is a document in the global environment. } {
    global doc_properties
    if { [array size doc_properties] > 0 } {
	return 1
    }
    return 0
}

ad_proc -deprecated doc_body_flush {} { Flushes the body (if possible). } {
    # Currently a no-op.
}

ad_proc -deprecated doc_find_template { filename } { Finds a master.adp file which can be used as a master template, looking in the directory containing $filename and working our way down the directory tree. } {
    set path_root $::acs::rootdir

    set start [clock clicks -milliseconds]

    set dir [file dirname $filename]
    while { [string length $dir] > 1 && [string first $path_root $dir] == 0 } {
	# Only look in directories under the path root.
	if { [file isfile "$dir/master.adp"] } {
	    return "$dir/master.adp"
	}
	set dir [file dirname $dir]
    }

    if { [file exists "$path_root/templates/master.adp"] } {
	return "$path_root/templates/master.adp"
    }

    # Uhoh. Nada!
    return ""
}

####################
#
# Legacy stuff
#
####################


ad_proc -deprecated util_striphtml {html} {
    Deprecated. Use ad_html_to_text instead.

    @see ad_html_to_text
} {
    return [ad_html_to_text -- $html]
}


ad_proc -deprecated util_convert_plaintext_to_html { raw_string } {

    Almost everything this proc does can be accomplished with the <a
    href="/api-doc/proc-view?proc=ad_text_to_html"><code>ad_text_to_html</code></a>.
    Use that proc instead.

    <p>

    Only difference is that ad_text_to_html doesn't check
    to see if the plaintext might in fact be HTML already by
    mistake. But we usually don't want that anyway,
    because maybe the user wanted a &lt;p&gt; tag in his
    plaintext. We'd rather let the user change our
    opinion about the text, e.g. html_p = 't'.

    @see ad_text_to_html
} {
    if { [regexp -nocase {<p>} $raw_string] || [regexp -nocase {<br>} $raw_string] } {
        # user was already trying to do this as HTML
        return $raw_string
    } else {
        return [ad_text_to_html -no_links -- $raw_string]
    }
}

ad_proc -deprecated util_maybe_convert_to_html {raw_string html_p} {

    This proc is deprecated. Use <a
    href="/api-doc/proc-view?proc=ad_convert_to_html"><code>ad_convert_to_html</code></a>
    instead.

    @see ad_convert_to_html

}  {
    if { $html_p == "t" } {
        return $raw_string
    } else {
        return [ad_text_to_html -- $raw_string]
    }
}

ad_proc -deprecated -warn util_quotehtml { arg } {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>.
    Use that instead. This one will be deleted eventually.

    @see ad_quotehtml
} {
    return [ns_quotehtml $arg]
}

ad_proc -deprecated util_quote_double_quotes {arg} {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>.
    Use that instead. This one will be deleted eventually.

    @see ad_quotehtml
} {
    return [ns_quotehtml $arg]
}

ad_proc -deprecated philg_quote_double_quotes {arg} {
    This proc does exactly the same as <a href="/api-doc/proc-view?proc=ad_quotehtml"><code>ad_quotehtml</code></a>.
    Use that instead. This one will be deleted eventually.

    @see ad_quotehtml
} {
    return [ns_quotehtml $arg]
}




ad_proc -deprecated ad_dimensional_set_variables {option_list {options_set ""}} {
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
		switch -- $Tformat {
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
    builds a form for choosing the columns to display
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

ad_proc -deprecated ad_order_by_from_sort_spec {sort_by tabledef} {
    Takes a sort_by spec, and translates it into an "order by" clause
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

ad_proc -deprecated ad_same_page_link {variable value text {form ""}} {
    Makes a link to this page, with a new value for "variable".
} {
    if { $form eq "" } {
        set form [ns_getform]
    }
    set url_vars [export_ns_set_vars url $variable $form]
    set href "[ad_conn url]?$variable=[ns_urlencode $value]$url_vars"
    return [subst {<a href="[ns_quotehtml $href]">[ns_quotehtml $text]</a>}]
}

ad_proc -deprecated ad_reverse order {
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

ad_proc -deprecated ad_custom_load {user_id item_group item item_type} {
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

ad_proc -deprecated ad_custom_list {user_id item_group item_set item_type target_url custom_url {new_string "new view"}} {
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


ad_proc -deprecated ad_custom_page_defaults {defaults} {
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

    # we have a form so stuff in the ones we don't find.
    # should think about how to support lists and ns_set persist too.
    foreach kvp $defaults {
        if {[ns_set find $form [lindex $kvp 0]] < 0} {
            ns_set put $form [lindex $kvp 0] [lindex $kvp 1]
        }
    }
}

ad_proc -deprecated ad_custom_form {return_url item_group item} {
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

ad_proc -deprecated ad_dimensional_settings {define current} {
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
                append html "<option selected=\"selected\" value=\"[ns_quotehtml [lindex $val 0]]\">[lindex $val 1]</option>\n"
            } else {
                append html "<option value=\"[ns_quotehtml [lindex $val 0]]\">[lindex $val 1]</option>\n"
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



########################################################################
# was in set-operation-procs.tcl
########################################################################


ad_proc -deprecated set_member? { s v } {
    <p>Tests whether or not $v is a member of set $s.</p>
} {
    if {$v ni $s} {
	return 0
    } else {
	return 1
    }
}



ad_proc -deprecated set_append! { s-name v } {
    <p>Adds the element v to the set named s-name in the calling
    environment, if it isn't already there.</p>
} {
    upvar $s-name s

    if { ![set_member? $s $v] } {
	lappend s $v
    }
}



ad_proc -deprecated set_union { u v } {
    <p>Returns the union of sets $u and $v.</p>
} {
    set result $u

    foreach ve $v {
	if { ![set_member? $result $ve] } {
	    lappend result $ve
	}
    }

  return $result
}

ad_proc -deprecated set_union! { u-name v } {
    <p>Computes the union of the set stored in the variable
    named $u-name in the calling environment and the set v,
    sets the variable named $u-name in the calling environment
    to that union, and also returns that union.</p>
} {
    upvar $u-name u

    foreach ve $v {
	if { ![set_member? $u $ve] } {
	    lappend u $ve
	}
    }

    return $u
}




ad_proc -deprecated set_intersection { u v } {
    <p>Returns the intersection of sets $u and $v.</p>
} {
    set result [list]

    foreach ue $u {
	if { [set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    return $result
}

ad_proc -deprecated set_intersection! { u-name v } {
    <p>Computes the intersection of the set stored in the variable
    named $u-name in the calling environment and the set v,
    sets the variable named $u-name in the calling environment
    to that intersection, and also returns that intersection.</p>
} {
    upvar $u-name u
    set result [list]

    foreach ue $u {
	if { [set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    set u $result
    return $result
}

ad_proc -deprecated set_difference { u v } {
    <p>Returns the difference of sets $u and $v.  (i.e. The set of all
    members of u that aren't also members of $v.)</p>
} {
    set result [list]

    foreach ue $u {
	if { ![set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    return $result
}

ad_proc -deprecated set_difference! { u-name v } {
    <p>Computes the difference of the set stored in the variable
    named $u-name in the calling environment and the set v,
    sets the variable named $u-name in the calling environment
    to that difference, and also returns that difference.</p>
} {
    upvar $u-name u
    set result [list]

    foreach ue $u {
	if { ![set_member? $v $ue] } {
	    lappend result $ue
	}
    }

    set u $result
    return $result
}

########################################################################
# from tcl/navigation-procs.tcl
########################################################################

ad_proc -deprecated -public ad_context_bar_ws args {
    Returns a Yahoo-style hierarchical navbar. Use ad_context_bar instead.

    @param args list of url desc ([list [list url desc] [list url desc] ... "terminal"])
    @return an html fragment generated by ad_context_bar_html

    @see ad_context_bar
} {
    return [ad_context_bar $args]
}


# a context bar, rooted at the workspace or index, depending on whether
# user is logged in

ad_proc -deprecated -public ad_context_bar_ws_or_index args {
    Returns a Yahoo-style hierarchical navbar. Use ad_context_bar instead.

    @param args list of url desc ([list [list url desc] [list url desc] ... "terminal"])
    @return an html fragment generated by ad_context_bar

    @see ad_context_bar
} {
    return [ad_context_bar $args]
}

ad_proc -public -deprecated ad_admin_context_bar args {
    Returns a Yahoo-style hierarchical navbar. Use ad_context_bar instead.

    @param args list of url desc ([list [list url desc] [list url desc] ... "terminal"])
    @return an html fragment generated by ad_context_bar

    @see ad_context_bar
} {
    return [ad_context_bar $args]
}


########################################################################
# From tcl/http-client-procs.tcl
########################################################################

#########################
## Deprecated HTTP API ##
#########################

ad_proc -deprecated -public util_link_responding_p {
    url
    {list_of_bad_codes "404"}
} {
    Returns 1 if the URL is responding (generally we think that anything other than 404 (not found) is okay).

    @see util::link_responding_p
} {
    util::link_responding_p -url $url -list_of_bad_codes $list_of_bad_codes
}

ad_proc -public -deprecated util_get_http_status {
    url
    {use_get_p 1}
    {timeout 30}
} {
    Returns the HTTP status code, e.g., 200 for a normal response
    or 500 for an error, of a URL.  By default this uses the GET method
    instead of HEAD since not all servers will respond properly to a
    HEAD request even when the URL is perfectly valid.  Note that
    this means AOLserver may be sucking down a lot of bits that it
    doesn't need.

    @see util::get_http_status
} {
    return [util::get_http_status -url $url -use_get_p $use_get_p -timeout $timeout]
}

ad_proc -deprecated -public ad_httpget {
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

    @see util::http::get
} {
    ns_log debug "Getting {$url} {$headers} {$timeout} {$depth}"

    if {[incr depth] > 10} {
        return -code error "ad_httpget:  Recursive redirection:  $url"
    }

    lassign [ns_httpopen GET $url $headers $timeout] rfd wfd headers
    close $wfd

    set response [ns_set name $headers]
    set status [lindex $response 1]
    set last_modified [ns_set iget $headers last-modified]

    if {$status == 302 || $status == 301} {
        set location [ns_set iget $headers location]
        if {$location ne ""} {
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
        if { $length eq "" } {set length -1}

        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd

        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd

        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    }

    # order matters here since we depend on page content
    # being element 1 in this list in util_httpget
    return [list page $page \
                status $status \
                modified $last_modified]
}

ad_proc -deprecated -public util_httpget {
    url {headers ""} {timeout 30} {depth 0}
} {
    util_httpget simply calls util::http::get which also returns
    status and last_modified

    @see util::http::get
} {
    return [dict get [util::http::get -url $url -headers $headers -timeout $timeout -depth $depth] page]
}

# httppost; give it a URL and a string with formvars, and it
# returns the page as a Tcl string
# formvars are the posted variables in the following form:
#        arg1=value1&arg2=value2

# in the event of an error or timeout, -1 is returned

ad_proc -deprecated -public util_httppost {url formvars {timeout 30} {depth 0} {http_referer ""}} {
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

        #headers necessary for a post and the form variables

        _ns_http_puts $timeout $wfd "Content-type: application/x-www-form-urlencoded \r"
        _ns_http_puts $timeout $wfd "Content-length: [string length $formvars]\r"
        _ns_http_puts $timeout $wfd \r
        _ns_http_puts $timeout $wfd "$formvars\r"
        flush $wfd
        close $wfd

        set rpset [ns_set new [_ns_http_gets $timeout $rfd]]
        while 1 {
            set line [_ns_http_gets $timeout $rfd]
            if { $line eq "" } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        if {$status == 302} {
            set location [ns_set iget $headers location]
            if {$location ne ""} {
                ns_set free $headers
                close $rfd
                return [util_httpget $location {}  $timeout $depth]
            }
        }
        set length [ns_set iget $headers content-length]
        if { "" eq $length } {set length -1}
        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]
        ns_set free $headers
        close $rfd
        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    } errmgs ] } {return -1}
    return $page
}

# system by Tracy Adams (teadams@arsdigita.com) to permit AOLserver to POST
# to another Web server; sort of like ns_httpget

ad_proc -deprecated -public util_httpopen {
    method
    url
    {rqset ""}
    {timeout 30}
    {http_referer ""}
} {
    Like ns_httpopen but works for POST as well; called by util_httppost
} {

    if { ![string match "http://*" $url] } {
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
        if {$rqset ne ""} {
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
        #close $wfd
        #close $rfd
        if { [info exists rpset] } {ns_set free $rpset}
        return -1
    }
    return [list $rfd $wfd ""]

}

ad_proc -deprecated -public util_http_file_upload { -file -data -binary:boolean -filename
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

    The switches <tt>-file /path/to/file</tt> and <tt>-data
    $raw_data</tt> are mutually exclusive.  You can specify one or the
    other, but not both.  NOTE: it is perfectly valid to not specify
    either, in which case no file is uploaded, but form variables are
    encoded using <tt>multipart/form-data</tt> instead of the usual
    encoding (as noted aboved).

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
    (it can be inferred from the name of the file).  However, if you
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
    <li><tt>vars</tt> (a list of Tcl vars to grab from the calling environment)
    </ul>

    <p>

    <tt>-rqset</tt> specifies an ns_set of extra headers to send to
    the server when doing the POST.

    <p>

    timeout, depth, and http_referer are optional, and are included
    as optional positional variables in the same order they are used
    in <tt>util_httppost</tt>.  NOTE: <tt>util_http_file_upload</tt> does
    not (currently) follow any redirects, so depth is superfluous.

    @author Michael A. Cleverly (michael@cleverly.com)
    @creation-date 3 September 2002

    @see util::http::post
} {

    # sanity checks on switches given
    if {$mode ni {formvars array ns_set vars}} {
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

        if {$mime_type eq "*/*" || $mime_type eq ""} {
            set mime_type [ns_guesstype $file]
        }
    }

    set boundary [ns_sha1 [list [clock clicks -milliseconds] [clock seconds]]]
    set payload {}

    if {[info exists data] && [string length $data]} {
        if {![info exists name]} {
            error "Cannot upload file without specifying form variable -name"
        }

        if {![info exists filename]} {
            error "Cannot upload file without specifying -filename"
        }

        if {$mime_type eq "*/*" || $mime_type eq ""} {
            set mime_type [ns_guesstype $filename]

            if {$mime_type eq "*/*" || $mime_type eq ""} {
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

        lassign [util_httpopen POST $url $rqset $timeout $http_referer] rfd wfd

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
            if { $line eq "" } break
            ns_parseheader $rpset $line
        }

        set headers $rpset
        set response [ns_set name $headers]
        set status [lindex $response 1]
        set length [ns_set iget $headers content-length]
        if { "" eq $length } { set length -1 }
        set type [ns_set iget $headers content-type]
        set_encoding $type $rfd
        set err [catch {
            while 1 {
                set buf [_ns_http_read $timeout $rfd $length]
                append page $buf
                if { "" eq $buf } break
                if {$length > 0} {
                    incr length -[string length $buf]
                    if {$length <= 0} break
                }
            }
        } errMsg]

        ns_set free $headers
        close $rfd

        if {$err} {
            return -code error -errorinfo $::errorInfo $errMsg
        }
    } errmsg] } {
        if {[info exists wfd] && $wfd in [file channels]} {
            close $wfd
        }

        if {[info exists rfd] && $rfd in [file channels]} {
            close $rfd
        }

        set page -1
    }

    return $page
}

########################################################################
# from tcl/community-core-procs.tcl
########################################################################

ad_proc -deprecated -private cc_lookup_screen_name_user { screen_name } {
    @see acs_user::get_user_id_by_screen_name
} {
    return [db_string user_select_screen_name {} -default {}]
}

ad_proc -deprecated cc_screen_name_user { screen_name } {

    @return Returns the user ID for a particular screen name, or an empty string
    if none exists.

    @see acs_user::get_user_id_by_screen_name

} {
    return [util_memoize [list cc_lookup_screen_name_user $screen_name]]
}

ad_proc -deprecated -private cc_lookup_email_user { email } {
    Return the user_id of a user given the email. Returns the empty string if no such user exists.
    @see party::get_by_email
} {
    return [db_string user_select {} -default {}]
}

ad_proc -public -deprecated cc_email_from_party { party_id } {
    @return The email address of the indicated party.
    @see party::email
} {
    return [db_string email_from_party {} -default {}]
}

ad_proc -deprecated cc_email_user { email } {

    @return Returns the user ID for a particular email address, or an empty string
    if none exists.

    @see party::get_by_email
} {
    return [util_memoize [list cc_lookup_email_user $email]]
}

ad_proc -deprecated -private cc_lookup_name_group { name } {
    @see group::get_id
} {
    return [db_string group_select {} -default {}]
}

ad_proc -deprecated cc_name_to_group { name } {

    Returns the group ID for a particular name, or an empty string
    if none exists.

    @see group::get_id
} {
    return [util_memoize [list cc_lookup_name_group $name]]
}

ad_proc -deprecated ad_user_new {
    email
    first_names
    last_name
    password
    password_question
    password_answer
    {url ""}
    {email_verified_p "t"}
    {member_state "approved"}
    {user_id ""}
    {username ""}
    {authority_id ""}
    {screen_name ""}
} {
    Creates a new user in the system.  The user_id can be specified as an argument to enable double click protection.
    If this procedure succeeds, returns the new user_id.  Otherwise, returns 0.

    @see auth::create_user
    @see auth::create_local_account
} {
    return [auth::create_local_account_helper \
		$email \
		$first_names \
		$last_name \
		$password \
		$password_question \
		$password_answer \
		$url \
		$email_verified_p \
		$member_state \
		$user_id \
		$username \
		$authority_id \
		$screen_name]
}

#
# from tcl/community-core-2-procs.tc
#


# The User Namespace
namespace eval oacs::user {

    ad_proc -deprecated -public get {
        {-user_id:required}
        {-array:required}
    } {
        Load up user information
	@see acs_user::get
    } {
        # Upvar the Tcl Array
        upvar $array row
        db_1row select_user {} -column_array row
    }

}

########################################################################
# from tcl/00-database-procs.tcl
########################################################################
#
ad_proc -deprecated db_package_supports_rdbms_p { db_type_list } {
    @return 1 if db_type_list contains the current RDMBS type.  A package intended to run with a given RDBMS must note this in its package info file regardless of whether or not it actually uses the database.

    @see apm_package_supports_rdbms_p
} {
    if { [lsearch $db_type_list [db_type]] != -1 } {
        return 1
    }

    # DRB: Legacy package check - we allow installation of old aD Oracle 4.2 packages,
    # though we don't guarantee that they work.

    if { [db_type] eq "oracle" && [lsearch $db_type_list "oracle-8.1.6"] != -1 } {
        return 1
    }

    return 0
}

########################################################################
#  from tcl/apm-procs.tcl
########################################################################


ad_proc -public -deprecated apm_doc_body_callback { string } {
    This callback uses the document API to append more text to the stream.
} {
    doc_body_append $string
}

########################################################################
#  from tcl/apm-file-procs.tcl
########################################################################


ad_proc -public -deprecated pkg_home {package_key} {

    @return A server-root relative path to the directory for a package.  Usually /packages/package-key
    @see acs_package_root_dir

} {
    return "/packages/$package_key"
}

########################################################################
# deprecated utilities-procs.tcl
########################################################################

# ad_library {
#
#     Provides a variety of non-ACS-specific utilities that have been
#     deprecated
#
#     Note the 5.2 deprecated procs have been moved to deprecated/5.2/acs-tcl
#
#     @author yon [yon@arsdigita.com]
#     @creation-date 9 Jul 2000
#     @cvs-id $Id$
# }

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

ad_proc -deprecated -warn set_variables_after_query {} {
    to be removed.


    @see packages/acs-tcl/tcl/00-database-procs.tcl
} {
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

ad_proc -deprecated -warn set_variables_after_subquery {} {
    to be removed.


    @see packages/acs-tcl/tcl/00-database-procs.tcl
} {
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

ad_proc -deprecated -warn set_variables_after_query_not_selection {selection_variable {name_prefix ""}} {
    to be removed.


    @see packages/acs-tcl/tcl/00-database-procs.tcl
} {
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


ad_proc -public -deprecated -warn ad_secure_conn_p {} {
    Use security::secure_conn_p instead.

    @see security::secure_conn_p
} {
    return [security::secure_conn_p]
}

ad_proc -public -deprecated ad_get_user_id {} {
    Gets the user ID. 0 indicates the user is not logged in.

    Deprecated since user_id now provided via ad_conn user_id

    @see ad_conn
} {
    return [ad_conn user_id]
}

ad_proc -public -deprecated -warn ad_verify_and_get_user_id {
    {-secure f}
} {
    Returns the current user's ID. 0 indicates user is not logged in

    Deprecated since user_id now provided via ad_conn user_id

    @see ad_conn
} {
    return [ad_conn user_id]
}

# handling privacy

ad_proc -public -deprecated ad_privacy_threshold {} {
    Pages that are consider whether to display a user's name or email
    address should test to make sure that a user's priv_ from the
    database is less than or equal to what ad_privacy_threshold returns.

    Now deprecated.

    @see  ad_conn
} {
    set session_user_id [ad_conn user_id]
    if {$session_user_id == 0} {
	# viewer of this page isn't logged in, only show stuff
	# that is extremely unprivate
	set privacy_threshold 0
    } else {
	set privacy_threshold 5
    }
    return $privacy_threshold
}

ad_proc -deprecated ad_maybe_redirect_for_registration {} {

    Checks to see if a user is logged in.  If not, redirects to
    [subsite]/register/index to require the user to register.
    When registration is complete, the user will return to the current
    location. All variables in ns_getform (both posts and gets) will
    be maintained. Note that this will return out of its caller so that
    the caller need not explicitly call "return". Returns the user id
    if login was successful.

    @see auth::require_login
} {
    auth::require_login
}

ad_proc -public -deprecated proc_doc { args } {

    A synonym for <code>ad_proc</code> (to support legacy code).

    @see ad_proc
} {
    ad_proc {*}$args
}

#
# GN: maybe this function was useful for ancient versions of Tcl, but
# unless i oversee something, it does not make any sense. The comment
# argues, that "return -code ..." ignores the error code, but then the
# function uses "return -code ..." to fix this...
#
ad_proc -deprecated ad_return { args } {

    Works like the "return" Tcl command, with one difference. Where
    "return" will always return TCL_RETURN, regardless of the -code
    switch this way, by burying it inside a proc, the proc will return
    the code you specify.

    <p>

    Why? Because "return" only sets the "returnCode" attribute of the
    interpreter object, which the function actually interpreting the
    procedure then reads and uses as the return code of the procedure.
    This proc adds just that level of processing to the statement.

    <p>

    When is that useful or necessary? Here:

    <pre>
    set errno [catch {
        return -code error "Boo!"
    } error]
    </pre>

    In this case, <code>errno</code> will always contain 2 (TCL_RETURN).
    If you use ad_return instead, it'll contain what you wanted, namely
    1 (TCL_ERROR).

} {
    return {*}$args
}

ad_proc -private -deprecated rp_handle_adp_request {} {

    Handles a request for an .adp file.

    @see adp_parse_ad_conn_file

} {
    doc_init

    set adp [ns_adp_parse -file [ad_conn file]]

    if { [doc_exists_p] } {
        doc_set_property body $adp
        doc_serve_document
    } else {
        set content_type [ns_set iget [ad_conn outputheaders] "content-type"]
        if { $content_type eq "" } {
            set content_type "text/html"
        }
        doc_return 200 $content_type $adp
    }
}

########################################################################
# deprecated site-nodes-procs.tcl
########################################################################

########################################################################
# deprecated party-procs.tcl
########################################################################

namespace eval party {

    ad_proc -deprecated -public permission_p {
        { -user_id "" }
        { -privilege "read" }
        party_id
    } {
        Wrapper for ad_permission to allow us to bypass having to
        specify the read privilege

        Deprecated: just another wrapper for permission::permission_p

        @author Michael Bryzek (mbryzek@arsdigita.com)
        @creation-date 10/2000

        @see permission::permission_p

    } {
        return [permission::permission_p -party_id $user_id -object_id $party_id -privilege $privilege]
    }

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
