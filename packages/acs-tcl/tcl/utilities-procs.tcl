ad_library {

    Provides a variety of non-ACS-specific utilities, including
    the procs to support the who's online feature.

    @author Various (acs@arsdigita.com)
    @creation-date 13 April 2000
    @cvs-id $Id$
}

#
# Namespace handling for the utilities is pretty arbitrary.
# We have currently
#   - ad_*
#   - util_*
#   - util::*
#   - oacs_util::*
#
namespace eval util {}
namespace eval oacs_util {}

ad_proc util::pdfinfo {
    file
} {
    Calls the pdfinfo command line utility on a given pdf file. The
    command pdfinfo must be installed on the server for this to
    work. On linux this is usually part of the poppler-utils
    (https://poppler.freedesktop.org/).

    @param file absolute path to the pdf file

    @return a dict containing all the pdfinfo returned fields as keys
            and their respective values
} {
    set pdfinfo [util::which pdfinfo]

    if {$pdfinfo eq ""} {
        error "the command 'pdfinfo' is not found on the system"
    }

    set retval [dict create]
    foreach line [split [exec $pdfinfo $file] \n] {
        lassign [split $line ":"] name value
        set name  [string trim $name]
        set value [string trim $value]
        dict set retval $name $value
    }

    return $retval
}

ad_proc util::zip {
    -source:required
    -destination:required
} {
    Create a zip file.

    @param source is the content to be zipped. If it is a directory, archive will
    contain all files into directory without the trailing directory itself.

    @param destination is the name of the created file
} {
    #
    # Split the source
    #
    if {[ad_file isfile $source]} {
        set filename [ad_file tail $source]
        set in_path  [ad_file dirname $source]
    } else {
        set filename "."
        set in_path  $source
    }

    #
    # Check if zipfile::mkzip, introduced in tcllib 1.18, is available.
    # Otherwise, use the legacy method calling an external zip command via exec.
    #
    if {![catch {package require zipfile::mkzip} version]} {
        ::zipfile::mkzip::mkzip $destination -directory $in_path $filename
    } else {
        set zip [util::which zip]
        if {$zip eq ""} {
            error "zip command not found on the system."
        }
        #
        # To avoid having the full path of the file included in the archive,
        # we must first cd to the source directory. zip doesn't have an option
        # to do this without building a little script...
        #
        set cmd [list exec]
        switch -- $::tcl_platform(platform) {
            windows {
                lappend cmd cmd.exe /c
                set zip_cmd [list]
                lappend zip_cmd "cd $in_path"
                lappend zip_cmd "${zip} -r \"${destination}\" \"${filename}\""
                set zip_cmd [join $zip_cmd " && "]
                lappend cmd $zip_cmd
            }
            default {
                #
                # Previous versions of this, for unix-like systems, used bash in
                # order to change directories before executing zip (see above).
                #
                # This method was problematic when using certain characters for
                # the filenames, such as backticks, for example.
                #
                # In order to avoid this and properly quote everything, we use
                # tclsh instead, in a convoluted and funny way.
                #
                # (Thanks to Nathan Coulter for the hack.)
                #
                # TODO: test this also on windows. It may work as well, and
                # potentially unify the two legacy implementations.
                #
                set tcl_shell [util::which tclsh]
                if {$tcl_shell eq ""} {
                    error "tclsh command not found on the system."
                }
                lappend cmd $tcl_shell -

                set script [
                    string map [
                        list @in_path@ [list $in_path] @zip@ [list $zip] @destination@ [list $destination] @filename@ [list $filename]
                    ] {
                        if {
                            [catch {
                                cd @in_path@
                                exec @zip@ -r @destination@ @filename@
                            } errorMsg eopts]
                        } {
                            puts "Error: [dict get $eopts -errorinfo]"
                            exit 1
                        }
                    }
                ]
                lappend cmd << $script
            }
        }

        # Create the archive
        {*}$cmd
    }
}

if {[info commands ns_valid_utf8] ne ""} {
    ad_proc -private ::util::zip_file_contains_valid_filenames {zip_fn} {

        Check, if the provided zip file contains only filenames with
        valid UTF-8 characters. Unfortunately, handling different
        character sets differs between variants of unzip (also between
        unzip between the redhat and debian families). For details
        about file structure of zip files, consult e.g.
        https://en.wikipedia.org/wiki/ZIP_(file_format)

        @return boolean
    } {
        set F [open $zip_fn rb]; set C [read $F]; close $F
        set validUTF8 1
        while {$validUTF8 && [binary encode hex [string range $C 0 3]] eq "504b0304"} {
            binary scan [string range $C 26 27] s fnSize
            binary scan [string range $C 28 29] s extraFieldSize
            set validUTF8 [ns_valid_utf8 [string range $C 30 29+$fnSize]]
            set C [string range $C [expr {30 + $fnSize + $extraFieldSize}] end]
        }
        return $validUTF8
    }
}

ad_proc util::unzip {
    -source:required
    -destination:required
    -overwrite:boolean
} {
    @param source must be the name of a valid zip file to be decompressed

    @param destination must be the name of a valid directory to contain decompressed files
} {
    set unzipCmd [util::which unzip]
    if {$unzipCmd eq ""} {
        error "unzip command not found on the system."
    }
    set extra_options ""
    #
    # Check, if the zip file contains filenames which are invalid
    # UTF-8 characters.
    #
    if {[info commands ::util::zip_file_contains_valid_filenames] ne ""
        && $::tcl_platform(os) eq "Linux"
        && ![::util::zip_file_contains_valid_filenames $source] } {
        #
        # The option "-O" works apparently only under Linux and might
        # depend on the version of "unzip". We assume here that the
        # broken characters are from Windows (code page 850)
        #
        lappend extra_options -O CP850
    }
    # -n means we don't overwrite existing files
    exec $unzipCmd {*}$extra_options [expr {$overwrite_p ? "-o" : "-n"}] $source -d $destination
}

ad_proc -deprecated util_report_library_entry {
    {extra_message ""}
} {
    Should be called at beginning of private Tcl library files so
    that it is easy to see in the error log whether or not
    private Tcl library files contain errors.

    DEPRECATED: this proc is a leftover from the past, OpenACS does
    inform about libraries being loaded in the logfile. If one needs a
    special statement for debugging purposes, a custom ns_log oneliner
    will do.

    @see ns_log
} {
    set tentative_path [info script]
    regsub -all -- {/\./} $tentative_path {/} scrubbed_path
    if { $extra_message eq ""  } {
        set message "Loading $scrubbed_path"
    } else {
        set message "Loading $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}

ad_proc -public util::get_referrer {
    -relative:boolean
    -trusted:boolean
} {
    @return referrer from the request headers.
    @param relative return the refer without protocol and host
} {
    set url [ns_set iget [ns_conn headers] Referer]
    #
    # Don't return untrusted header field when -trusted was
    # specified. An attacker might to sneak in e.g. a JavaScript URL.
    #
    if { $trusted_p && [util::external_url_p $url]} {
        ns_log warning "someone tried to sneak in an untrusted referrer '$url'"
        set url ""
    }
    if {$relative_p} {
        # In case the referrer URL has a protocol and host remove it
        regexp {^[a-z]+://[^/]+(/.*)$} $url . url
    }
    return $url
}


##
#  Database-related code
##



ad_proc -deprecated util_AnsiDatetoPrettyDate {
    sql_date
} {
    Converts 1998-09-05 to September 5, 1998

    DEPRECATED: this proc hardcodes the date format and the language
    to American English. Better alternatives exist in acs-lang.

    @see lc_time_fmt
} {
    set sql_date [string range $sql_date 0 9]
    if { ![regexp {(.*)-(.*)-(.*)$} $sql_date match year month day] } {
        return ""
    } else {
        set allthemonths {January February March April May June July August September October November December}

        set trimmed_month [string trimleft $month 0]
        set pretty_month  [lindex $allthemonths $trimmed_month-1]
        set trimmed_day   [string trimleft $day 0]

        return "$pretty_month $trimmed_day, $year"
    }
}

ad_proc -public util_remove_nulls_from_ns_set {
    old_set_id
} {
    Creates and returns a new ns_set without any null value fields

    @return new ns_set
} {
    set new_set_id [ns_set new "no_nulls$old_set_id"]

    foreach {key value} [ns_set array $old_set_id] {
        if { $value ne "" } {
            ns_set put $new_set_id $key $value
        }
    }

    return $new_set_id
}

ad_proc -public util::random_init {seed} {
    Seed the random number generator.
} {
    nsv_set rand ia 9301
    nsv_set rand ic 49297
    nsv_set rand im 233280
    nsv_set rand seed $seed
}

ad_proc -public util::random {} {
    Return a pseudo-random number between 0 and 1. The reason to have
    this proc is that seeding can be controlled by the user and the
    generation is independent of Tcl.

    @see util::random_init
} {
    nsv_set rand seed [expr {([nsv_get rand seed] * [nsv_get rand ia] + [nsv_get rand ic]) % [nsv_get rand im]}]
    return [expr {[nsv_get rand seed]/double([nsv_get rand im])}]
}

ad_proc -public util::random_range {range} {
    Returns a pseudo-random number between 0 and range.

    @return integer
} {
    incr range
    return [expr {int([util::random] * $range) % $range}]
}

ad_proc -public db_html_select_options {
    { -bind "" }
    { -select_option "" }
    stmt_name
    sql
} {

    Generate html option tags for an HTML selection widget. If select_option
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

    Generate html option tags with values for an HTML selection widget. If
    select_option is passed and there exists a value for it in the values
    list, this option will be marked as selected. The "select_option" can be
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
    -no_base_encode:boolean
    {-anchor}
    {-exclude {}}
    {-override {}}
    {-set {}}
    {-formvars {}}
    {vars {}}
} {

    Exports variables either as a URL or in the form of hidden form
    variables. The result is properly urlencoded, unless flags
    prohibit this.

    <p>
    Example usage: <code>set html [export_vars -form { foo bar baz }]</code><br>
    <code>set url [export_vars { foo bar baz }]</code>

    <p>
    This will export the three variables <code>foo</code>,
    <code>bar</code> and <code>baz</code> as hidden HTML form
    fields. It does exactly the same as <code>[export_vars -form {foo
    bar baz}]</code>.

    <p>
    Example usage: <code>[export_vars -sign -override {{foo "new value"}} -exclude { bar } { foo bar baz }]</code>

    <p>

    This will export a variable named <code>foo</code> with the value
    "new value" and a variable named <code>baz</code> with the value
    of <code>baz</code> in the caller's environment. Since we've
    specified that <code>bar</code> should be excluded,
    <code>bar</code> won't get exported even though it's specified in
    the last argument. Additionally, even though <code>foo</code> is
    specified also in the last argument, the value we use is the one
    given in the <code>override</code> argument. Finally, both
    variables are signed, because we specified the <code>-sign</code>
    switch.

    <p>

    You can specify variables with <b>three different precedences</b>,
    namely <b><code>override</code>, <code>exclude</code> or
    <code>vars</code></b>. If a variable is present in
    <code>override</code>, that's what'll get exported, no matter
    what. If a variable is in <code>exclude</code> and not in
    <code>override</code>, then it will <em>not</em> get
    output. However, if it is in <code>vars</code> and <em>not</em> in
    either of <code>override</code> or <code>exclude</code>, then
    it'll get output. In other words, we check <code>override</code>,
    <code>exclude</code> and <code>vars</code> in that order of
    precedence.

    <p>

    The two variable specs, <b><code>vars</code> and
    <code>override</code></b> both look the same: They take a list of
    variable specs. Examples of variable specs are:

    <ul>
    <li>foo
    <li>foo:multiple,sign
    <li>{foo "the value"}
    <li>{foo {[my_function arg]}}
    <li>{foo:array,sign {[array get my_array]}}
    </ul>

    In general, there's one or two elements. If there are two, the
    second element is the value we should use. If one, we pull the
    value from the variable of the same name in the caller's
    environment. Note that when you specify the value directly here,
    we call the Tcl command subst on it, so backslashes, square
    brackets and variables will get substituted correctly. Therefore,
    make sure you use curly braces to surround this instead of the
    <code>[list]</code> command; otherwise the contents will get
    substituted twice, and you'll be in trouble.

    <p>

    Right after the name, you may specify a colon and some flags,
    separated by commas. Valid flags are:

    <dl>

    <dt><b>multiple</b></dt>
    <dd>
    Treat the value as a list and output each element separately.
    </dd>

    <dt><b>array</b></dt>
    <dd>

    The value is an array and should be exported in a way compliant
    with the <code>:array</code> flag of <a
    href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>,
    which means that each entry will get output as
    <code>name.key=value</code>.

    <p> If you don't specify a value directly, but want it pulled out
    of the Tcl environment, then you don't need to specify
    <code>:array</code>. If you do, and the variable is in fact not an
    array, an error will be thrown.  <p>

    </dd>

    <dt><b>sign</b></dt>
    <dd>

    Sign this variable. This goes hand-in-hand with the
    <code>:verify</code> flag of <a
    href="/api-doc/proc-view?proc=ad_page_contract"><code>ad_page_contract</code></a>
    and makes sure that the value isn't tampered with on the client
    side. The <code>-sign</code> switch to <code>export_vars</code>,
    is a short-hand for specifying the <code>:sign</code> switch on
    every variable.

    <p> For example, one can use "user_id:sign(max_age=60)" in
    export_vars to let the exported variable after 60 seconds.  Other
    potential arguments for sign are "user" or "csrf" to bind the
    signature to a user or to the CSRF token.

    </dd>

    </dl>

    The argument <b><code>exclude</code></b> simply takes a list of
    names of variables that you don't want exported, even though
    they're specified in <code>vars</code>.

    <p>

    <b>Intended use:</b> A page may have a set of variables that it
    cares about. You can store this in a variable once and pass that
    to <code>export_vars</code> like this:

    <p><blockquote>
    <code>set my_vars { user_id sort_by filter_by  }<br>
    ... [export_vars $my_vars] ...</code>
    </blockquote><p>

    Then, say one of them contains a column to filter on. When you
    want to clear that column, you can say <code>[export_vars -exclude
    { filter_by } $my_vars]</code>.

    <p>

    Similarly, if you want to change the sort order, you can say
    <code>[export_vars -override { { sort_by $column } }
    $my_vars]</code>, and sorting will be done according to the new
    value of <code>column</code>.

    <p>

    If the variable name contains a colon (:), that colon must be
    escaped with a backslash, so for example "form:id" becomes
    "form\:id". Sorry.

    @param sign Sign all variables.

    @param url Export in URL format. This is the default.

    @param form Export in form format. You can't specify both URL and
    form format.

    @param quotehtml HTML quote the entire resulting string. This is
    an interim solution while we're waiting for the templating system
    to do the quoting for us.

    @param entire_form Export the entire form from the GET query
    string or the POST.

    @option no_empty If specified, variables with an empty string
    value will be suppressed from being exported.  This avoids
    cluttering up the URLs with lots of unnecessary variables.

    @option base The base URL to make a link to. The provided value
    should be a plain value (i.e. urldecoded). In case the provided
    value is urlencoded, use the flag "-no_base_encode". The value of
    this parameter will be prepended to the query string along with a
    question mark (?), if the query is nonempty. The returned string
    can be used directly in a link (when output is in URL format).

    @option no_base_encode Decides whether argument passed as
                           <code>base</code> option will be encoded by
                           ad_urlencode_url proc

    @param set an ns_set that we want to export together with our
               variables. It has no effect when also the '-entire_form'
               flag is specified and will otherwise behave as if the
               current request form data was the supplied ns_set.

    @param formvars a list of parameters that will be looked up into
                    the current request and exported. Won't have any
                    effect if '-entire_form' or '-set' are specified
                    and will otherwise behave as if the current
                    request form data was a subset of the whole form
                    containing only the selected variables.

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
    # should be the straightforward source for the generation of the
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
        #
        # We are exporting all of the request's variables.
        #
        set the_form [ns_getform]
    } elseif { $set ne "" } {
        #
        # We are exporting a custom ns_set
        #
        set the_form $set
    } elseif { $formvars ne "" } {
        #
        # We are exporting a subset of the request's variables.
        #
        set the_form [ns_set create]
        foreach var $formvars {
            if {[ns_queryexists $var]} {
                ns_set put $the_form $var [ns_queryget $var]
            }
        }
    } else {
        #
        # We won't export any ns_set
        #
        set the_form ""
    }

    # Note that ns_getform will return the empty string outside a
    # connection.
    if { $the_form ne "" } {
        foreach {varname varvalue} [ns_set array $the_form] {
            lappend noprocessing_vars [list $varname $varvalue]
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
                regsub -all -- {\\:} $var_spec "!!cOlOn!!" var_spec

                set name_spec [split [lindex $var_spec 0] ":"]

                # Replace escaped colons with single colon
                regsub -all -- {!!cOlOn!!} $name_spec ":" name_spec

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
                        set exp_flag($name:sign) ""
                    }

                    if { [llength $var_spec] > 1 } {
                        if { $precedence_type ne "noprocessing_vars" } {
                            #if {[util::potentially_unsafe_eval_p -- [lindex $var_spec 1]]} {
                            #    ad_log warning "potentially_unsafe_eval in variable/value pair $var_spec"
                            #}
                            set value [uplevel [list subst [lindex $var_spec 1]]]
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

    set export_string {}

    if { $url_p } {
        foreach {key value} [ns_set array $export_set] {
            lappend export_string [ad_urlencode_query $key]=[ad_urlencode_query $value]
        }
        set export_string [join $export_string "&"]
    } else {
        foreach {key value} [ns_set array $export_set] {
            append export_string [subst {<div><input type="hidden"
                name="[ns_quotehtml $key]"
                value="[ns_quotehtml $value]"></div>
            }]
        }
    }

    if { $quotehtml_p } {
        set export_string [ns_quotehtml $export_string]
    }

    # Prepend with the base URL
    if { [info exists base] && $base ne "" } {
        set base [string trimright $base "?"]
        if { [string first ? $base] > -1 } {
            # The base already has query vars; assume that the
            # path up to this point is already correctly encoded.
            set export_string $base[expr {$export_string ne "" ? "&$export_string" : ""}]
        } else {
            # The base has no query vars: encode URL part if not
            # explicitly said otherwise. Include also as exception
            # trivial case of the base being the dummy url '#'.
            if {!$no_base_encode_p && $base ne "#"} {
                set base [ad_urlencode_url $base]
            }
            set export_string $base[expr {$export_string ne "" ? "?$export_string" : ""}]
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
    set user_binding 0
    set secret  [ns_config "ns/server/[ns_info server]/acs" parametersecret ""]
    foreach {key val} [ns_set array [ns_parsequery $params]] {
        switch -- $key {
            max_age -
            secret {
                set $key $val
            }
            user {
                if {$user_binding == 0} {
                    set user_binding -1
                } else {
                    ns_log warning "can't overrode sign(user) with sign(nonce)"
                }
            }
            csrf {
                if {$user_binding == 0} {
                    set user_binding -2
                } else {
                    ns_log warning "can't overrode sign(user) with sign(nonce)"
                }
            }
            default {
                #
                # It seems, there are several cases, where
                # "export_vars_sign" is called with invalid params
                # (which can be seemingly ignored:
                #
                ns_log warning  "export_vars_sign: invalid value '$key' in sign() specification (params <$params>, key=<$key>)"
                #error "invalid value '$key' in sign() specification"

            }
        }
    }

    return [ad_sign -max_age $max_age -secret $secret -binding $user_binding $value]
}


ad_proc -deprecated export_entire_form {} {

    Exports everything in ns_getform to the ns_set.  This should
    generally not be used. It's much better to explicitly name
    the variables you want to export.

    export_vars is now the preferred interface.

    @see export_vars
} {
    set hidden ""
    set the_form [ns_getform]
    if { $the_form ne "" } {
        foreach {varname varvalue} [ns_set array $the_form] {
            append hidden "<input type=\"hidden\" name=\"[ns_quotehtml $varname]\" value=\"[ns_quotehtml $varvalue]\" >\n"
        }
    }
    return $hidden
}

ad_proc -deprecated export_ns_set_vars {
    {format "url"}
    {exclusion_list ""}
    {setid ""}
} {
    Returns all the params in an ns_set with the exception of those in
    exclusion_list. If no setid is provide, ns_getform is used. If
    format = url, a URL parameter string will be returned. If format = form, a
    block of hidden form fragments will be returned.

    export_vars is now the preferred interface.

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
        foreach {name value} [ns_set array $setid] {
            if {$name ni $exclusion_list && $name ne ""} {
                if {$format eq "url"} {
                    lappend return_list "[ad_urlencode_query $name]=[ad_urlencode_query $value]"
                } else {
                    lappend return_list " name=\"[ns_quotehtml $name]\" value=\"[ns_quotehtml $value]\""
                }
            }
        }
    }
    if {$format eq "url"} {
        return [join $return_list "&"]
    } else {
        return "<div><input type='hidden' [join $return_list " ></div>\n <div><input type='hidden' "] ></div>"
    }
}


ad_proc -deprecated export_entire_form_as_url_vars {
    {vars_to_passthrough ""}
} {
    export_vars is now the preferred interface.

    Returns a URL parameter string of name-value pairs of all the form
    parameters passed to this page. If vars_to_passthrough is given, it
    should be a list of parameter names that will be the only ones passed
    through.

    @see export_vars
} {
    set params [list]
    set the_form [ns_getform]
    if { $the_form ne "" } {
        foreach {varname varvalue} [ns_set array $the_form] {
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

ad_proc -deprecated util_get_current_url {} {
    Returns a URL for re-issuing the current request, with query variables.
    If a form submission is present, that is converted into query vars as well.

    DEPRECATED: ad_return_url is a complete replacement for this API
    that also allows better control over the behavior.

    @see ad_return_url

    @return URL for the current page

    @author Lars Pind (lars@pinds.com)
    @creation-date February 11, 2003
} {
    set url [ad_conn url]

    set query [ns_getform]
    if { $query ne "" } {
        append url ?[export_vars -url -entire_form]
    }

    return $url
}


# putting commas into numbers (thank you, Michael Bryzek)

ad_proc -deprecated util_commify_number { num } {
    Returns the number with commas inserted where appropriate. Number can be
    positive or negative and can have a decimal point.
    e.g. -1465.98 => -1,465.98

    DEPRECATED: this proc has been long superseded by lc_numeric,
    which also supports different locales and formats.

    @see lc_numeric
} {
    while { 1 } {
        # Regular Expression taken from Mastering Regular Expressions (Jeff Friedl)
        # matches optional leading negative sign plus any
        # other 3 digits, starting from end.
        if { ![regsub -- {^(-?[0-9]+)([0-9][0-9][0-9])} $num {\1,\2} num] } {
            break
        }
    }
    return $num
}

ad_proc -deprecated util_report_successful_library_load {
    {extra_message ""}
} {
    Should be called at end of private Tcl library files so that it is
    easy to see in the error log whether or not private Tcl library
    files contain errors.

    DEPRECATED: this proc is a leftover from the past, OpenACS does
    inform about libraries being loaded in the logfile. If one needs a
    special statement for debugging purposes, a custom ns_log oneliner
    will do.

    @see ns_log
} {
    set tentative_path [info script]
    regsub -all -- {/\./} $tentative_path {/} scrubbed_path
    if { $extra_message eq ""  } {
        set message "Done... $scrubbed_path"
    } else {
        set message "Done... $scrubbed_path; $extra_message"
    }
    ns_log Notice $message
}


# Some procs to make it easier to deal with CSV files (reading and writing)
# added by philg@mit.edu on October 30, 1999

ad_proc util_escape_quotes_for_csv {string} {
    Returns its argument with double quote replaced by backslash double quote
} {
    regsub -all \" $string {\"}  result

    return $result
}

ad_proc -public oacs_util::process_objects_csv {
    {-object_type:required}
    {-file:required}
    {-header_line 1}
    {-override_headers {}}
    {-constants ""}
} {

    This processes a comma separated set of objects, taking the CSV
    and calling package_instantiate_object for each one.

    @return a list of the created object_ids
} {
    # FIXME: We should catch the error here
    set csv_stream [open $file r]

    # Check if there are headers
    if {$override_headers ne ""} {
        set headers $override_headers
    } else {
        if {!$header_line} {
            return -code error "There is no header!"
        }

        # get the headers
        ns_getcsv $csv_stream headers
    }

    set list_of_object_ids [list]

    # Process the file
    db_transaction {
        while {1} {
            # Get a line
            set n_fields [ns_getcsv $csv_stream one_line]

            # end of things
            if {$n_fields == -1} {
                break
            }

            # ignore empty lines
            if {$n_fields == 0} {
                continue
            }

            # Process the row
            set extra_vars [ns_set create]
            for {set i 0} {$i < $n_fields} {incr i} {
                set varname [string tolower [lindex $headers $i]]
                set varvalue [lindex $one_line $i]

                # Set the value
                ns_log debug "oacs_util::process_objects_csv: setting $varname to $varvalue"
                ns_set put $extra_vars $varname $varvalue
            }

            # Add in the constants
            if {$constants ne ""} {
                # This modifies extra_vars, without touching constants
                ns_set merge $constants $extra_vars
            }

            # Create object and go for it
            set object_id [package_instantiate_object -extra_vars $extra_vars $object_type]
            lappend list_of_object_ids $object_id

            # Clean Up
            ns_set free $extra_vars
        }
    }

    close $csv_stream

    # Return the list of objects
    return $list_of_object_ids
}

ad_proc -public oacs_util::csv_foreach {
    {-file:required}
    {-header_line 1}
    {-override_headers {}}
    {-array_name:required}
    code_block
} {
    Reads a CSV string and executes code block for each row in the CSV.

    @param file the CSV file to read.
    @param header_line the line with the list of var names
    @param override_headers the list of variables in the CSV
    @param array_name the name of the array to set with the values from the CSV as each line is read.
} {
    set csv_stream [open $file r]

    # Check if there are headers
    if {$override_headers ne ""} {
        set headers $override_headers
    } else {
        if {!$header_line} {
            return -code error "There is no header!"
        }

        # get the headers
        ns_getcsv $csv_stream headers
    }

    # provide access to errorCode

    # Upvar Magic!
    upvar 1 $array_name row_array

    while {1} {
        # Get a line
        set n_fields [ns_getcsv $csv_stream one_line]

        # end of things
        if {$n_fields == -1} {
            break
        }

        # Process the row
        for {set i 0} {$i < $n_fields} {incr i} {
            set varname [string tolower [lindex $headers $i]]
            set varvalue [lindex $one_line $i]
            set row_array($varname) $varvalue
        }

        # Now we are ready to process the code block
        set errno [catch { uplevel 1 $code_block } error]

        if {$errno > 0} {
          close $csv_stream
        }

        # handle error, return, break, continue
        # (source: https://wiki.tcl-lang.org/unless last case)
        switch -exact -- $errno {
            0   {}
            1   {return -code error -errorinfo $::errorInfo \
                     -errorcode $::errorCode $error}
            2   {return $error}
            3   {break}
            4   {}
            default     {return -code $errno $error}
        }
    }
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
    set headers [ad_conn outputheaders]
    ns_set put $headers Server "[ns_info name]/[ns_info version]"
    foreach {key value} [ns_set array $headers] {
        append headers_so_far "$key: $value\r\n"
    }
    append entire_string_to_write $headers_so_far "\r\n" $first_part_of_page
    ns_write $entire_string_to_write
}

ad_proc -public util_return_headers {
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
        append content_type "; charset=[ns_config ns/parameters OutputCharset utf-8]"
    }

    if {[ns_info name] eq "NaviServer"} {
        set binary [expr {$text_p ? "" : "-binary"}]
        ns_headers {*}$binary 200 $content_type {*}$content_length
    } else {
        if {$content_length ne ""} {
            ns_set put [ns_conn outputheaders] "Content-Length" $content_length
        }
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
    util_return_headers $content_type
    if { $first_part_of_page ne "" } {
        ns_write $first_part_of_page
    }
}

ad_proc -deprecated ad_apply {func arglist} {
    Evaluates the first argument with ARGLIST as its arguments, in the
    environment of its caller. Analogous to the Lisp function of the same name.

    DEPRECATED: modern Tcl can achieve the same result simply by
    expanding a list as arguments of a command.

    @see {*}
} {
    set func_and_args [concat $func $arglist]
    return [uplevel $func_and_args]
}

ad_proc -public ad_safe_eval args {

    Version of "eval" that checks its arguments for brackets that may be
    used to execute unsafe code. There are actually better ways in Tcl
    to achieve this, but it is kept for backwards compatibility.

} {
    foreach arg $args {
        if { [string match {*[\[;]*} $arg] } {
            return -code error "Unsafe argument to ad_safe_eval: $arg"
        }
    }
    return [uplevel {*}$args]
}

ad_proc -public ad_decode { value args } {

    This procedure is analogous to sql decode procedure. The first parameter is
    the value we want to decode. This parameter is followed by a list of
    pairs where first element in the pair is convert from value and second
    element is convert to value. The last value is default value, which will
    be returned in the case convert from values matches the given value to
    be decoded.

    Note that in most cases native Tcl idioms such as expr or switch
    will do the trick. This proc CAN make sense when one has many
    alternatives to decode, as in such cases a switch statement would
    not be as compact.

    <p>Good usage:<br>
    <code>ad_decode $value f Foo b Bar d Dan s Stan l Lemon m Melon
    Unknown</code><br> ---> a oneliner as opposed to a long switch statement<br>

    <p>Bad usage:<br>
    <code>ad_decode $boolean_p t 0 1</code><br>---> just use <code>expr {!$boolean_p}</code>

    @param value input value
    @return matched value or default
} {
    set num_args [llength $args]
    if {$num_args % 2 == 1} {
        set default [lindex $args end]
        set map [lrange $args 0 end-1]
    } else {
        set default ""
        set map $args
    }
    if {[dict exists $map $value]} {
        return [dict get $map $value]
    } else {
        return $default
    }
}

ad_proc -public ad_urlencode { string } {
    same as ns_urlencode except that dash and underscore are left unencoded.
} {
    set encoded_string [ns_urlencode $string]
    regsub -all -- {%2d} $encoded_string {-} encoded_string
    regsub -all -- {%5f} $encoded_string {_} ad_encoded_string
    return $ad_encoded_string
}

ad_proc -public ad_urlencode_url {url} {
    Perform an urlencode operation on a potentially full url
    (containing a location, but without query part).
    @see ad_urlencode_folder_path
} {
    ad_try {
        #
        # Assign the components, and check if the URL is valid
        #
        set components [ns_parseurl $url]
    } on ok {r} {
        #
        # Assume the possibility that older ns_parseurl versions accepted a URL
        # without a scheme.
        #
        if {[dict exists $components proto]} {
            set result [util::join_location \
                            -proto [dict get $components proto] \
                            -hostname [dict get $components host] \
                            -port [expr {[dict exists $components port] ? [dict get $components port] : ""}] \
                           ]
            set path [dict get $components path]
            if {$path ne ""} {
                set path /$path
            }
            set tail [dict get $components tail]
            append result [ad_urlencode_folder_path $path/$tail]
        } else {
            #
            # No protocol, we encode it as a path
            #
            set result [ad_urlencode_folder_path $url]
        }
    } on error {errorMsg} {
        #
        # If the URL is not strictly valid, at least we try to encode it as a
        # path.
        #
        set result [ad_urlencode_folder_path $url]
    }
    return $result
}


ad_proc -private ad_run_scheduled_proc { proc_info } {
    Runs a scheduled procedure and updates monitoring information in the shared variables.
} {
    if {[ns_info name] eq "NaviServer"} {
        set proc_info [lindex $proc_info 0]
    }

    #
    # Grab information about the scheduled procedure.
    #
    lassign $proc_info thread once interval proc args time . debug
    set count 0

    ad_mutex_eval [nsv_get ad_procs mutex] {
        set procs [nsv_get ad_procs .]

        #
        # Find the entry in the shared variable by comparing at the first
        # five fields. Then delete this entry from the jobs. It might be
        # added again after this loop with a fresh count and timestamp,
        # when "once" is false.
        #
        # It would be much better to use e.g. a dict with some proper keys
        # instead.
        #
        for { set i 0 } { $i < [llength $procs] } { incr i } {
            set other_proc_info [lindex $procs $i]
            for { set j 0 } { $j < 5 } { incr j } {
                if { [lindex $proc_info $j] ne [lindex $other_proc_info $j] } {
                    break
                }
            }

            #
            # When the entry was found ($j == 5) get the "count" and
            # delete the entry.
            #
            if { $j == 5 } {
                set count [lindex $other_proc_info 6]
                set procs [lreplace $procs $i $i]
                break
            }
        }

        if { $once == "f" } {
            #
            # The proc will run again - add it again to the shared
            # variable (updating ns_time and incrementing the count).
            #
            lappend procs [list $thread $once $interval $proc $args [ns_time] [expr { $count + 1 }] $debug]
        }
        nsv_set ad_procs . $procs
    }

    ns_log notice "Running scheduled proc $proc {*}$args..."

    # Actually run the procedure.
    if {$proc ne ""} {
        $proc {*}$args
    }

    ns_log debug "Done running scheduled proc $proc."

    #
    # In case there are temporary XOTcl objects, clean these up to
    # avoid surprises in schedued threads about pre-existing objects.
    #
    if {[namespace which ::xo::at_cleanup] ne ""} {
        ::xo::at_cleanup
    }
}

# Initialize NSVs for ad_schedule_proc.
if { [apm_first_time_loading_p] } {
    nsv_set ad_procs mutex [ns_mutex create oacs:sched_procs]
    nsv_set ad_procs . ""
}

ad_proc -public ad_schedule_proc {
    {-thread t}
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

    @param thread t/f If true run scheduled proc in its own thread.
       Note that when scheduled procs executed in the main thread
       these procs can delay processing of other scheduled procs for
       a potentially long time, no other jobs will be scheduled.
       If scheduled procs should be running at certain times, it is
       highly recommended to run all scheduled procs in separate
       (job execution) thread and use the main scheduled thread
       mainly for scheduling.
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
    #
    # Don't schedule a proc to run if
    # - we have enabled server clustering,
    # - and we're not the canonical server,
    # - and the procedure was not requested to run on all servers.
    #
    if { [server_cluster_enabled_p] && ![ad_canonical_server_p] && $all_servers == "f" } {
        return
    }

    set proc_info [list $thread $once $interval $proc $args [ns_time] 0 $debug]
    ns_log debug "Scheduling proc $proc"

    # Add to the list of scheduled procedures, for monitoring.
    nsv_lappend ad_procs . $proc_info

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

# Brad Duell (bduell@ncacasi.org) 07/10/2003
# User session variables, then redirect
ad_proc -public ad_cache_returnredirect {
    url
    { persistent "f" }
    { excluded_vars "" }
} {
    An addition to ad_returnredirect.  It caches all variables in the
    redirect except those in excluded_vars and then calls
    ad_returnredirect with the resultant string.

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
            append excluded_vars_url [export_vars {{"$item" "$value"}}]
        }
    }

    set saved_list ""
    if { $vars ne "" } {
        foreach {item value} [ns_set array [ns_parsequery $vars]] {
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
    Write the HTTP response required to get the browser to redirect to
    a different page, to the current connection. This does not cause
    execution of the current page, including serving an ADP file, to
    stop. If you want to stop execution of the page, you should call
    ad_script_abort immediately following this call.

    <p>

    This proc is a replacement for ns_returnredirect, but improved in
    two important respects:
    <ul>
    <li>
    When the supplied target_url isn't complete, (e.g. /foo/bar.tcl or
    foo.tcl) the prepended location part is constructed by looking at
    the HTTP 1.1 Host header.
    </li>
    <li>
    If a URL relative to the current directory is supplied
    (e.g. foo.tcl) it prepends location and directory.
    </li>
    </ul>

    @param message A message to display to the user. See
                   util_user_message.

    @param html Set this flag if your message contains HTML. If
                specified, you're responsible for proper quoting of
                everything in your message. Otherwise, we quote it for
                you.

    @param allow_complete_url By default we disallow redirecting to
                              URLs outside the current host. This is
                              based on the currently set host header
                              or the hostname in the config file if
                              there is no host header. Set
                              allow_complete_url if you are
                              redirecting to a known safe external web
                              site. This prevents redirecting to a
                              site by URL query hacking.

    @see util_user_message
    @see ad_script_abort
} {
    if {$message ne ""} {
        #
        # Leave a hint, that we do not want to be consumed on the
        # current page.
        #
        set ::__skip_util_get_user_messages 1
        util_user_message -message $message -html=$html_p
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
        set url [util_current_location][ad_urlencode_folder_path [util_current_directory]]
        if {$target_url ne "."} {
            append url $target_url
        }
    }

    # Sanitize URL to avoid potential injection attack
    regsub -all -- {[\r\n]} $url "" url

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
    if {$replace_p} {
        set messages [list]
    } else {
        set messages [ad_get_client_property -default {} -cache_only t "acs-kernel" "general_messages"]
    }
    if { $message ne "" } {
        if { !$html_p } {
            set message [ns_quotehtml $message]
        }
        dict incr messages $message
    }
    ad_set_client_property -persistent f "acs-kernel" "general_messages" $messages
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
        ad_set_client_property -persistent f "acs-kernel" "general_messages" {}
    }
    template::multirow create $multirow message
    foreach {message count} $messages {
        if {$count > 1} {
            append message " ($count)"
        }
        template::multirow append $multirow $message
    }
}

ad_proc -public util_complete_url_p {string} {
    Determine whether string is a complete URL, i.e.
    whether it begins with protocol: where protocol
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
    {-array}
    {-driver ""}
} {
    Returns the protocol and port for the specified (or current) driver.

    @param driver the driver to query (defaults to [ad_conn driver])
    @param array the array to populate with proto, address and port

    @see security::configured_driver_info
} {

    if {$driver eq ""} {
        set driver [ad_conn driver]
    }

    set section [ns_driversection -driver $driver]

    switch -glob -- $driver {
        nsudp* -
        nssock* {
            set d [list proto http port [ns_config -int $section Port] address [ns_config $section address]]
        }
        nsunix {
            set d [list proto http port "" address ""]
        }
        nsssl* - nsssle {
            set d [list proto https port [ns_config -int $section Port] address [ns_config $section address]]
        }
        nsopenssl {
            set d [list proto https port [ns_config -int $section ServerPort] address [ns_config $section address]]
        }
        default {
            #ns_log notice "Unknown driver: [ad_conn driver]. Only know nssock, nsunix, nsssl, nsssle, nsopenssl"
            set d [list proto http port [ns_config -int $section Port] address [ns_config $section address]]
        }
    }
    lappend d hostname [ns_config $section hostname]

    if {[info exists array]} {
        upvar $array result
        array set result $d
    }
    return $d
}

ad_proc util::split_host {hostspec hostnameVar portVar} {
    Split host potentially into a hostname and a port
} {
    upvar $hostnameVar hostname $portVar port
    if {![regexp {^(.*):(\d+)$} $hostspec . hostname port]} {
        set port ""
        set hostname $hostspec
    }
    regexp {^\[(.+)\]$} $hostname . hostname
}

ad_proc util::split_location {location protoVar hostnameVar portVar} {

    Split the provided location into "proto", "hostname" and "port".
    The results are returned on success to the provided output
    variables.  The function supports IP-literal notation according to
    RFC 3986 section 3.2.2.

    @author Gustaf Neumann
    @return boolean value indicating success
    @see util::join_location
} {
    upvar $protoVar proto $hostnameVar hostname $portVar port

    try {
        set urlInfo [ns_parseurl $location]
    } on error {errorMsg} {
        #
        # Here we cannot use "ad_log warning", since it calls
        # "split_location" leading potentially in some error cases to
        # a recursive loop (call path "ad_log warning",
        # "util::request_info -with_headers...",
        # "util_current_location", "security::validated_host_header"
        # "util::split_location"). Therefore, we are using here the a
        # simplified version just printing the header fields.
        #
        set msg "cannot parse URL '$location': $errorMsg"
        if {[ns_conn isconnected]} {
            append msg \
                \n [ns_conn request] \
                \n [util::ns_set_pretty_print [ns_conn headers]]
        }
        ns_log warning $msg
        set success 0
    } on ok {result} {
        if {[dict exists $urlInfo proto] && [dict exists $urlInfo host]} {
            set proto [dict get $urlInfo proto]
            set hostname [dict get $urlInfo host]
            if {[dict exists $urlInfo port]} {
                set port [dict get $urlInfo port]
            } else {
                set port [dict get {http 80 https 443} $proto]
            }
            set success 1
        } else {
            set success 0
        }
    }
    return $success
}

ad_proc util::join_location {{-proto ""} {-hostname} {-port ""}} {
    Join hostname and port and use IP-literal notation when necessary.
    The function is the inverse function of  util::split_location.
    @return location consisting of hostname and optionally port
    @author Gustaf Neumann
    @see util::split_location
} {
    set result ""
    if {$proto ne ""} {
        append result $proto://
        #
        # When the specified port is equal to the default port, omit
        # it from the result.
        #
        if {$port ne "" && $port eq [dict get {http 80 https 443} $proto]} {
            set port ""
        }
    }
    if {[string match *:* $hostname]} {
        append result "\[$hostname\]"
    } else {
        append result $hostname
    }
    if {$port ne ""} {
        append result :$port
    }
    return $result
}

ad_proc -public util::configured_location {{-suppress_port:boolean}} {

    Return the configured location as configured for the current
    network driver. While [util_current_location] honors the virtual
    host information of the host header field,
    util::configured_location returns the main configured location
    (probably the main subsite). This also differs from [ad_url],
    which returns always the same value from the kernel parameter,
    since it returns either the https or http result.

    @return the configured location in the form "proto://hostname?:port?"

    @see ad_url
    @see util_current_location
} {
    set driver_info [util_driver_info]
    return [util::join_location \
                -proto    [dict get $driver_info proto] \
                -hostname [dict get $driver_info hostname] \
                -port     [expr {$suppress_port_p ? "" : [dict get $driver_info port]}]]
}

ad_proc -public util_current_location {} {

    This function behaves like [ad_conn location], since it returns
    the location string of the current request in the form
    protocol://hostname?:port? but it honors the "Host:" header field
    (when the client addressed the server with a hostname different
    to the default one from the server configuration file) and
    therefore as well the host-node mapping.  If the "Host" header
    field is missing or empty this function falls back to [ad_conn
    location].

    @return the current location in the form "protocol://hostname?:port?"

    @see util::configured_location
    @see ad_url
    @see ad_conn
} {

    #
    # Compute util_current_location only once per request and cache
    # the result per thread.
    #
    if {[info exists ::__util_current_location]} {
        return $::__util_current_location
    }

    #
    # In case we have no connection return the location based on the
    # configured kernel parameters. This will be the same value for
    # all (maybe host-node mapped) subsites, so probably one should
    # parameterize this function with a subsite value and compute the
    # result in the non-connected based on the subsite_id.
    #
    if {![ns_conn isconnected]} {
        return [ad_url]
    }

    set default_port(http) 80
    set default_port(https) 443
    set default_port(udp) 8000

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

    if { [ad_conn behind_proxy_p] } {
        #
        # We are running behind a proxy
        #
        if {[ad_conn behind_secure_proxy_p]} {
            #
            # We know, the request was an HTTPS request
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
    set Host [security::validated_host_header]
    #ns_log notice "util_current_location validated host header <$Host>"
    if {$Host ne ""} {
        util::split_host $Host hostname Host_port
        if {$Host_port ne ""} {
            set port $Host_port
        }
    } else {
        ns_log notice "ignore non-existing or untrusted host header, fall back to <$hostname>"
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
    #ns_log notice "util_current_location returns <$result> based on hostname <$hostname>"
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
    set path [ad_conn vhost_url]

    set lastchar [string index $path end]
    if {$lastchar eq "/" } {
        return $path
    } else {
        set file_dirname [ad_file dirname $path]
        # Treat the case of the root directory special
        if {$file_dirname eq "/" } {
            return /
        } else {
            return $file_dirname/
        }
    }
}


ad_proc -public ad_get_tcl_call_stack {
    {level -2}
} {

    Returns a stack trace from where the caller was called.  See also
    ad_print_stack_trace which generates a more readable stack trace
    at the expense of truncating args.

    @param level The level to start from, relative to this
    proc. Defaults to -2, meaning the proc that called this proc's
    caller. Per default, don't show "ad_log", when this calls
    ad_get_tcl_call_stack.

    @author Lars Pind (lars@pinds.com)

    @see ad_print_stack_trace
} {
    set stack ""
    #
    # keep the previous state of ::errorInfo
    #
    set errorInfo $::errorInfo

    for { set x [expr {[info level] + $level}] } { $x > 0 } { incr x -1 } {
        set info [info level $x]
        regsub -all \n $info {\\n} info
        #
        # In case, we have an NSF frame, add information about the
        # current object and the current class to the debug output.
        #
        if {![catch {uplevel #$x ::nsf::current} obj]
            && ![catch {uplevel #$x [list ::nsf::current class]} class]
        } {
            set objInfo [list $obj $class]
            set info "{$objInfo} $info"
        }
        #
        # Don't produce too long lines
        #
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
    #
    # restore previous state of ::errorInfo
    #
    set ::errorInfo $errorInfo
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

    foreach {varname value} [ns_set array $set_id] {
        upvar $level $varname var
        if { [info exists var] } {
            switch -- $duplicates {
                fail {
                    return -code error "ad_ns_set_to_tcl_vars tried to set the var $varname which is already set"
                }
                ignore {
                    # it's already set ... don't overwrite it
                    continue
                }
            }
        }
        set var $value
    }
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

    #
    # We count every element of list1.
    #
    foreach e $list1 {
        incr l($e)
    }

    #
    # For every element in list2 that is in list1, we uncount. We exit
    # as soon as all of the elements in list1 are accounted for.
    #
    foreach e $list2 {
        if {[info exists l($e)] && [incr l($e) -1] <= 0} {
            unset l($e)
            if {[array size l] == 0} {
                break
            }
        }
    }

    #
    # Now we just make sure that no counter is left that is positive.
    #
    foreach {k v} [array get l] {
        if {$v > 0} {
            return 0
        }
    }

    return 1
}

ad_proc -public util_get_subset_missing {
    list1
    list2
} {
    Returns the elements in list1 that are not in list2. Ignores duplicates.

    @return The list of elements from list1 that could not be found in list2.

    @author Peter Marklund
} {
    set missing [list]

    foreach e $list1 {
        if {$e ni $list2 && $e ni $missing} {
            lappend missing $e
        }
    }

    return $missing
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
        regsub -all -- {<[^>]+>} $item "" item_notags
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

# apisano 2017-06-08: this should someday replace proc
# util_text_to_url, but it is unclear to me whether we want two
# different semantics to sanitize URLs and filesystem names or
# not. For the time being I have replaced util_text_to_url in every
# place where this was used to sanitize filenames.
ad_proc ad_sanitize_filename {
    -no_resolve:boolean
    {-existing_names ""}
    -collapse_spaces:boolean
    {-replace_with "-"}
    -tolower:boolean
    str
} {
    Sanitize the provided filename for modern Windows, OS X, and Unix
    filesystems (NTFS, ext, etc.). FAT 8.3 filenames are not supported.
    The generated strings should be safe against
    <a target="_blank" href="https://github.com/minimaxir/big-list-of-naughty-strings">
    https://github.com/minimaxir/big-list-of-naughty-strings
    </a>

    @author Gustaf Neumann
} {
    #
    # Trim trailing periods and spaces (for Windows)
    #
    set str [string trim $str { .}]

    #
    # Remove Control characters (0x00–0x1f and 0x80–0x9f)
    # and reserved characters (/, ?, <, >, \, :, *, |, ; and ")
    regsub -all -- {[\u0000-\u001f|/|?|<|>|\\:*|\"|;]+} $str "" str

    # allow a custom replacement char, that must be safe.
    regsub -all -- {[\u0000-\u001f|/|?|<|>|\\:*|\"|;|\.]+} $replace_with "" replace_with
    if {$replace_with eq ""} {error "-replace_with must be a safe filesystem character"}

    #
    # Remove Unix reserved filenames (. and ..)
    # reserved names in windows
    set l [string length $str]
    if {($l <  3 && $str in {"." ".."}) ||
        ($l == 3 && $str in {CON PRN AUX NUL}) ||
        ($l == 4 && $str in {
            COM1 COM2 COM3 COM4 COM5 COM6 COM7 COM8 COM9
            LPT1 LPT2 LPT3 LPT4 LPT5 LPT6 LPT7 LPT8 LPT9
        })
    } {
        set str ""
    } elseif {$l > 255} {
        #
        # Truncate the name to 255 characters
        #
        set str [string range $str 0 254]
    }

    #
    # The transformations above are necessary. The following
    # transformation are optional.
    #
    if {$collapse_spaces_p} {
        #
        # replace all consecutive spaces by a single char
        #
        regsub -all -- {[ ]+} $str $replace_with str
    }
    if {$tolower_p} {
        #
        # replace all consecutive spaces by a single "-"
        #
        set str [string tolower $str]
    }

    # check if the resulting name is already present
    if {$str in $existing_names} {

        if { $no_resolve_p } {
            # name is already present in the existing_names list and we
            # are asked to not automatically resolve the collision
            error "The name $str is already present"
        } else {
            # name is already present in the existing_names list -
            # compute an unoccupied replacement using a pattern like
            # this: if foo is taken, try foo-2, then foo-3 etc.

            # Holes will not be re-occupied. E.g. if there's foo-2 and
            # foo-4, a foo-5 will be created instead of foo-3. This
            # way confusion through replacement of deleted content
            # with new stuff is avoided.

            set str_length [string length "${str}${replace_with}"]
            set number 2

            foreach name $existing_names {

                if {[string range $name 0 $str_length-1] eq "${str}${replace_with}"} {
                    set n [string range $name $str_length end]
                    if {[string is integer -strict $n] && $n >= $number} {
                        set number [incr n]
                    }
                }
            }

            set str "$str$replace_with$number"
        }
    }

    return $str
}

ad_proc -public util_text_to_url {
    {-existing_urls {}}
    {-no_resolve:boolean}
    {-replacement "-"}
    {-text ""}
    {_text ""}
} {
    Modify a string so that it is suited as a well formatted URL path element.
    Also, if given a list of existing URLs it can catch duplicate or optionally
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
    # them with their ASCII counterparts.
    #
    # TODO: The following mappings are based on ISO8859-*, which are rarely used today.
    #       Should be use (parts?) of ad_sanitize_filename or be replaced by it.
    #
    set text [string map { \xe4 ae \xf6 oe \xfc ue \xdf ss \xf8 o \xe0 a \xe1 a \xe8 e \xe9 e } $text]

    # here's the Danish ones (hm. the o-slash conflicts with the definition above, which just says 'o')
    set text [string map { \xe6 ae \xf8 oe \xe5 aa \xC6 Ae \xd8 Oe \xc5 Aa } $text]

    # substitute all non-word characters
    regsub -all -- {([^a-z0-9])+} $text $replacement text

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


ad_proc util_email_valid_p { query_email } {
    Returns 1 if an email address has more or less the correct form.
    The initial regexp was taken from Jeff Friedls book "Mastering Regular
    Expressions".

    It was later updated with the version proposed by mozilla for the email
    input type validation.
    https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/email#validation

    @author Philip Greenspun (philg@mit.edu)
    @author Jeff Friedl (jfriedl@oreilly.com)
    @author Lars Pind (lars@arsdigita.com)
    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @author Günter Ernst <gernst@wu.ac.at>
} {
    # This regexp was very kindly contributed by Jeff Friedl, author of
    # _Mastering Regular Expressions_ (O'Reilly 1997).
    # return [regexp "^\[^@<>\"\t ]+@\[^@<>\".\t ]+(\\.\[^@<>\".\n ]+)+$" $query_email]

    # Improved regexp from the folks at mozilla:
    # https://developer.mozilla.org/en-US/docs/Web/HTML/Element/input/email#validation
    return [regexp {^[a-zA-Z0-9.!#$%&'*+\/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$} $query_email]
}

ad_proc -public util_email_unique_p { email } {
    Returns 1 if the email passed in does not yet exist in the system.

    @author yon (yon@openforce.net)
} {
    return [db_string email_unique_p {}]
}

ad_proc -public util_url_valid_p {
    {-relative:boolean}
     query_url
 } {
    Check if an absolute Web URL (HTTP, HTTPS or FTP) is valid.

    If the 'relative' flag is set, also relative URLs are accepted.

    Refined regexp from https://mathiasbynens.be/demo/url-regex

    @author Philip Greenspun (philg@mit.edu)
    @author Héctor Romojaro <hector.romojaro@gmail.com>

    @param relative     Boolean. If true, Accept also relative URLs.
    @param query_url    The URL to check.
    @return             1 if the web URL is valid, 0 otherwise.

} {
    #
    # Does the URL look absolute?
    #
    if {$relative_p && ![regexp -nocase {^(.*://|mailto:)(.)*$} [string trim $query_url]]} {
        #
        # Relative URLs (https://datatracker.ietf.org/doc/html/rfc1808)
        #
        # Less restrictive (e.g. ../, ./, /, #g, ;x... and even an empty string
        # are valid relative URLs, see RFC above).
        #
        # At least, we check for spaces...
        #
        return [regexp -nocase {^[^\s]*$} [string trim $query_url]]
    } else {
        #
        # Absolute URLs (HTTP, HTTPS or FTP)
        #
        # The authority part of the URL should not start with either space,
        # /, $, ., ? or #, and should not have spaces until the end of line.
        #
        return [regexp -nocase {^(https?|ftp)://[^\s/$.?#][^\s]+$} [string trim $query_url]]
    }
}

ad_proc -public util::min { args } {
    Returns the minimum of a list of numbers. Example: <code>min 2 3 1.5</code> returns 1.5.

    Since Tcl8.5, numerical min and max are among the math functions
    supported by expr. The reason why this proc is still around is
    that it supports also non-numerical values in the list, in a way
    that is not so easily replaceable by a lsort idiom (but could).

    @see expr
    @see lsort

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


ad_proc -public util::max { args } {
    Returns the maximum of a list of numbers. Example: <code>max 2 3 1.5</code> returns 3.

    Since Tcl8.5, numerical min and max are among the math functions
    supported by expr. The reason why this proc is still around is
    that it supports also non-numerical values in the list, in a way
    that is not so easily replaceable by a lsort idiom (but could).

    @see expr
    @see lsort

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

ad_proc -public util_sets_equal_p { list1 list2 } {
    Tests whether each unique string in list1 occurs as many
    times in list1 as in list2 and vice versa (regardless of order).

    @return 1 if the lists have identical sets and 0 otherwise

    @author Peter Marklund
} {
    return [expr { [llength $list1] == [llength $list2] && [lsort $list1] eq [lsort $list2] }]
}

ad_proc -public util_list_of_ns_sets_to_list_of_lists {
    {-list_of_ns_sets:required}
} {
    Transform a list of ns_sets (most likely produced by db_list_of_ns_sets)
    into a list of lists that match the array set format in the sublists
    (key value key value ...)

    @param list_of_ns_sets A list of ns_set ids

    @author Ola Hansson (ola@polyxena.net)
    @creation-date September 27, 2002
} {
    set result [list]

    foreach ns_set $list_of_ns_sets {
        lappend result [ns_set array $ns_set]
    }

    return $result
}

ad_proc -public xml_get_child_node_content_by_path {
    node
    path_list
} {
    Return the first nonempty contents of a child node down a given path from the current node.

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
        [xml_get_child_node_content_by_path $root_node { { person comments foo } { person name first_names } { properties datetime } }] &quot;2001-08-08&quot;
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
    </pre>

    @param node        The node to start from
    @param path_list   List of the node to try, e.g.
    { grouptype typevalue }.
    @param attribute_name   Attribute name at the very end of the very bottom of the tree route at path_list.

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
    return [string range [sec_random_token] 0 $length-1]
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
    @return a boolean telling whether a background execution with this
            name is currently running.
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


####################
#
# Procs in the util namespace
#
####################

ad_proc util::name_to_path {
    -name:required
} {
    Transforms a pretty name to a reasonable pathname.
} {
    regsub -all -nocase -- { } [string trim [string tolower $name]] {-} name
    regsub -all -- {[^[:alnum:]\-]} $name {} name
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

        if { ![ad_file exists $backup_path] } {
            # We found a non-existing backup path
            break
        }

        incr backup_counter
    }

    #exec "mv" "$file_path" "$backup_path"
    file rename -- $file_path $backup_path
}



ad_proc -public util::subst_safe { string } {
    Make string safe for subst'ing.
} {
    regsub -all -- {\$} $string {\$} string
    regsub -all -- {\[} $string {\[} string
    regsub -all -- {\]} $string {\]} string
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
        set index [util::random_range [expr {[llength $list] - 1}]]
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
            switch -- $hours {
                0 { set result "" }
                1 { set result "One hour " }
                default { set result "$hours hours "}
            }
            switch -- $minutes {
                0 {}
                1 { append result "$minutes minute " }
                default { append result "$minutes minutes " }
            }
        } else {
            set days [expr {abs($hours / 24)}]
            switch -- $days {
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

    set old_fd [file tempfile old_f [ad_tmpdir]/nsdiff-XXXXXX]
    set new_fd [file tempfile new_f [ad_tmpdir]/nsdiff-XXXXXX]
    puts $old_fd [join [split $old $split_by] "\n"]
    puts $new_fd [join [split $new $split_by] "\n"]
    close $old_fd
    close $new_fd

    #
    # Diff output is 1 based, our lists are 0 based, so insert a dummy
    # element to start the list with.
    #
    set old_w [linsert [split $old $split_by] 0 {}]
    set sv 1

    try {
        exec -ignorestderr diff -f $old_f $new_f
    } on error {output} {
    } on ok {output} {
    }
    set lines [split $output \n]
    set pos -1
    set nrLines [llength $lines]
    while {1} {
        if {$nrLines < $pos} {
            break
        }
        set diff [lindex $lines [incr pos]]
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
            while {1} {
                if {$nrLines < $pos} {
                    break
                }
                set diff [lindex $lines [incr pos]]
                if {$diff eq "."} {
                    break
                } else {
                    append res "${split_by}${start_new}${diff}${end_new}"
                }
            }
            set sv [expr {$d_end + 1}]
        } elseif {[regexp {^a(\d+)$} $diff full m1]} {
            set d_end $m1
            for {set i $sv} {$i <= $m1} {incr i} {
                append res "${split_by}[lindex $old_w $i]"
            }
            while {1} {
                if {$nrLines < $pos} {
                    break
                }
                set diff [lindex $lines [incr pos]]
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
    # This param controls how many backups of the server log to keep,
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
                    if { [ad_file isfile $file] } {
                        if {$extension eq "" || $file_extension eq $extension} {
                            lappend files [list $filename $file]
                        }
                    } elseif { [ad_file isdirectory $file] } {
                        if { $include_dirs == 1 } {
                            lappend files $file
                        }
                        lappend new_files_to_examine {*}[glob -nocomplain "$file/*"]
                    }
                }
            }
        }
        set files_to_examine $new_files_to_examine
    }
    return $files
}

ad_proc -deprecated util::string_check_urlsafe {
    s1
} {
    This proc accepts a string and verifies if it is url safe.
    - make sure there is no space
    - make sure there is no special characters except '-' or '_'
    Returns 1 if yes and 0 if not.
    Meant to be used in the validation section of ad_form.

    DEPRECATED: this proc is not in use in upstream code as of
    2022-09-5. It also looks as if this will return true when a string
    is NOT safe.
} {
    return [regexp {[<>:\"|/@\#%&+\\ ]} $s1]
}

ad_proc -public util::which {prog} {

    Use environment variable PATH to search for the specified executable
    program. Replacement for UNIX command "which", avoiding exec.

    exec which:    3368.445 microseconds per iteration
    ::util::which:  282.372 microseconds per iteration

    In addition of being more than 10 time faster than the
    version via exec, this version is less platform dependent.

    @param prog   name of the program to be located on the search path
    @return fully qualified name including path, when specified program is found,
    or otherwise empty string

    @author Gustaf Neumann
} {
    switch -- $::tcl_platform(platform) {
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
        set fullname [ad_file join $dir $prog]
        foreach ext $exts {
            if {[ad_file executable $fullname$ext]} {
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
    https://wiki.tcl-lang.org/1039

    @param command A list of arguments to pass to exec
    @param result_var Variable name in caller's scope to set the result in

    @return 0 or 1. 0 if no error, 1 if an error occurred. If an error
    occurred the error message will be put into result_var in the
    caller's scope.

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
                # exited with a nonzero exit status, $code.
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
                set result "an error occurred $errName \"$msg\""
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
    HTTP or HTTPS port number added or removed from current hostname
    or another hostname that the host responds to (from host_node_map)
} {
    set external_url_p [util_complete_url_p $url]
    #
    # Only if the URL is syntactical a URL with a protocol, it might
    # be external.
    #
    if {$external_url_p} {
        #
        # If it has a protocol, we have to be able to find it in security::locations
        #
        set locations_list [security::locations]
        # more valid url pairs with host_node_map

        foreach location $locations_list {
            if {$location eq ""} {
                continue
            }
            set len [string length $location]
            #ns_log notice "util::external_url_p location match <$location/*> with <$url> sub <[string range $url 0 $len-1]>"
            if {[string range $url 0 $len-1] eq $location} {
                set external_url_p 0
                break
            }
        }
    }
    return $external_url_p
}

ad_proc util::potentially_unsafe_eval_p { -warn:boolean string } {

    Check content of the string to identify potentially unsafe content
    in the provided string. The content is unsafe, when it contains
    externally provided content, which might be provided e.g. via
    query variables, or via user values stored in the database. When
    such content contains square braces, a "subst" command on
    it can evaluate arbitrary commands, which is dangerous.

} {
    #ns_log notice "util::potentially_unsafe_eval_p '$string'"
    set unsafe_p 0
    set original_string $string
    while {1} {
        set p [string first \[ $string ]
        if {$p > 0} {
            set previous_char [string range $string $p-1 $p-1]
            set string [string range $string $p+1 end]
            if {$previous_char eq "\\"} {
                continue
            }
        }
        #ns_log notice "util::potentially_unsafe_eval_p '$string' $p"
        if {$p < 0 || [string length $string] < 2} {
            break
        }
        set unsafe_p 1
        if {$warn_p} {
            ad_log warning "potentially unsafe eval on '$original_string'"
        }
        break
    }
    #ns_log notice "util::potentially_unsafe_eval_p '$string' ->  $unsafe_p"
    return $unsafe_p
}

# potential test cases
#util::potentially_unsafe_eval_p 123
#util::potentially_unsafe_eval_p {123[aaa}
#util::potentially_unsafe_eval_p {123\[aaa}
#util::potentially_unsafe_eval_p {123\[aaa[567}

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

ad_proc ad_tmpnam {{template ""}} {
    A stub function to replace the deprecated "ns_tmpnam", which uses
    the deprecated C-library function "tmpnam()".  However, also
    ns_mktemp is not recommended any more due to a potential race
    between the name creation and the file open command.
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

ad_proc ad_opentmpfile {varFilename {template "oacs"}} {

    Wrapper for Tcl's "file tempfile ...", but respects the server's
    tmpdir settings, e.g. when admin want to specify the temporary
    directory.  The function is similar to "ns_opentmpfile", but
    provides a default template and uses always the configured tmp
    directory.

} {
    uplevel [list file tempfile $varFilename [ns_config ns/parameters tmpdir]/$template]
}

if {$::tcl_version > 8.6} {
    #
    # Tcl 8.7 or newer
    #
    ad_proc ad_mktmpdir {{prefix "oacs"}} {

        Wrapper for Tcl's "file tempdir ...", but respects the server's
        tmpdir settings.

        @param prefix optional parameter, for easier
               identification of the directory
        @return name of the created directory
    } {
        file tempdir [ns_config ns/parameters tmpdir]/$prefix
    }
} else {
    #
    # Tcl 8.6 or earlier
    #
    ad_proc ad_mktmpdir {{prefix "oacs"}} {

        Wrapper for Tcl's "file tempdir ...", but respects the server's
        tmpdir settings.

        @param prefix optional parameter, for easier
               identification of the directory
        @return name of the created directory

    } {
        package require fileutil
        ::fileutil::maketempdir -prefix ${prefix}_ -dir [ns_config ns/parameters tmpdir]
    }
}

ad_proc -private util::ns_set_pretty_print {
    {-title {}}
    {-prefix " "}
    set
} {
    Return pretty printed version of an ns_set, in the style of HTTP
    request header fields.

    @param title title info for the full set
    @param prefix prefix string for every line (used e.g. for indenting)
    @return multi-line string
} {
    set lines {}
    if {$title ne ""} {
        lappend lines $title
    }
    lappend lines {*}[lmap {k v} [ns_set array $set] {
        string cat $prefix $k ": " $v
    }]
    return [join $lines \n]
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
                append info "\n    connection already closed, cooked form-content:"
                foreach {k v} [ns_set array [ns_getform]] {
                    if {[string length $v] > 100} {
                        set v "[string range $v 0 100]..."
                    }
                    append info "\n        $k: $v"
                }
            } else {
                set ct [ns_set iget [ns_conn headers] content-type]
                if {[string match text/* $ct] || $ct eq "application/x-www-form-urlencoded"} {
                    set data [ns_conn content]
                    if {[string length $data] < 2000} {
                        append info "\n        post-data: $data"
                    }
                }
            }
        }

        #
        # Optional header info
        #
        if {$with_headers_p} {
            append info \n [util::ns_set_pretty_print [ns_conn headers]]
        }
    }
    return $info
}

ad_proc util::trim_leading_zeros {
    string
} {
    Returns a string with leading zeros trimmed.  Used to get around
    Tcl interpreter problems without thinking leading zeros are octal.

    <p>If string is real and mod(number)&lt;1, then we have pulled off
    the leading zero; i.e. 0.231 -&gt; .231 - this is still fine
    for Tcl though...
} {
    if {$string ne ""} {
        set string [string trimleft $string 0]
        if {$string eq ""} {
            set string 0
        }
    }
    return $string
}

ad_proc -public ad_log {
    level
    args
} {
    Output ns_log message with detailed context. This function is
    intended to be used typically with "error" to ease debugging.

    @param level Severity level such as "error" or "warning".
    @param args Log message

    @author Gustaf Neumann
} {
    set with_headers [expr {$level in {error Error}}]
    append request "    " \
        [util::request_info -with_headers=$with_headers]

    ns_log $level {*}$args "\n[uplevel ad_get_tcl_call_stack]${request}\n"
}

ad_proc -public util::var_subst_quotehtml {
   {-ulevel 1}
   string
} {

    Substitute in the provided string all variables with their values
    (like "subst -nobackslashes -nocommands ..."), and perform HTML
    quoting on the variable values before substitution.  This command
    supports Tcl array syntax, and Tcl scalar variables with and
    without curly braces.

    @param ulevel Where we should uplevel to when doing the subst's.
           Defaults to '1', meaning the caller's scope.

    @author Gustaf Neumann
} {
    #
    # Protect evaluation characters
    #
    set escaped [string map {[ \\[ ] \\] \\ \\\\} $string]
    #
    # Handle array syntax:
    #
    regsub -all -- {\$([0-9a-zA-Z_:]*[\(][^\)]+[\)])} $escaped {[ns_quotehtml [set \1]]} escaped
    #
    # Handle plain variables:
    #
    regsub -all -- {\$([0-9a-zA-Z_:]+|[\{][^\}]+[\}])} $escaped {[ns_quotehtml $\1]} result
    #
    # Finally, "subst" the result.
    #
    return [uplevel $ulevel [list ::subst $result]]
}


namespace eval util {

    ad_proc -public ::util::file_content_check {
        -type:required
        -filename:required
    } {

        Check whether the provided file is of the requested type.
        This function is more robust and portable than relying on
        external programs and their output, but it does not work on
        all possible file types. It checks a few common cases that
        could lead to problems otherwise, like when uploading archives.

        @return Boolean value (0 or 1)

    } {
        set known_signatures {
            zip    504b0304
            gzip   1f8b
            pdf    255044462d
            xz     fd377a585a00
            bz2    425A68
            export 23206578706f7274696e6720
        }
        if {[dict exists $known_signatures $type]} {
            set hex_signature [dict get $known_signatures $type]
            set len [expr {[string length $hex_signature] / 2}]
            set F [open $filename rb]
            set signature [read $F $len]
            close $F
            return [expr {[binary encode hex $signature] eq $hex_signature}]
        } else {
            error "util::file_content_check called with unsupported file type '$type'"
        }
    }

    ad_proc -public ::util::ns_set_to_tcl_string {set_id} {

        Return a plain text version of the passed-in ns_set, useful
        for debugging and introspection.

        @return text string conisting of multiple lines of the form "key: value"
    } {
        set result ""
        foreach {key value} [ns_set array $set_id] {
            append result "$key : $value\n"
        }
        return $result
    }

    ad_proc ::util::inline_svg_from_dot {{-css ""} dot_code} {

        Transform a dot source code into an inline svg image based on
        code from xotcl-core; should be probably made more
        configurable in the future.

        @param dot_code grapviz dot code
        @result graph in HTML markup

        @author Gustaf Neumann
    } {
        catch {set dot [::util::which dot]}
        if {$dot ne ""} {
            set dir [ad_tmpdir]/oacs-dotcode
            if {![ad_file isdirectory $dir]} {
                file mkdir $dir
            }
            #
            # Cache file in the filesystem based on an MD5 checksum
            # derived from the dot source-code, the format and the
            # styling.
            #
            # TODO: one should provide a more general - usable for
            # many applications - file cache with a cleanup of stale
            # entries (maybe based on last access time, when the
            # filesystem provides it).
            #
            set dot_signature [ns_md5 $dot_code-svg-$css]
            set stem $dir/$dot_signature
            if {![ad_file exists $stem.svg]} {
                ns_log notice "inline_svg_from_dot: generate $stem.svg"

                set dotfile $stem.dot
                set svgfile $stem.svg
                set f [open $dotfile w]; puts $f $dot_code; close $f

                try {
                    exec $dot -Tsvg -o $svgfile $dotfile
                } on error {errorMsg} {
                    ns_log warning "inline_svg_from_dot: dot returned $errorMsg"
                } on ok {result} {
                    set f [open $stem.svg]; set svg [read $f]; close $f
                } finally {
                    file delete -- $stem.dot
                }
            } else {
                ns_log notice "inline_svg_from_dot: reuse $stem.svg"
            }
            if {[ad_file exists $stem.svg]} {
                set f [open $stem.svg]; set svg [read $f]; close $f
                #
                # Delete the first three lines generated from dot.
                #
                regsub {^[^\n]+\n[^\n]+\n[^\n]+\n} $svg "" svg
                set result ""
                if {$css ne ""} {
                    append result <style>$css</style>
                }
                append result "<div class='inner'>$svg</div>"
                return $result
            } else {
                ns_log warning "cannot create svg file"
            }
        }
        return ""
    }
}

#
# Management of resource files, to be used in sitewide-admin procs to
# decide between CDN installations and local installations.
#
# The configuration information is provided via dict named resource_info,
# containing typically the following fields (all in Camel case style):
#
#   - resourceName:  Name for the resources
#                    where the resource are to be stored
#   - resourceDir:   the top-level directory on the local disk,
#                    where the resource are to be stored
#   - cdn:           the CDN URL prefix for obtaining the content (e.g. //maxcdn.bootstrapcdn.com/bootstrap)
#   - cdnHost:       CDN host, sometimes needed for content security policies
#   - cssFiles:      list of CSS files for that package (can be provided via URN)
#   - jsFiles:       list of JavaScript files for that package (can be provided via URN)
#   - extraFiles:    list of more files, probably included by cssFiles (e.g. fonts)
#   - prefix:        used for resolving the files on the server; might either point
#                    to the CDN or to locally installed files (typically /resources/...)
#
# Optionally, the dict can contain more fields, like e.g. a "urnMap"
# for mapping URLs to resources (see e.g. openacs-bootstrap4-theme) or
# "downloadURLs" for downloading full packages.
#
namespace eval util::resources {

    ad_proc -public ::util::resources::is_installed_locally {
        -resource_info:required
        {-version_dir ""}
    } {

        Check, if the required resource files are installed locally.
        When the version_dir is specified, it is possible to have
        different versions locally installed.

        @param resource_info a dict containing resourceDir, cssFiles, jsFiles, and extraFiles
        @param version_dir an optional directory, under the resource directory

        @author Gustaf Neumann
    } {
        set installed 1
        set version_dir [version_dir \
                             -version_dir $version_dir \
                             -resource_info $resource_info]
        set resource_dir [dict get $resource_info resourceDir]
        set downloadFiles {}
        ns_log notice "check downloadURLs <[dict exists $resource_info downloadURLs]> // [lsort [dict keys $resource_info]]"
        if {[dict exists $resource_info downloadURLs]} {
            ns_log notice "we have downloadURLs <[dict get $resource_info downloadURLs]>"
            foreach url [dict get $resource_info downloadURLs] {
                lappend downloadFiles [ad_file tail $url]
            }
        }
        set files [concat \
                       [dict get $resource_info cssFiles] \
                       [dict get $resource_info jsFiles] \
                       [dict get $resource_info extraFiles] \
                       $downloadFiles \
                      ]
        ns_log notice "check files <$files>"
        foreach file $files {
            if {$version_dir eq ""} {
                set path $resource_dir/$file
            } else {
                set path $resource_dir/$version_dir/$file
            }
            if {![ad_file readable $path/]} {
                set installed 0
                break
            }
        }
        return $installed
    }

    ad_proc -public ::util::resources::can_install_locally {
        {-resource_info:required}
        {-version_dir ""}
    } {

        Check, whether the operating system's permissions allow us to
        install in the configured directories.

        @param resource_info a dict containing at least resourceDir
        @param version_dir an optional directory, under the resource directory

        @author Gustaf Neumann
    } {
        set can_install 1
        set version_dir [version_dir \
                             -version_dir $version_dir \
                             -resource_info $resource_info]

        set resource_dir [dict get $resource_info resourceDir]

        if {![ad_file isdirectory $resource_dir]} {
            try {
                file mkdir $resource_dir
            } on error {errorMsg} {
                set can_install 0
            }
        }
        if {$can_install && $version_dir ne ""} {
            set path $resource_dir/$version_dir
            if {![ad_file isdirectory $path]} {
                try {
                    file mkdir $path
                    #
                    # We check on the version-dir, if the package is
                    # installed, therefore, don't create an empty one.
                    #
                    file delete $path
                } on error {errorMsg} {
                    set can_install 0
                }
            } else {
                set can_install [ad_file writable $path]
            }
        }
        return $can_install
    }

    ad_proc -public ::util::resources::version_dir {
        {-resource_info:required}
        {-version_dir ""}
    } {

        Obtain the version_dir either form the provided string or from
        the resource_info dict.

    } {
        if {$version_dir eq "" && [dict exists $resource_info versionDir]} {
            set version_dir [dict get $resource_info versionDir]
        }
        return $version_dir
    }

    ad_proc -private ::util::resources::download_helper {
        -url
    } {
        Helper for ::util::resources::download, since some download
        sites tend to redirect.

        @result dict as returned by ns_http.
    } {
        #set result [util::http::get -url $url -spool]
        set host [dict get [ns_parseurl $url] host]
        set result [ns_http run -hostname $host -spoolsize 1 $url]
        set fn ""
        switch [dict get $result status] {
            200 {
                set fn [dict get $result file]
            }
            301 -
            302 {
                set location [ns_set iget [dict get $result headers] location]
                ns_log notice "download redirected to $location"
                #set result [util::http::get -url $location -spool]
                set host [dict get [ns_parseurl $url] host]
                set result [ns_http run -hostname $host -spoolsize 1 $location]
                if {[dict get $result status] == 200} {
                    set fn [dict get $result file]
                }
            }
            default {
                ns_log warning "::util::resources::download $url" \
                    "lead to HTTP status code [dict get $result status]"
            }
        }
        if {$fn eq ""} {
            error "download from $url failed: $result"
        }
        return $result
    }

    ad_proc -public ::util::resources::download {
        {-resource_info:required}
        {-version_dir ""}
    } {

        Download resources typically from a CDN and install it for local usage.
        The installed files are as well gzipped for faster delivery, when gzip is available.-

        @param version_dir an optional directory, under the resource directory
        @param resource_info a dict containing resourceDir, cdn, cssFiles, jsFiles, and extraFiles

        @author Gustaf Neumann
    } {
        set resource_dir [dict get $resource_info resourceDir]
        set version_dir [version_dir \
                             -version_dir $version_dir \
                             -resource_info $resource_info]

        set can_install [::util::resources::can_install_locally \
                             -resource_info $resource_info \
                             -version_dir $version_dir]
        if {!$can_install} {
            error "Cannot download resources to $resource_dir due to permissions"
        }

        #
        # Get the CDN prefix (this does not include the source version
        # information as used on the CDN).
        #
        set download_prefix https:[dict get $resource_info cdn]
        set local_path $resource_dir

        if {$version_dir ne ""} {
            append local_path /$version_dir
            append download_prefix /$version_dir
        }
        if {![ad_file writable $local_path]} {
            file mkdir $local_path
        }

        #
        # Do we have gzip installed?
        #
        set gzip [::util::which gzip]

        #
        # So far, everything went fine. Now download the files and
        # raise an exception, when the download fails.
        #
        foreach file [concat \
                          [dict get $resource_info cssFiles] \
                          [dict get $resource_info jsFiles] \
                          [dict get $resource_info extraFiles] \
                         ] {

            ns_log notice "::util::resources::download $download_prefix/$file"
            set result [download_helper -url $download_prefix/$file]
            #ns_log notice "... returned status code [dict get $result status]"
            set fn [dict get $result file]

            set local_root [ad_file dirname $local_path/$file]
            if {![ad_file isdirectory $local_root]} {
                file mkdir $local_root
            }
            file rename -force -- $fn $local_path/$file

            #
            # Remove potentially stale gzip file.
            #
            if {[ad_file exists $local_path/$file.gz]} {
                file delete -- $local_path/$file.gz
            }

            #
            # When gzip is available, produce a static compressed file
            # as well.
            #
            if {$gzip ne ""} {
                #
                # Recent versions of gzip (starting with gzip 1.6,
                # released 2013) should use:
                #
                #      exec $gzip -9 -k $local_path/$file
                #
                # For backwards compatibility, we use redirects.
                #
                exec $gzip -9 < $local_path/$file > $local_path/$file.gz
            }
        }

        if {[dict exists $resource_info downloadURLs]} {
            #
            # For downloadURLs, just handle here the download. How to
            # decompress these archives and what to do with these to
            # install it properly is handled by package-speficic
            # downloaders, which might call this function.
            #
            foreach url [dict get $resource_info downloadURLs] {
                set result [download_helper -url $url]
                set fn [dict get $result file]
                set file [ad_file tail $url]
                file rename -force -- $fn $local_path/$file
            }
        }
    }
}

ad_proc -deprecated ad_tcl_vars_to_ns_set {
    -set_id
    -put:boolean
    args
} {
    Takes a list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    DEPRECATED 5.10.1: modern ns_set idioms make this proc obsolete

    @see ns_set

    @param set_id If this switch is specified, it'll use this set instead of
    creating a new one.

    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead
    of <code>ns_set update</code> (update is default)

    @param args A number of variable names that will be transported into the ns_set.

    @author Lars Pind (lars@pinds.com)

} {
    ns_log notice "deprecated call: [info level [info level]]"

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

ad_proc -deprecated ad_tcl_vars_list_to_ns_set {
    -set_id
    -put:boolean
    vars_list
} {
    Takes a Tcl list of variable names and <code>ns_set update</code>s values in an ns_set
    correspondingly: key is the name of the var, value is the value of
    the var. The caller is (obviously) responsible for freeing the set if need be.

    DEPRECATED 5.10.1: modern ns_set idioms make this proc obsolete

    @see ns_set

    @param set_id If this switch is specified, it'll use this set instead of
    creating a new one.

    @param put If this boolean switch is specified, it'll use <code>ns_set put</code> instead
    of <code>ns_set update</code> (update is default)

    @param vars_list A Tcl list of variable names that will be transported into the ns_set.

    @author Lars Pind (lars@pinds.com)

} {
    ns_log notice "deprecated call: [info level [info level]]"
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

ad_proc -deprecated oacs_util::vars_to_ns_set {
    {-ns_set:required}
    {-var_list:required}
} {
    Does an ns_set put on each variable named in var_list

    DEPRECATED 5.10.1: modern ns_set idioms make this proc obsolete

    @see ns_set

    @param var_list list of variable names in the calling scope
    @param ns_set an ns_set id that already exists.
} {
    ns_log notice "deprecated call: [info level [info level]]"
    foreach var $var_list {
        upvar $var one_var
        ns_set put $ns_set $var $one_var
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
