ad_library {

    Routines to support documenting pages and processing query arguments.

    @author Lars Pind (lars@pinds.com)
    @author Jon Salz (jsalz@mit.edu)
    @author Yonatan Feldman (yon@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)

    @creation-date 16 June 2000
    @cvs-id $Id$
}

####################
#
# Documentation-mode procs
#
####################

ad_proc api_page_documentation_mode_p { } {

    Determines whether the thread is in "gathering documentation" or "executing the page" mode.

    @return true if the thread is in "gathering documentation" mode, or false otherwise.

    @see doc_set_page_documentation_mode

} {
    if { [info exists ::ad_conn(api_page_documentation_mode_p)] } {
        return $::ad_conn(api_page_documentation_mode_p)
    }
    return 0
}

ad_proc doc_set_page_documentation_mode { page_documentation_mode_p } {

    Set a flag in the environment determining whether the thread is in
    "gathering documentation" or "executing the page" mode.

    @param page_documentation_mode_p true to set the "gathering documentation" flag,
    or false to clear it.
    @see api_page_documentation_mode_p
} {
    set ::ad_conn(api_page_documentation_mode_p) $page_documentation_mode_p
}

####################
#
# Complaints procs
#
####################

# global:
# ad_page_contract_complaints: list of error messages reported using ad_complain
# ad_page_contract_errorkeys: [list] is a stack of errorkeys
# ad_page_contract_error_string(name:flag) "the string"
# ad_page_contract_context context for error message
#

ad_proc -private ad_complaints_init {context} {
    Initializes the complaints system.

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    set ::ad_page_contract_complaints [list]
    set ::ad_page_contract_errorkeys [list]
    set ::ad_page_contract_context $context
}

ad_proc -public ad_complain {
    {-key ""}
    {message ""}
} {
    Used to report a problem while validating user input. This proc does not
    in itself make your code terminate, you must call return if you do not
    want control to return to the caller.

    <p>

    @param key

    @param message

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    # if no key was specified, grab one from the internally kept stack
    if { $key eq "" && [info exists ::ad_page_contract_errorkeys] } {
        set key [lindex $::ad_page_contract_errorkeys 0]
    }
    if { [info exists ::ad_page_contract_error_string($key)] } {
        lappend ::ad_page_contract_complaints $::ad_page_contract_error_string($key)
    } elseif { $message eq "" } {
        lappend ::ad_page_contract_complaints [_ acs-tcl.lt_Validation_key_compla]
    } else {
        lappend ::ad_page_contract_complaints $message
    }
}

ad_proc -private ad_complaints_with_key { errorkey code } {
    Sets the default errorkey to be used when ad_complaint is called. This essentially maintains
    a stack of errorkeys, so we can just say ad_complain without any arguments, when called
    from within some code that is surrounded by ad_complaints_with_key.

    @author Lars Pind
    @creation-date 25 July 2000
} {
    set ::ad_page_contract_errorkeys [concat $errorkey $::ad_page_contract_errorkeys]
    uplevel 1 $code
    set ::ad_page_contract_errorkeys [lrange $::ad_page_contract_errorkeys 1 end]
}

ad_proc -private ad_complaints_count {} {
    Returns the number of complaints encountered so far.

    @author Lars Pind
    @creation-date 25 July 2000
} {
    return [llength $::ad_page_contract_complaints]
}

ad_proc -public ad_complaints_get_list {} {
    Returns the list of complaints encountered so far.

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    return $::ad_page_contract_complaints
}

ad_proc -private ad_complaints_parse_error_strings { errorstrings } {
    Parses the error-strings argument to ad_page_contract and stores the
    result in global variables, so it can be used by ad_complain.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    array set ::ad_page_contract_error_string [list]

    foreach { errorkeys text } $errorstrings {
        foreach errorkey $errorkeys {
            set errorkeyv [split $errorkey ":"]
            if { [llength $errorkeyv] > 2 } {
                return -code error "Error name '$error' doesn't have the right format. It must be var\[:flag\]"
            }
            lassign $errorkeyv name flags
            if { $flags eq "" } {
                set ::ad_page_contract_error_string($name) $text
            } else {
                foreach flag [split $flags ","] {
                    if { $flag ne "" } {
                        set ::ad_page_contract_error_string($name:$flag) $text
                    } else {
                        set ::ad_page_contract_error_string($name) $text
                    }
                }
            }
        }
    }
}

####################
#
# Validation OK procs
#
####################

# global:
# ad_page_contract_validations_passed(name) 1               the variable was supplied
# ad_page_contract_validations_passed(name:flag) 1          the filter returned 1
#

ad_proc -private ad_page_contract_set_validation_passed { key } {
    Call this to signal that a certain validation block has passed successfully.
    This can be tested later using ad_page_contract_get_validation_passed_p.

    @param key Is the key, in the format of either <i>formal_name</i> or <i>formal_name</i>:<i>flag_name</i>.

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    set ::ad_page_contract_validations_passed($key) 1
}

ad_proc -private ad_page_contract_get_validation_passed_p { key } {
    Find out whether the named validation block has been passed or not.

    @param key Is the key, in the format of either <i>formal_name</i> or <i>formal_name</i>:<i>flag_name</i>.

    @author Lars Pind (lars@pinds.com)
    @creation-date 24 July 2000
} {
    return [info exists ::ad_page_contract_validations_passed($key)]
}

####################
#
# Eval helper proc
#
####################

ad_proc ad_page_contract_eval { args } {
    This just uplevels its args. We need this proc, so that the return -code statements
    get processed correctly inside a catch block. This processing is namely done by the
    proc invocation.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    uplevel 1 $args
}

####################
#
# ad_page_contract
#
####################

ad_proc -private ad_page_contract_argspec_flag_regexp {} {
   Returns the regexp defining what an argspec flag should look like.
} {
    return {[a-zA-Z0-9_]+(?:\((?:\\\(|\\\)|[^\)])+\))?}
}

ad_proc -private ad_page_contract_parse_argspec {arg_spec} {

    Parse the argument spec: this is a string in the form
    &lt;name&gt;:&lt;flag_spec&gt;[,&lt;flag_spec&gt;...]
    <ul>
    <li> &lt;name&gt; is a token made of any non-space, non-tab and non-colon
    <li> &lt;flag_spec&gt; is string in the form
         &lt;flag_name&lgt;[(&lt;flag_parameter&gt;[|&lt;flag_parameter&gt;...])]
    <li> &lt;flag_parameter&gt; is a string containing arbitrary characters,
                       however, because parenthesys ")" and "(" and
                       pipe "|" are separators in the argspec syntax,
                       they need to be escaped via the character backslash (\)
    </ul>

    Examples of valid argspecs:

<pre>
    - my_page_parameter
    - my_page_parameter:integer
    - my_page_parameter:integer,notnull
    - my_page_parameter:integer,notnull,oneof(1|2|3)
    - another_page_parameter:oneof(this is valid|This, is also valid|This is valid \(as well!\))
</pre>
} {
    set flag_rx [ad_page_contract_argspec_flag_regexp]

    if { ![regexp [subst -nocommands {^([^ \t:]+)(?::(${flag_rx}(?:,${flag_rx})*))?$}] $arg_spec match name flags] } {
        error "Argspec '$arg_spec' doesn't have the right format. It must be var\[:flag\[,flag ...\]\]"
    }

    return [list $name $flags]
}

ad_proc -private ad_page_contract_split_argspec_flags {flags} {

    Splits the flags in an argspec definition into a list.

} {
    set flag_rx [ad_page_contract_argspec_flag_regexp]

    set pre_flag_list [list]
    while { [regexp [subst -nocommands {^(${flag_rx})(?:,(.+)|)$}] $flags _ flag rest] } {
        lappend pre_flag_list $flag
        set flags $rest
    }

   return $pre_flag_list
}

ad_proc -private ad_page_contract_split_argspec_flag_parameters {flag_parameters} {

    Splits the flag parameters from an argespec into a list of values.

    Flag parameters are a list of values expressed as &lt;value&gt;[|&lt;value&gt; ...]

} {
    # First, unescape the parenthesys
    regsub -all {\\\(} $flag_parameters {(} flag_parameters
    regsub -all {\\\)} $flag_parameters {)} flag_parameters

    set parameters [list]
    while {[string length $flag_parameters] > 0} {
        set flag_parameter ""

        # First, keep appending to the string as long as we find
        # escaped occurrences of the pipe character.
        while { [set quoted_sep_i [string first {\|} $flag_parameters]] >= 0 } {
            append flag_parameter [string range $flag_parameters 0 ${quoted_sep_i}-1]|
            set flag_parameters [string range $flag_parameters ${quoted_sep_i}+2 end]
        }

        # Now that all escaped occurrences are over, find the first
        # unescaped one.
        set pi [string first | $flag_parameters]
        if {$pi == -1} {
            # There was none, the entire remainder of the string is
            # our parameter and we are done.
            append flag_parameter $flag_parameters
            set flag_parameters ""
        } else {
            # Our parameter is all of the remaining string up to the
            # pipe character. We will keep parsing further.
            append flag_parameter [string range $flag_parameters 0 ${pi}-1]
            set flag_parameters [string range $flag_parameters ${pi}+1 end]
        }
        lappend parameters $flag_parameter
    }

    return $parameters
}

# global:

# ad_page_contract_variables: list of all the variables, required or
#   optional, specified in the ad_page_contract call error

ad_proc -public ad_page_contract {
    {-form {}}
    {-level 1}
    {-context ""}
    {-warn:boolean}
    -properties
    docstring
    args
} {
    Specifies the contract between programmer and graphic designer for a page.
    When called with the magic "documentation-gathering" flag set
    (to be defined), the proc will record the information about this page, so
    it can be displayed as documentation. When called during normal
    page execution, it will validate the query string and set
    corresponding variables in the caller's environment.

    <p>

    Example:

    <blockquote><pre>ad_page_contract  {
        Some documentation.
        &#64;author me (my@email)
        &#64;cvs-id $Id$
    } {
        foo
        bar:integer,notnull,multiple,trim
        {greble:integer {[expr {[lindex $bar 0] + 1}]}}
    } -validate {
        greble_is_in_range -requires {greble:integer} {
            if { $greble &lt; 1 || $greble &gt; 100 } {
                ad_complain
            }
        }
        greble_exists -requires { greble_is_in_range } {
            if { ![info exists ::greble_values($greble)] } {
                ad_complain [_ acs-tcl.lt_Theres_no_greble_with]
            }
        }
    } -errors {
        foo {error message goes here}
        bar:integer,notnull {another error message}
        greble_is_in_range {Greble must be between 1 and 100}
    }</pre></blockquote>

    An argspec takes one of two forms, depending on whether there's a default value or not:

    <ol>
    <li><blockquote><code>{<i>name</i>[:<i>flag</i>,<i>flag</i>,<i>flag</i>] <i>default</i>}</code></blockquote></li>
    <li><blockquote><code><i>name</i>[:<i>flag</i>,<i>flag</i>,<i>flag</i>]</code></blockquote></li>
    </ol>

    <p>

    If no default value is specified, the argument is considered required, but the empty string is permissible unless you
    specify <code>:notnull</code>.  For all arguments, the filter <code>:nohtml</code> is applied by default.  If the arg
    is named <code>*.tmpfile</code>, the <code>tmpfile</code> filter is applied.

    <p>

    Possible flags are:

    <blockquote>

    <dl>

    <dt><b>trim</b>
    <dd>The value will be string trimmed.

    <dt><b>notnull</b>
    <dd>When set, will barf if the value is the empty string.
    Checked after processing the <code>trim</code> flag. If <b>not</b> set,
    the empty string is <b>always</b> considered valid input, and <b>no other
    filters are processed for that particular value</b>. If it's an array or
    multiple variable, the filters will still be applied for other values, though.

    <dt><b>optional</b>
    <dd>If there's a default value present,
    it's considered optional even without the flag. If a default is
    given, and the argument is present but blank, the default value will
    be used. Optional and no default value means the variable will not
    be set, if the argument is not present in the query string.

    <dt><b>multiple</b>
    <dd>
    If multiple is specified, the var
    will be set as a list of all the argument values
    (e.g. arg=val1&arg=val2 will turn into arg=[list val1 val2]).
    The defaults are filled in from left to right, so it can depend on
    values of arguments to its left.

    <dt><b>array</b>
    <dd>
    This syntax maps query variables into Tcl arrays. If you specify
    <code>customfield:array</code>, then query var <code>customfield.foo</code> will
    translate into the Tcl array entry <code>$customfield(foo)</code>. In other words:
    whatever comes after the dot is used as the key into the array,
    or, more mathematically: <code>x.y=z => set x(y) z</code>.
    If you use dot or comma is part of your key (i.e., <code>y</code> above contains comma or dot),
    then you can easily <code>split</code> on it in your Tcl code.
    Remember that you can use any other flag or filter with array.

    <dt><b>verify</b>
    <dd>Will invoke <a href="/api-doc/proc-view?proc=ad_verify_signature"><code>ad_verify_signature</code></a>
    to verify the value of the variable, to make sure it's the value that was output by us, and haven't been tampered with.
    If you use <a href="/api-doc/proc-view?proc=export_vars"><code>export_vars -form -sign</code></a>
    or <a href="/api-doc/proc-view?proc=export_vars"><code>export_vars -sign</code></a> to export the
    variable, use this flag to verify it. To verify a variable named <code>foo</code>, the verify flag
    looks for a form variable named <code>foo:sig</code>. For a <code>:multiple</code>, it only expects one single
    signature for the whole list. For <code>:array</code> it also expects one signature only, taken on the
    <code>[array get]</code> form of the array.

    <dt><b>cached</b>
    <dd>This syntax will check to see if a value is being passed in for this variable.  If it is not, it will then look in
    cache for this variable in the package that this page is located, and get this value if it exists.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_date"><b>date</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the array validates as a date.
    Use this filter with :array to do automatic date filtering.  To use it, set up in your HTML form
    a call to a date formfield.  Then on the receiving page, specify the filter using
    <code>varname:array,date</code>.  If the date validates, there will be a variable set in your
    environment <code>varname</code> with four keys: <code>day, month, year,</code> and <code>date</code>.
    You can safely pass <code>$varname(date)</code> to Oracle.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_time"><b>time</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the array validates as a time in
    am/pm format. That is that it has two fields: <code>time</code> and <code>ampm</code> that have
    valid values. Use this filter with :array to do automatic time filtering. To use it, set up
    in you HTML form using [ec_timeentrywidget varname] or equivalent. Then on the processing page
    specify the filter using <code>varname:array,time</code>. If the time validates, there will be
    a variable set in your environment <code>varname</code> with five keys: <code>time, ampm,
    hours, minutes,</code> and <code>seconds</code>.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_time24"><b>time24</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the array validates as a time in
    24hr format. That is that it has one field: <code>time</code> that has valid values. Use this
    filter with :array to do automatic time filtering. To use it, set up in you HTML form using
    &lt;input type="text" name="varname".time&gt;. Then on the processing page specify the filter using
    <code>varname:array,time24</code>. If the time validates, there will be a variable set in your
    environment <code>varname</code> with four keys: <code>time, hours, minutes,</code> and
    <code>seconds</code>.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_integer"><b>integer</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value is integer,
    and removed any leading zeros.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_naturalnum"><b>naturalnum</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value is a natural number, i.e.
    non-decimal numbers >= 0.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_oneof"><b>oneof</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value X contained in
    the set of the provided values. Usage example: <code>color:oneof(red|blue|green)</code>

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_range"><b>range</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value X is in range
    [Y, Z]. Usage example: <code>foo:range(1|100)</code>

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_nohtml"><b>nohtml</b></a>
    <dd>Pluggable filter, installed by default, that disallows any and all html.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_html"><b>html</b></a>
    <dd>Pluggable filter, installed by default, that only allows certain, safe allowed tags to pass
    (see <a href="proc-view?proc=ad_html_security_check">ad_html_security_check</a>).
    The purpose of screening naughty html is to prevent users from uploading
    HTML with tags that hijack page formatting or execute malicious code on the users's computer.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_allhtml"><b>allhtml</b></a>
    <dd>Pluggable filter, installed by default, that allows any and all html.  Use of this filter
    is not recommended, except for cases when the HTML will not be presented to the user or there is some
    other reason for overriding the site-wide control over naughty html.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_tmpfile"><b>tmpfile</b></a>
    <dd>Checks to see if the path and file specified by tmpfile are allowed on this system.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_sql_identifier"><b>sql_identifier</b></a>
    <dd>Pluggable filter, installed by default, that makes sure the value is a valid SQL identifier.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_path"><b>path</b></a>
    <dd>Pluggable filter, installed by default, that makes sure that argument contains only Tcl word
    characters or a few additional safe characters used in paths ("/", ".", "-")

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_token"><b>token</b></a>
    <dd>Pluggable filter, installed by default, that makes sure that argument contains only Tcl word
    characters or a few additional safe characters (",", ":", "-").

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_word"><b>word</b></a>
    <dd>Pluggable filter, installed by default, that makes sure that argument contains only Tcl word
    characters (as defined by \w in Tcl regular expressions, i.e. characters, digits and underscore).

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_localurl"><b>localurl</b></a>
    <dd>Pluggable filter, installed by default, that makes sure that argument contains a
    non-external url, which can be used in ad_returnredirect without throwing an error.

    <dt><a href="proc-view?proc=ad_page_contract_filter_proc_clock"><b>clock</b></a>
    <dd>Pluggable filter, installed by default, that makes sure that
    argument is a time string formatted according to the format
    specified in the flag. The format uses the syntax from the clock
    Tcl command. Usage example time:clock(%H:%M:%S).

    </dl>

    <a href="/api-doc/proc-search?query_string=ad_page_contract_filter_proc&search_type=Search&name_weight=5&param_weight=3&doc_weight=2">more filters...</a>

    </blockquote>

    <p>

    <b>Note</b> that there can be <em>no</em> spaces between name,
    colon, flags, commas, etc. The first space encountered denotes the
    beginning of the default value. Also, variable names can't contain
    commas, colons or anything Tcl accepts as list element separators
    (space, tab, newline, possibly others)
    If more than one value is specified for something that's not
    a multiple, a complaint will be thrown ("you supplied more than one value for foo").

    <p>

    There's an interface for enhancing ad_page_contract with <b>pluggable filters</b>, whose names
    can be used in place of flags
    (see <a href="proc-view?proc=ad_page_contract_filter"><code>ad_page_contract_filter</code></a>).
    There's also an interface for pluggable <b>filter rules</b>, which determine
    what filters are applied to arguments
    (see <a href="proc-view?proc=ad_page_contract_filter_rule"><code>ad_page_contract_filter_rule</code></a>).

    <p>

    Note on <strong>QQ-variables</strong>: Unlike the old <code>ad_page_variables</code>,
    <code>ad_page_contract</code> does <strong>not</strong> set QQ-versions of variables.
    The QQ-versions (had each single-quote replaced by two single-quotes) were only necessary
    for building up SQL statements directly in a Tcl string. Now that we're using bind variables,
    the QQ-variables aren't necessary anymore, and thus, <code>ad_page_contract</code> doesn't waste
    time setting them.

    <h3>Default Values</h3>

    <strong>Default values</strong> are filled in from left to right
    (or top to bottom), so it can depend on the values or variables that comes
    before it, like in the example above. Default values are <strong>only used when
    the argument is not supplied</strong>, thus you can't use default values to override the
    empty string. (This behavior has been questioned and may have to
                   be changed at a later point.)
    Also, default values are <em>not</em> checked, even if you've specified
    flags and filters. If the argument has the <b><code>multiple</code></b> flag specified,
    the default value is treated as a list. If the <b><code>array</code></b> flag is specified, we
    expect it to be in <code>array get</code> format, i.e. a list of <code>{ name value name value ... }</code>
    pairs. If both <b><code>multiple</code></b> and <b><code>array</code></b> are set, the <code>value</code> elements of the
    before-mentioned <code>array get</code> format are treated as lists themselves.

    <h3>Errors Argument</h3>

    The <b><code>-errors</code></b> block defines custom error messages. The format is a list in <code>array get</code> format
    with alternating error-names and error texts. The error names can be <code>foo</code>, which
    means it's thrown when the variable is not supplied. Or <code>foo:flag,flag,...</code>, which
    means it'll get thrown whenever one of the flags fail. If you want the same error to be
    thrown for both not supplying a var, and for a flag, you can say <code>foo<b>:,</b>flag,...</code>
    (a comma immediately after the colon).

    <h3>Validation Blocks</h3>

    The <b><code>-validate</code></b> is used to fully customized user input validation. The format is a list
    of named chunks of code, for example:

    <pre>-validate {
        <i>name</i> {
            <i>code block</i>
        }
        <i>another_name</i> -requires { <i>argname</i>[:<i>filter-or-validation-block-name</i>,...] ... } {
            <i>code block</i>
        }
    }</pre>


    The name is for use with the <code>-errors</code> block, and for use within the <code>-requires</code>
    argument of another validation block.
    The validation blocks will get executed after all flags and filters have been evaluated.
    The code chunk should perform some validation, and if it's unhappy it should call
    <a href="proc-view?proc=ad_complain"><code>ad_complain</code></a>, <i>optionally</i> with an error message.
    If no error message is specified, the error should be declared in the <code>-errors</code> section.

    <p>

    Each validation block can also have a <code>-requires</code> switch, which takes a list of
    validations that must already have been successfully passed, for the validation to get executed.
    The intent is that you want to provide as much feedback as possible at once, but you don't want
    redundant feedback, like "foo must be an integer" <em>and</em> "foo must be in range 10 to 20".
    So a check for foo in range 10 to 20 would have a <code>-requires { foo:integer }</code> switch,
    to ensure that the check only gets executed if foo was successfully validated as an integer.

    <p>

    In the <code>-requires</code> argument, you can specify a list of (1) the
    name of an argument, which means that the argument must be supplied.
    Or (2) you can specify <code><i>argname</i>:<i>filter</i></code> or
    <code><i>argname</i>:<i>validation_block</i></code> to say that a given filter, flag or
    valdiation block must have been executed <em>and</em> satisfied for this validation block to get executed.
    You can have as many requirements as you like.

    <p>

    @param docstring The documentation for your page;
                     will be parsed like ad_proc and ad_library.

    @param args If the first argument is not a switch, it should be the query arguments that this page accepts,
                in the form of a list of argument specs. See above.
                Otherwise, the query arguments can be passed with the -query switch.

    @param properties What properties the resulting document will contain.

    @param form Optionally supply the parameters directly here instead of fetching them from the page's form (ns_getform).
                This should be a reference to an ns_set.

    @author Lars Pind (lars@pinds.com)
    @author Yonatan Feldman (yon@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @creation-date 16 June 2000
} {
    ad_complaints_init $context

    ####################
    #
    # Parse arguments
    #
    ####################


    set query [list]

    if { [llength $args] > 0 } {
        set valid_args { validate errors return_errors properties }   ;# add type later

        # If the first arg isn't a switch, it should be the query
        if { [string index [lindex $args 0] 0] ne "-" } {
            set args [lassign $args query]
        } else {
            # otherwise, accept a -query argument
            lappend valid_args query
        }

        ad_arg_parser $valid_args $args
    }

    # reset $::ad_page_contract_variables
    if {[info exists ::ad_page_contract_variables]} {
        unset ::ad_page_contract_variables
    }

    ####################
    #
    #   Check supplied query form and set up variables in caller's environment
    #
    ####################
    #
    # These are the steps:
    # 1. go over the formal args, massaging it into an internal data structure that's easier to manipulate
    # 2. go over the form (actual args), match actual to formal args, apply filters
    # 3. go over the formal args again: defaulting, post filters, complain if required but not supplied
    # 4. execute the validation blocks
    #
    ####################


    ####################
    #
    # Step 1: Massage the query arg into some useful data structure.
    #
    ####################
    # BASIC STUFF:
    # list apc_formals                list of formals in the order specified by in the arguments
    # array apc_formal($name)         1 if there is a formal argument with that name
    # array apc_default_value($name)  the default value, if any
    #
    # FILTERS:
    # array apc_internal_filter($name:$flag):        1 if the given flag is set, undefined
    # array apc_filters($name):                      contains a list of the filters to apply
    # array apc_post_filters($name):                 contains a list of the post filters to apply
    # array apc_filter_parameters($name:$flag):      contains a list of the parameters for a filter
    #
    # DOCUMENTATION:
    # array apc_flags($name):         contains a list of the flags that apply
    #

    set apc_formals [list]
    array set apc_formal [list]
    array set apc_default_value [list]

    array set apc_internal_filter [list]
    array set apc_filters [list]
    array set apc_post_filters [list]
    array set apc_filter_parameters [list]

    array set apc_flags [list]

    foreach element $query {
        set element_len [llength $element]

        if { $element_len > 2 } {
            return -code error [_ acs-tcl.lt_Argspec_element_is_in]
        }

        set arg_spec [lindex $element 0]

        lassign [ad_page_contract_parse_argspec $arg_spec] name flags

        lappend apc_formals $name
        set apc_formal($name) 1

        if { $element_len == 2 } {
            set apc_default_value($name) [lindex $element 1]
        }

        set flag_list [list]

        # find parameterized flags
        foreach flag [ad_page_contract_split_argspec_flags $flags] {

            #
            # The following statement is transitional code, and should
            # help in the upgrading phase, when newer page_contracts
            # with "object_id" are processed, but the
            # page_contract_filter_proc is not yet defined.
            #
            if {$flag eq "object_id"
                && [info commands ad_page_contract_filter_proc_object_id] eq ""
            } {
                # fall back to "integer"
                set flag integer
                ns_log notice "Warning: page contract contains 'object_id', but filter proc is not available"
            }

            set left_paren [string first "(" $flag]
            if { $left_paren == -1 } {
                lappend flag_list $flag
            } else {
                if { [string index $flag end] ne ")" } {
                    return -code error "Missing or misplaced end parenthesis for flag '$flag' on argument '$name'"
                }
                set flag_parameters [string range $flag $left_paren+1 [string length $flag]-2]
                set flag [string range $flag 0 $left_paren-1]

                lappend flag_list $flag

                set apc_filter_parameters($name:$flag) \
                    [ad_page_contract_split_argspec_flag_parameters $flag_parameters]
            }
        }

        #
        # Apply filter rules
        #

        foreach filter_rule [array names ::acs::ad_page_contract_filter_rules] {
            [ad_page_contract_filter_rule_proc $filter_rule] $name flag_list
        }

        #
        # Sort the flag list according to priority
        #

        set flag_list_for_sorting [list]
        foreach flag $flag_list {
            lappend flag_list_for_sorting [list [ad_page_contract_filter_priority $flag] $flag]
        }
        set flag_list_sorted [lsort -index 0 $flag_list_for_sorting]

        #
        # Split flag_list up into the different kinds, i.e. internal, filter (classic) or post_filter.
        #
        # apc_flags($name) is for documentation only.
        #

        set apc_flags($name) [list]
        set apc_filters($name) [list]
        set apc_post_filters($name) [list]

        foreach flag_entry $flag_list_sorted {
            set flag [lindex $flag_entry 1]
            lappend apc_flags($name) $flag

            switch [ad_page_contract_filter_type $flag] {
                internal {
                    set apc_internal_filter($name:$flag) 1
                }
                filter {
                    lappend apc_filters($name) $flag
                }
                post {
                    lappend apc_post_filters($name) $flag
                }
                default {
                    return -code error "Unrecognized flag or filter \"$flag\" specified for query argument $name"
                }
            }
        }
    }

    ####################
    #
    # Documentation-gathering mode
    #
    ####################

    if { [api_page_documentation_mode_p] } {
        # Just gather documentation for this page

        ad_parse_documentation_string $docstring doc_elements

        # copy all the standard elements over
        foreach element { query properties } {
            if { [info exists $element] } {
                set doc_elements($element) [set $element]
            }
        }
        # then the arrays
        foreach element { apc_default_value apc_flags } {
            set doc_elements($element) [array get $element]
        }
        # then the array names
        set doc_elements(apc_arg_names) $apc_formals

        # figure out where the calling script is located, relative to the ACS root
        set root_dir [nsv_get acs_properties root_directory]
        set script [info script]
        set root_length [string length $root_dir]
        if { $root_dir eq [string range $script 0 $root_length-1 ] } {
            set script [string range $script $root_length+1 end]
        }

        error [array get doc_elements] "ad_page_contract documentation"
    }

    #
    # Page serving mode
    #

    ####################
    #
    # Parse -properties argument
    #
    ####################
    # This must happen even if the query (aka parameters, formals) is empty

    if { [info exists properties] } {
        upvar 1 __page_contract_property property
        array set property [doc_parse_property_string $properties]
    }

    # If there are no query arguments to process, we're done
    if { $query eq "" } {
        return
    }

    ####################
    #
    # Parse -validate block
    #
    ####################
    #
    # array apc_validation_blocks($name): an array of lists that contain the validation blocks
    #                                    the list will contain either 1 or 2 elements, a possible
    #                                    list of required completed filters/blocks and the code block
    #                                    for the validation block. Once the block has executed, this entry
    #                                    self destructs, i.e. unset apc_validation_blocks($name)

    array set apc_validation_blocks [list]

    if { ![info exists validate] } {
        set validate [list]
    }

    set validate_len [llength $validate]
    for { set i 0 } { $i < $validate_len } { incr i } {
        set name [lindex $validate $i]

        if { [string first : $name] != -1 } {
            return -code error [_ acs-tcl.lt_Validation_block_name]
        }
        if { [info exists apc_formal($name)] } {
            return -code error [_ acs-tcl.lt_You_cant_name_your_va]
        }
        if { [info exists apc_validation_blocks($name)] } {
            return -code error [_ acs-tcl.lt_You_cant_have_two_val]
        }

        incr i
        if { [string index [lindex $validate $i] 0] == "-" } {
            if { [lindex $validate $i] ne "-requires" } {
                return -code error [_ acs-tcl.lt_Valid_switches_are_-r]
            }
            set requires [lindex $validate [incr i]]

            foreach element $requires {
                if { [string first , $element] != -1 } {
                    return -code error [_ acs-tcl.lt_The_-requires_element]
                }
                set parts_v [split $element ":"]
                set parts_c [llength $parts_v]
                if { $parts_c > 2 }  {
                    return -code error [_ acs-tcl.lt_The_-requires_element_1]
                }
                set req_filter [lindex $parts_v 1]
                if { $req_filter in {array multiple} } {
                    return -code error "You can't require \"$req_name:$req_filter\" for block \"$name\"."
                }
            }
            incr i
        } else {
            set requires [list]
        }
        set code [lindex $validate $i]
        set apc_validation_blocks($name) [list $requires $code]
    }

    ####################
    #
    # Parse -errors argument
    #
    ####################

    if { [info exists errors] } {
        ad_complaints_parse_error_strings $errors
    }

    ####################
    #
    # Step 2: Go through all the actual arguments supplied in the form
    #
    ####################

    if { $form eq "" } {
        set form [ns_getform]
        if {$form eq "" && ![ns_conn isconnected]} {
            ad_log warning "ad_page_contract called with no form data and no connection; aborting request"
            ad_script_abort
        }
    }

    # This is the array in which we store the signature variables as we come across them
    # Whenever we see a variable named foo:sig, we record it here as apc_signatures(foo).
    array set apc_signatures [list]

    foreach {actual_name actual_value} [ns_set array $form] {
        #
        # Map actual argument to formal argument ... only complication is from arrays
        #

        # Check the name of the argument to passed in the form, ignore if not valid
        if { [regexp -nocase -- {^[a-z0-9_\-\.\:]*$} $actual_name] } {

            # The name of the formal argument in the page
            set formal_name $actual_name

            # This will be var(key) for an array
            set variable_to_set var

            # It may be a signature for another variable
            if { [regexp {^(.*):sig$} $actual_name match formal_name] } {
                set apc_signatures($formal_name) $actual_value
                # We're done with this variable
                continue
            }

            # If there is no formal with this name, _or_ the formal that has this name is an array,
            # in which case it can't be the right formal, since we'd have to have a dot and then the key
            if { ![info exists apc_formal($formal_name)] || [info exists apc_internal_filter($formal_name:array)] } {

                # loop over all the occurrences of dot in the argument name
                # and search for a variable spec with that name, e.g.
                # foo.bar.greble can be interpreted as foo(bar.greble) or foo.bar(greble)
                set found_p 0
                set actual_name_v [split $actual_name "."]
                set actual_name_c [expr { [llength $actual_name_v] - 1 }]
                for { set i 0 } { $i < $actual_name_c } { incr i } {
                    set formal_name [join [lrange $actual_name_v 0 $i] "."]
                    if { [info exists apc_internal_filter($formal_name:array)] } {
                        set found_p 1
                        set variable_to_set var([join [lrange $actual_name_v $i+1 end] "."])
                        break
                    }
                }
                if { !$found_p } {
                    # The user supplied a value for which we didn't have any arg_spec
                    # It might be safest to fail completely in this case, but for now,
                    # we just ignore it and go on with the next arg
                    continue
                }
            }

            if { [info exists apc_internal_filter($formal_name:multiple)]
                 && $actual_value eq ""
             } {
                # LARS:
                # If you lappend an empty_string, it'll actually add the empty string to the list as an element
                # which is not what we want
                continue
            }

            # Remember that we've found the spec so we don't complain that this argument is missing
            ad_page_contract_set_validation_passed $formal_name

            #
            # Apply filters
            #

            if { [info exists apc_internal_filter($formal_name:trim)] } {
                set actual_value [string trim $actual_value]
                ad_page_contract_set_validation_passed $formal_name:trim
            }

            if { $actual_value eq "" } {
                if { [info exists apc_internal_filter($formal_name:notnull)] } {
                    ad_complain -key $formal_name:notnull [_ acs-tcl.lt_You_must_specify_some]
                    continue
                } else {
                    ad_page_contract_set_validation_passed $formal_name:notnull
                }
            } else {
                set ::ad_page_contract_validations_passed($formal_name:notnull) 1

                foreach filter $apc_filters($formal_name) {
                    set ::ad_page_contract_errorkeys [concat $formal_name:$filter $::ad_page_contract_errorkeys]
                    set filter_proc [ad_page_contract_filter_proc $filter]
                    if { ![info exists apc_filter_parameters($formal_name:$filter)] } {
                        set filter_ok_p [$filter_proc $formal_name actual_value]
                    } else {
                        set filter_ok_p [$filter_proc $formal_name actual_value $apc_filter_parameters($formal_name:$filter)]
                    }
                    set ::ad_page_contract_errorkeys [lrange $::ad_page_contract_errorkeys 1 end]

                    if { $filter_ok_p } {
                        set ::ad_page_contract_validations_passed($formal_name:$filter) 1
                    } else {
                        break
                    }
                }
            }

            #
            # Set the variable in the caller's environment
            #

            upvar 1 $formal_name var

            if { [info exists apc_internal_filter($formal_name:multiple)] } {
                lappend $variable_to_set $actual_value
            } else {
                if { [info exists $variable_to_set] } {
                    set complaint [_ acs-tcl.lt_Youve_supplied_two_va]
                    ad_complain -key $formal_name:-doublevalue $complaint
                    ad_log warning "User experienced '$complaint' when submitting a form related to path_info: [ad_conn path_info]"
                    continue
                } else {
                    set $variable_to_set $actual_value
                }
            }
        } else {
            ad_log warning "ad_page_contract: attempt to use a nonstandard variable name in form: '$actual_name'"
        }
    }


    ####################
    #
    # Step 3: Pass over each formal argument to make sure all the required
    # things are there, and setting defaults if they're provided,
    # apply post filters, and validate signatures.
    #
    ####################

    foreach formal_name $apc_formals {

        upvar $level $formal_name var

        if { [info exists apc_internal_filter($formal_name:cached)] } {
            if { ![ad_page_contract_get_validation_passed_p $formal_name]
                 && ![info exists apc_internal_filter($formal_name:notnull)]
                 && (![info exists apc_default_value($formal_name)]
                     || $apc_default_value($formal_name) eq "")
             } {
                if { [info exists apc_internal_filter($formal_name:array)] } {
                    # This is an array variable, so we need to loop through each name.* variable for this package we have ...
                    set array_list ""
                    foreach arrayvar [ns_cache names util_memoize] {
                        if {[regexp [list [ad_conn session_id] [ad_conn package_id] "$formal_name."] $arrayvar]} {
                            set arrayvar [lindex $arrayvar [llength $arrayvar]-1]
                            if { $array_list ne "" } {
                                append array_list " "
                            }
                            set arrayvar_formal [string range $arrayvar [string first "." $arrayvar]+1 [string length $arrayvar]]
                            append array_list "{$arrayvar_formal} {[ad_get_client_property [ad_conn package_id] $arrayvar]}"
                        }
                    }
                    set apc_default_value($formal_name) $array_list
                } else {
                    set apc_default_value($formal_name) [ad_get_client_property [ad_conn package_id] $formal_name]
                }
            }
        }

        #
        # Perform these checks only, when the validation is passed and
        # a we have a value for the variable
        #
        if { [ad_page_contract_get_validation_passed_p $formal_name] && [info exists var]} {

            if { [info exists apc_internal_filter($formal_name:verify)] } {
                if { ![info exists apc_internal_filter($formal_name:array)] } {
                    # This is not an array, verify the scalar variable
                    if { ![info exists apc_signatures($formal_name)]
                         || ![ad_verify_signature \
                                  -secret [ns_config "ns/server/[ns_info server]/acs" parameterSecret ""] \
                                  $var $apc_signatures($formal_name)]
                     } {
                        ad_complain -key $formal_name:verify [_ acs-tcl.lt_The_signature_for_the]
                        continue
                    }
                } else {
                    # This is an array: verify the [array get] form of the array
                    if { ![info exists apc_signatures($formal_name)]
                         || ![ad_verify_signature \
                                  -secret [ns_config "ns/server/[ns_info server]/acs" parameterSecret ""] \
                                  [lsort [array get var]] $apc_signatures($formal_name)]
                     } {
                        ad_complain -key $formal_name:verify [_ acs-tcl.lt_The_signature_for_the]
                        continue
                    }
                }
            }

            # Apply post filters
            foreach filter $apc_post_filters($formal_name) {
                ad_complaints_with_key $formal_name:$filter {
                    set filter_proc [ad_page_contract_filter_proc $filter]
                    if { ![info exists apc_filter_parameters($formal_name:$filter)] } {
                        set filter_ok_p [$filter_proc $formal_name var]
                    } else {
                        set filter_ok_p [$filter_proc $formal_name var $apc_filter_parameters($formal_name:$filter)]
                    }
                }
                if { $filter_ok_p } {
                    ad_page_contract_set_validation_passed $formal_name:$filter
                } else {
                    break
                }
            }

        } else {
            #
            # No value supplied for this arg spec.
            #
            if { [info exists apc_default_value($formal_name)] } {
                #
                # Only use the default value if there has been no
                # complaints so far Why? Because if there are
                # complaints, the page isn't going to serve anyway,
                # and because one default value may depend on another
                # variable having a correct value.
                #
                if { [ad_complaints_count] == 0 } {
                    # we need to set the default value
                    if { [info exists apc_internal_filter($formal_name:array)] } {
                        array set var [uplevel subst \{$apc_default_value($formal_name)\}]
                    } else {
                        set var [uplevel subst \{$apc_default_value($formal_name)\}]
                    }
                }

            } elseif { ![info exists apc_internal_filter($formal_name:optional)]
                       && ![info exists ::ad_page_contract_validations_passed($formal_name)] } {
                #
                # The element is not optional and it was not already
                # flagged by the notnull constraint.
                #
                # Before we complain, we check, if a multirow or array
                # with the name are already defined in the target
                # environment. This is just used for cases, where
                # multirows are passed to an "ad_include
                # contract". These data types are not copied to the
                # ns_set and therefore these are not seen by the above
                # tests. No further checking other than check for
                # existence is performed for these cases.
                #
                set multirow_name $formal_name:rowcount
                if {![uplevel $level [list info exists $multirow_name]]
                    && ![uplevel $level [list info exists $formal_name]]
                } {
                    ad_complain -key $formal_name [_ acs-tcl.lt_You_must_supply_a_val]
                }
            }
        }
    }

    ####################
    #
    # Step 4: Execute validation blocks
    #
    ####################

    set done_p 0
    while { !$done_p } {

        set done_p 1
        foreach validation_name [array names apc_validation_blocks] {
            lassign $apc_validation_blocks($validation_name) dependencies code

            set dependencies_met_p 1
            #
            # Check, of the variables of the dependencies were provided.
            #
            foreach dependency $dependencies {
                set varName [lindex [split $dependency ":"] 0]
                if { ![ad_page_contract_get_validation_passed_p $varName] } {
                    # var $varName was not provided
                    set dependencies_met_p 0
                    break
                }
            }

            #
            # Check, whether the earlier section haven't returned
            # errors, in which case the detailed validation is not
            # necessary.
            #
            if { $dependencies_met_p && [ad_complaints_count] > 0} {
                set dependencies_met_p 0
            }

            if { $dependencies_met_p } {

                # remove from validation blocks array, so we don't execute the same block twice
                unset apc_validation_blocks($validation_name)

                set no_complaints_before [ad_complaints_count]

                # Execute the validation block with an environment with a default error key set
                set ::ad_page_contract_errorkeys [concat $validation_name $::ad_page_contract_errorkeys]
                set validation_ok_p [ad_page_contract_eval uplevel 1 $code]
                set ::ad_page_contract_errorkeys [lrange $::ad_page_contract_errorkeys 1 end]

                if { $validation_ok_p eq ""
                     || ($validation_ok_p ne "1" && $validation_ok_p ne "0" )
                 } {
                    set validation_ok_p [expr {[ad_complaints_count] == $no_complaints_before}]
                }

                if { $validation_ok_p } {
                    set ::ad_page_contract_validations_passed($validation_name) 1
                    # more stuff to process still
                    set done_p 0
                }

            }
        }
    }

    ####################
    #
    # Done. Spit out error, if any
    #
    ####################

    # Initialize the list of page variables for other scripts to use
    set ::ad_page_contract_variables $apc_formals

    if { [ad_complaints_count] > 0 } {

        set complaints [ad_complaints_get_list]
        if {$warn_p} {
            ad_log warning "contract in '$::ad_page_contract_context'"\
                "was violated:\n" [join $complaints "\n "]
        }

        if { [info exists return_errors] } {
            upvar 1 $return_errors error_list
            set error_list $complaints
        } else {
            template::multirow create complaints text
            foreach elm $complaints {
                template::multirow append complaints $elm
            }
            ad_try {
                if {[ns_conn isconnected] == 0} {
                    ad_script_abort
                }
                if {[incr ::__ad_complain_depth] == 1} {
                    #
                    # Render the error page going through templating,
                    # theming and so on.
                    #
                    # This is the intended complaint behavior, where
                    # the page will look "fancy" and consistent with
                    # the rest of the website.
                    #
                    set context $::ad_page_contract_context
                    set prev_url [util::get_referrer -trusted]
                    set html [ad_parse_template \
                                  -params [list \
                                               complaints [list context $context] \
                                               prev_url] \
                                  [template::themed_template "/packages/acs-tcl/lib/complain"]]
                } else {
                    #
                    # We detected a recursion. This can happen if the
                    # templates involved in rendering the complaint
                    # also fail their own validation.
                    #
                    # We fallback to a basic rendering that won't
                    # involve any other template in order to break the
                    # cycle.
                    #
                    ad_log warning "Depth of recursive complaints exceeded. We will return a basic rendering."
                    set html [subst {
                        <html>
                           <head>
                              <title>[_ acs-tcl.lt_Problem_with_your_inp]</title>
                           </head>
                           <body>
                              <ul>
                              <li>[join $complaints </li><li>]</li>
                              </ul>
                           </body>
                        </html>
                    }]
                }
            } on error {errorMsg} {
                set errorCode $::errorCode
                #
                # Check, if we were called from "ad_script_abort" (intentional abortion)
                #
                if {[ad_exception $errorCode] eq "ad_script_abort"} {
                    #
                    # Yes, this was an intentional abortion
                    #
                    return ""
                }
                ad_log error "problem rendering complain page: $errorMsg ($errorCode) $::errorInfo"
                set html "Invalid input"
            }
            ns_return 422 text/html $html
            ad_script_abort
        }
    }
}

ad_proc -public ad_page_contract_get_variables { } {
    Returns a list of all the formal variables specified in
    ad_page_contract. If no variables have been specified, returns an
    empty list.
} {
    if { [info exists ::ad_page_contract_variables] && $::ad_page_contract_variables ne "" } {
        return $::ad_page_contract_variables
    }
    return [list]
}

ad_proc ad_include_contract {docstring args} {

    Define an interface between a page and an ADP &lt;include&gt;
    similar to the page_contract. This is a light-weight
    implementation based on the ad_page_contract. It allows one to
    check the passed arguments (types, optionality) and can be used
    for setting defaults the usual way.  Using ad_include_contracts
    helps to improve documentation of included content.

    @param docstring documentation of the include
    @param args passed parameter
    @see ad_page_contract

    @author gustaf neumann (neumann@wu-wien.ac.at)
    @creation-date Sept 2015
} {
    set __cmd {ns_set create include}
    foreach __v [uplevel {info vars}] {
        if {[string match __* $__v]
            || [regexp {[a-zA-Z]:[a-z0-9]} $__v]
            || ![uplevel [list info exists $__v]]
        } {
            #
            # Don't add internal variables (starting with __*),
            # multirow variables, or vars without values into the
            # ns_set used for checking
            #
            continue
        }
        if {[uplevel [list array exists $__v]]} {
            #
            # For the time being, do nothing with arrays
            #
            # ns_log notice "$__v is an array"
            # if {[string match *:* $__v] || [uplevel [list info exists $__v:rowcount]]} {
            #     #
            #     # don't try to pass multirows
            #     #
            # } else {
            #     #lappend __cmd $__v [uplevel [list array get $__v]]
            # }
            continue
        }

        #ns_log notice "V=$__v exists: [uplevel [list info exists $__v]]"
        lappend __cmd $__v [uplevel [list set $__v]]
    }

    #ns_log notice "final command: $__cmd"

    if {[uplevel {info exists __adp_remember_stub}]} {
        set __path [string range [uplevel {set __adp_remember_stub}] [string length $::acs::rootdir]+1 end]
        set __context "include $__path"
    } else {
        set __context ""
    }

    ad_page_contract -warn -level 2 -context $__context -form [{*}$__cmd] $docstring {*}$args
}

####################
#
# Filter subsystem
#
####################
#
# ad_page_contract_filters($flag) = [list $type $proc_name $doc_string $script $priority]
# ad_page_contract_mutex(filters) = mutex
#
# types are: internal, filter, post
#

if { [apm_first_time_loading_p] } {

    set internal_filters {
        multiple  {internal}
        array     {internal}
        optional  {internal}
        trim      {internal}
        notnull   {internal}
        verify    {internal}
        cached    {internal}
    }
    nsv_array set ad_page_contract_filters $internal_filters
    array set ::acs::ad_page_contract_filters $internal_filters
    nsv_array set ad_page_contract_filter_rules {}
    array set ::acs::ad_page_contract_filter_rules {}

    nsv_set ad_page_contract_mutex filters [ns_mutex create page_contract_filter]
    nsv_set ad_page_contract_mutex filter_rules [ns_mutex create page_contract_filter_rule]
}

ad_proc -public ad_page_contract_filter {
    -deprecated:boolean
    {-type filter}
    {-priority 1000}
    name
    proc_args
    doc_string
    body
} {
    Declare a filter to be available for use in ad_page_contract.
    <p>
    Here's an example of how to declare a filter:

    <pre>
    ad_page_contract_filter integer { name value } {
        Checks whether the value is a valid integer, and removes any leading zeros so as
        not to confuse Tcl into thinking it's octal
    } {
        if { ![regexp {^[0-9]+$} $value] } {
            ad_complain [_ acs-tcl.lt_Value_is_not_an_integ]
            return 0
        }
        set value [util::trim_leading_zeros $value]
        return 1
    }
    </pre>

    After the filter has been declared, it can be used as a flag in <code>ad_page_contract</code>, e.g.
    <pre>
    ad_page_contract {
        foo:integer
    } {}
    </pre>

    <b>Note</b> that there's only one global namespace for names. At some point,
    we might add package-local filters, but we don't have it yet.

    <p>

    The filter proc <b>must</b> return either 1 if it accepts the value or 0 if it rejects it.
    Any problem with the value is reported using <b><code>ad_complain</code></b>
    (see documentation for this). <b>Note:</b>
    Any modifications you make to value from inside your code block <b>will modify
    the actual value being set in the page.</b>

    <p>

    There are two types of filters. They differ in scope for variables that are <b>multiple</b> or <b>array</b>.
    The standard type of filter (<b>filter classic</b>) is invoked on each individual value before it's being put into the
    list or the array. A <b>post filter</b> is invoked after all values have been collected, and is invoked on the
    list or array as a whole.

    <p>

    @param type The type of filter; i.e. <code>filter</code> or <code>post</code>. Default is <code>filter</code>.

    @param name The name of the flag as used in <code>ad_page_contract</code>

    @param proc_args the arguments to your filter. The filter must
    take three arguments, <code>name</code>, <code>value</code>, and <code>parameters</code>, although you can name them
    any way you want. The first will be set to the name of the variable, the second will <b>be upvar'd</b> to the value,
    so that any change you make to the value will be reflected in the value ultimately being set in the page's
    environment, and the third is a list of arguments to the filter. This third argument can have multiple parameters
    split by <code>|</code> with no spaces or any other characters. Something like <code>foo:range(3|5)</code>

    @param body The body is a procedure body that performs the
    filtering. It'll automatically have one argument named
    <code>value</code> set, and it must either return the possibly
    transformed value, or throw an error. The error message will
    be displayed to the user.

    @param doc_string Standard documentation-string. Tell other programmers what your filter does.

    @param deprecated used to flag a filter as deprecated

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {

    if { ![string is wordchar $name] || $name eq "" } {
        return -code error [_ acs-tcl.lt_Flag_name_must_be_a_v]
    }
    if { [string tolower $name] ne $name } {
        return -code error [_ acs-tcl.lt_Flag_names_must_be_al]
    }
    if { ![string match $type filter] && ![string match $type post] } {
        return -code error [_ acs-tcl.lt_Filter_type_must_be_f]
    }

    set proc_args_len [llength $proc_args]

    if { $proc_args_len != 2 && $proc_args_len != 3 } {
        return -code error [_ acs-tcl.lt_Invalid_number_of_arg]
    }

    set script [info script]
    set proc_name ad_page_contract_filter_proc_$name

    #
    # Register the filter
    #

    set mutex [nsv_get ad_page_contract_mutex filters]
    ns_mutex lock $mutex

    set prior_type [ad_page_contract_filter_type $name]

    if {$prior_type eq "internal"} {
        ns_mutex unlock $mutex
        return -code error [_ acs-tcl.lt_The_flag_name_name_is]
    } elseif { $prior_type ne "" } {
        set prior_script [ad_page_contract_filter_script $name]
        if { $prior_script ne $script } {
            ns_log Warning [_ acs-tcl.lt_Multiple_definitions_]
        }
    }
    set filter_info [list $type $proc_name $doc_string $script $priority]
    set ::acs::ad_page_contract_filters($name) $filter_info
    nsv_set ad_page_contract_filters $name $filter_info
    ns_mutex unlock $mutex

    #
    # Declare the proc
    #

    # this may look complicated, but it's really pretty simple:
    # If you declare a filter like this: ad_page_contract_filter foo { name value } { ... }
    # it turns into this proc:
    # ad_proc ad_page_contract_filter_proc_foo { name value_varname } { upvar $value_varname value ; ... }
    # so that when the filter proc is passed the name of a variable, the body of the proc
    # will have access to that variable as if the value had been passed.

    set visibility [expr {$deprecated_p ? "-deprecated" : "-public"}]

    lassign $proc_args arg0 arg1 arg2
    if { $proc_args_len == 2 } {
        ad_proc $visibility $proc_name [list $arg0 ${arg1}_varname] $doc_string "upvar \$${arg1}_varname $arg1\n$body"
    } else {
        ad_proc $visibility $proc_name [list $arg0 ${arg1}_varname $arg2] $doc_string "upvar \$${arg1}_varname $arg1\n$body"
    }
}

ad_proc ad_page_contract_filter_type { filter } {
    Returns the type of proc that executes the given ad_page_contract filter,
    or the empty string if the filter is not defined.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if {[info exists ::acs::ad_page_contract_filters($filter)]} {
        return [lindex [set ::acs::ad_page_contract_filters($filter)] 0]
    }
    if { [nsv_exists ad_page_contract_filters $filter] } {
        return [lindex [nsv_get ad_page_contract_filters $filter] 0]
    } else {
        return {}
    }
}

ad_proc ad_page_contract_filter_proc { filter } {
    Returns the proc that executes the given ad_page_contract filter.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    #
    # No need to go to the nsv causing mutex locks; note that the
    # name of the filter-procs is more or less hardcoded in the
    # doc-strings above.
    #
    return ad_page_contract_filter_proc_$filter
    #return [lindex [nsv_get ad_page_contract_filters $filter] 1]
}

ad_proc ad_page_contract_filter_script { filter } {
    Returns the type of proc that executes the given ad_page_contract filter,
    or the empty string if the filter is not defined.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return [lindex [set ::acs::ad_page_contract_filters($filter)] 3]
    #return [lindex [nsv_get ad_page_contract_filters $filter] 3]
}

ad_proc ad_page_contract_filter_priority { filter } {
    Returns the type of proc that executes the given ad_page_contract filter,
    or the empty string if the filter is not defined.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return [lindex [set ::acs::ad_page_contract_filters($filter)] 4]
    #return [lindex [nsv_get ad_page_contract_filters $filter] 4]
}

ad_proc ad_page_contract_filter_invoke {
    filter
    name
    value_varname
    {parameters ""}
} {
    Invokes a filter on the argument and returns the result (1 or 0).
    The value may be modified during the invocation of the filter.

    @param filter the name of the filter to invoke
    @param name the logical name of the variable to filter
    @param value_varname the name of the variable holding the value to be filtered.
    @param parameters any arguments to pass to the filter

    @author Lars Pind (lars@pinds.com)
    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    upvar $value_varname value
    set filter_proc [ad_page_contract_filter_proc $filter]
    set filter_result [$filter_proc $name value {*}$parameters]
    if { $filter_result } {
        ad_page_contract_set_validation_passed $name:$filter
    }
    return $filter_result
}

####################
#
# Filter rules
#
####################

#
# ad_page_contract_filter_rules($name) = [list $proc_name $doc_string $script]
# ad_page_contract_mutex(filter_rules) = mutex
#

ad_proc ad_page_contract_filter_rule {
    name
    proc_args
    doc_string
    body
} {
    A filter rule determines what filters are applied to a given value. The code is passed the
    name of the formal argument and the list of filters currently being applied, and should
    on that basis modify the list of filters to suit its needs. Usually, a filter rule will add
    a certain filter, unless some list of filters are already present.

    <p>

    Unlike the filters themselves (registered with <code>ad_page_contract_filter</code>), all rules
    are always applied to all formal arguments of all pages.

    @param name filter rules must be named. The name isn't referred to anywhere.

    @param proc_args the filter rule proc must take two arguments, <code>name</code> and <code>filters</code>,
           although you can name them as you like. The first will be set to the name of the formal argument,
           the second will <b>be upvar'd</b> to the list of filters, so that any modifications you make to this list
           are reflected in the actual list of filters being applied.

    @param doc_string let other programmers know what your filter rule does.

    @param body the code to manipulate the filter list.

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [llength $proc_args] != 2 } {
        return -code error [_ acs-tcl.lt_The_proc_must_accept_]
    }

    set script [info script]
    set proc_name ad_page_contract_filter_rule_proc_$name
    set rule_key ::acs::ad_page_contract_filter_rules($name)

    set mutex [nsv_get ad_page_contract_mutex filter_rules]
    ns_mutex lock $mutex

    if {[info exists $rule_key]} {
        set prior_script [set $rule_key]
    } elseif { [nsv_exists ad_page_contract_filter_rules $name] } {
        set prior_script [ad_page_contract_filter_rule_script $name]
    }

    if { [info exists prior_script] && $script ne $prior_script } {
        ns_log Warning "Multiple definitions of the ad_page_contract_filter_rule \"$name\" in $script and $prior_script"
    }

    set rule_info [list $proc_name $doc_string $script]
    nsv_set ad_page_contract_filter_rules $name $rule_info
    set $rule_key $rule_info
    ns_mutex unlock $mutex

    # same trick as ad_page_contract_filter does.

    lassign $proc_args arg0 arg1
    ad_proc $proc_name [list $arg0 ${arg1}_varname] $doc_string "upvar \$${arg1}_varname $arg1\n$body"
}

ad_proc ad_page_contract_filter_rule_proc { filter } {
    Returns the proc that executes the given ad_page_contract default-filter.
} {
    return [lindex $::acs::ad_page_contract_filter_rules($filter) 0]
    #return [lindex [nsv_get ad_page_contract_filter_rules $filter] 0]
}

ad_proc ad_page_contract_filter_rule_script { filter } {
    Returns the proc that executes the given ad_page_contract default-filter.
} {
    return [lindex $::acs::ad_page_contract_filter_rules($filter) 2]
    #return [lindex [nsv_get ad_page_contract_filter_rules $filter] 2]
}

####################
#
# Declare standard filters
#
####################

ad_page_contract_filter integer { name value } {
    Checks whether the value is a valid integer, and removes any leading zeros so as
    not to confuse Tcl into thinking it's octal. Allows negative numbers.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    #
    # We can't really use "string is integer -strict", since it allows
    # numbers, which are invalid for e.g. SQL... e.g. "0x40".
    #
    ## First simple a quick check avoiding the slow regexp
    #if {[string is integer -strict $value]} {
    #    return 1
    #}

    if { [regexp {^(-)?(\d+)$} $value _ sign rest] } {
        # Trim the value for any leading zeros
        set value $sign[util::trim_leading_zeros $rest]
        # the string might be still too large, so check again...
        if {[string is integer -strict $value]} {
            return 1
        }
    }
    ad_complain [_ acs-tcl.lt_name_is_not_an_intege]
    return 0
}

ad_page_contract_filter naturalnum { name value } {
    Checks whether the value is a valid integer >= 0,
    and removes any leading zeros so as
    not to confuse Tcl into thinking it's octal.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {

    # We can't really use "string is integer -strict", since it allows
    # numbers, which are invalid for e.g. SQL... e.g. "0x40".
    #
    # First a simple quick check to avoid the slow regexp
    # if {[string is integer -strict $value] && $value >= 0} {
    #    return 1
    # }

    # Check with leading zeros, but no "-" allowed, so it must be positive
    if { [regexp {^(0*)([1-9][0-9]*|0)$} $value match zeros value] } {
        if {[string is integer -strict $value]} {
            return 1
        }
    }

    ad_complain [_ acs-tcl.lt_name_is_not_a_natural]
    return 0
}

ad_page_contract_filter object_id { name value } {

    Checks whether the value is a valid object_id, i.e. in the range
    defined for the SQL datatype "integer", which is the same for
    Oracle and PostgreSQL. In case, object_types are altered in future
    versions of OpenACS to e.g. "longinteger", this function has to be
    adjusted as well.

    The function is essentially the same as ad_page_contract_filter
    "integer", but with the additional value range check.

    @author Gustaf Neumann
    @creation-date May 23, 2021

} {
    if { [regexp {^(-)?(\d+)$} $value _ sign rest] } {
        set value $sign[util::trim_leading_zeros $rest]
        if {[string is integer -strict $value]
            && $value >= -2147483648
            && $value <= 2147483647 } {
            return 1
        }
    }
    ad_complain [_ acs-tcl.lt_name_is_not_an_oid]
    return 0
}

ad_page_contract_filter object_type { name object_id types } {

    Checks whether the supplied object_id is an acs_object of one of
    the types specified in the flag parameters.

    The check will take the object_type hierarchy into account
    e.g. will always succeed if one of the types is "acs_object". In
    this case the filter will just behave as an existence check.

    Example: some_user_id:object_type(user),notnull

} {
    if { $types eq "" } {
        set types acs_object
    }

    # First make sure the object_id is formally correct
    if { ![ad_page_contract_filter_proc_object_id $name object_id] } {
        return 0
    }

    if { ![acs_object::is_type_p \
               -object_id $object_id \
               -object_types $types] } {
        ad_complain [_ acs-tcl.lt_invalid_object_type]
        return 0
    }

    return 1
}

ad_page_contract_filter range { name value range } {
    Checks whether the value falls between the specified range.
    Range must be a list of two elements: min and max.
    Example spec:     w:range(3|7)


    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date August 18, 2000
} {
    if { [llength $range] != 2 } {
        error [_ acs-tcl.lt_Invalid_number_of_par]
        ad_script_abort
    }

    lassign $range min max
    set value [util::trim_leading_zeros $value]

    if { ![string is integer -strict $value] || $value < $min || $value > $max } {
        ad_complain [_ acs-tcl.lt_name_is_not_in_the_ra]
        return 0
    }
    return 1
}

ad_page_contract_filter oneof { name value set } {
    Checks whether the value is contained in the set of provided values.
    Example spec:     w:oneof(red|green)

    @author Gustaf Neumann
    @creation-date Feb, 2018
} {
    if { $value ni $set } {
        ad_complain [_ acs-tcl.lt_name_is_not_valid]
        return 0
    }
    return 1
}


ad_page_contract_filter sql_identifier { name value } {
    Checks whether the value is a valid SQL identifier
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { ![string is wordchar $value] } {
        ad_complain [_ acs-tcl.lt_name_is_not_a_valid_S]
        return 0
    }
    return 1
}

ad_page_contract_filter allhtml { name value } {
    Allows any html tags (a no-op filter)
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    return 1
}

ad_page_contract_filter nohtml { name value } {
    Doesn't allow any HTML to pass through.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [string first < $value] >= 0 } {
        ad_complain [_ acs-tcl.lt_Value_for_name_contai]
        return 0
    }
    return 1
}

ad_page_contract_filter dbtext { name value } {
    Ensure that the value can be used in an SQL query.

    Note that this is not the same as quoting or otherwise ensuring
    the safety of the statement itself. What we enforce here is that
    the value will be accepted by the db interface without
    complaining. The actual definition may change or be database
    specific in the future.
} {
    #
    # Reject the NUL character
    #
    if {[string first \u00 $value] != -1} {
        ad_complain [_ acs-tcl.lt_name_contains_invalid]
        return 0
    }

    return 1
}

ad_page_contract_filter html { name value } {
    Checks whether the value contains naughty HTML
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    #
    # Reject the NUL character
    #
    if {[string first \u00 $value] != -1} {
        ns_log notice "invalid input for 'html' filter: passed-in value contains NUL character"
        ad_complain [_ acs-tcl.lt_name_contains_invalid]
        return 0
    }

    set naughty_prompt [ad_html_security_check $value]
    if { $naughty_prompt ne "" } {
        ad_complain $naughty_prompt
        return 0
    }
    return 1
}

ad_page_contract_filter tmpfile { name value } {
    Validate a tmpfile path. This must exist, be a direct child of the
    configured tmpfolder in the server-wide parameter and be readable
    and writable by the current user.

    Example usage: uploaded_file.tmpfile:tmpfile,optional

    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    set tmpfile_p [security::safe_tmpfile_p \
                       -must_exist \
                       $value]

    if {!$tmpfile_p} {
        ad_log warning "They tried to sneak in invalid tmpfile '$value'"
        ad_complain [_ acs-tcl.lt_You_specified_a_path_]
    }

    return $tmpfile_p
}

ad_page_contract_filter clock { name value {formats "%Y-%m-%d"} } {
    Ensures the supplied date string is in one of the specified clock
    formats.

    @author Antonio Pisano
    @see clock
} {
    set valid_p 0
    foreach format $formats {
        if { ![catch { clock scan $value -format $format } errmsg] } {
            set valid_p 1
            break
        }
    }

    if {!$valid_p} {
        set time(time) [ns_quotehtml $value]
        ad_complain [_  acs-tcl.lt_Invalid_time_timetime_2]
    }

    return $valid_p
}

ad_page_contract_filter -type post date { name date } {
    Validates date type variables
    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    foreach date_element { day month year } {
        if { ![info exists date($date_element)] } {
            ad_complain [_ acs-tcl.lt_Invalid_date_date_ele]
            return 0
        }
    }

    # check if all elements are blank
    if { "$date(day)$date(month)$date(year)" eq ""} {
        set date(date) {}
        return 1
    }

    foreach date_element { day year } {
        if { ![regexp {^(0*)(([1-9][0-9]*|0))$} $date($date_element) match zeros real_value] } {
            ad_complain [_ acs-tcl.lt_Invalid_date_date_ele_1]
            return 0
        }
        set date($date_element) $real_value
    }

    if { $date(year) ne "" && [string length $date(year)] != 4 } {
        ad_complain [_ acs-tcl.lt_Invalid_date_The_year]
        return 0
    }

    if { [regexp {^(0*)(([1-9][0-9]*|0))$} $date(month) match zeros real_value] } {
        set date(month) $real_value
    } else {
        set months_list {January February March April May June July August September October November December}
        set date(month) [expr {[lsearch $months_list $date(month)] + 1}]
    }

    if {
        "" eq $date(month)
        || "" eq $date(day)
        || "" eq $date(year)
        || $date(month) < 1 || $date(month) > 12
        || $date(day) < 1 || $date(day) > 31
        || $date(year) < 1
        || ($date(month) == 2 && $date(day) > 29)
        || (($date(year) % 4) != 0 && $date(month) == 2 && $date(day) > 28)
        || ($date(month) == 4 && $date(day) > 30)
        || ($date(month) == 6 && $date(day) > 30)
        || ($date(month) == 9 && $date(day) > 30)
        || ($date(month) == 11 && $date(day) > 30)
    } {
        ad_complain [_ acs-tcl.lt_Invalid_date_datemont]
        return 0
    }

    set date(date) [format "%04d-%02d-%02d" $date(year) $date(month) $date(day)]
    return 1
}

ad_page_contract_filter -type post time { name time } {
    Validates time type variables of the regular variety (that is 8:12:21 PM)

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    foreach time_element { time ampm } {
        if { ![info exists time($time_element)] } {
            ad_complain [_ acs-tcl.lt_Invalid_time_time_ele]
            return 0
        }
    }

    # check if all elements are blank
    if { "$time(time)$time(ampm)" eq "" } {
        return 1
    }

    set time_element_values [split $time(time) ":"]
    if { [llength $time_element_values] != 3 } {
        ad_complain [_ acs-tcl.lt_Invalid_time_timetime]
        return 0
    }

    set time_element_names [list hours minutes seconds]

    for { set i 0 } { $i < 3 } { incr i } {
        array set time [list [lindex $time_element_names $i] [lindex $time_element_values $i]]
    }

    if {
        "" eq $time(hours)
        || "" eq $time(minutes)
        || "" eq $time(seconds)
        || (![string equal -nocase "pm" $time(ampm)] && ![string equal -nocase "am" $time(ampm)])
        || $time(hours) < 1 || $time(hours) > 12
        || $time(minutes) < 0 || $time(minutes) > 59
        || $time(seconds) < 0 || $time(seconds) > 59
    } {
        ad_complain [_ acs-tcl.lt_Invalid_time_timetime_1]
        return 0
    }

    return 1
}

ad_page_contract_filter -type post time24 { name time } {
    Validates time type variables of the 24HR variety (that is 20:12:21)

    @author Yonatan Feldman (yon@arsdigita.com)
    @creation-date 25 July 2000
} {
    if { ![info exists time(time)] } {
        ad_complain [_ acs-tcl.lt_Invalid_time_time_is_]
        return 0
    }

    # check if all elements are blank
    if { "$time(time)" eq "" } {
        return 1
    }

    set time_element_values [split $time(time) ":"]
    if { [llength $time_element_values] != 3 } {
        ad_complain [_ acs-tcl.lt_Invalid_time_timetime]
        return 0
    }

    set time_element_names [list hours minutes seconds]

    for { set i 0 } { $i < 3 } { incr i } {
        array set time [list [lindex $time_element_names $i] [lindex $time_element_values $i]]
    }

    if {
        "" eq $time(hours)
        || "" eq $time(minutes)
        || "" eq $time(seconds)
        || $time(hours) < 0 || $time(hours) > 23
        || $time(minutes) < 0 || $time(minutes) > 59
        || $time(seconds) < 0 || $time(seconds) > 59
    } {
        ad_complain [_ acs-tcl.lt_Invalid_time_timetime_2]
        return 0
    }

    return 1
}


ad_page_contract_filter string_length_range { name value range} {
    Checks whether the string is within the specified range, inclusive

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date August 2000
} {
    set actual_length [string length $value]
    if { $actual_length < [lindex $range 0] } {
        set binding [list name $name actual_length $actual_length min_length [lindex $range 0]]
        ad_complain [_ acs-tcl.lt_name_is_too_short__Pl $binding]
        return 0
    } elseif { $actual_length > [lindex $range 1] } {
        set binding [list name $name actual_length $actual_length max_length [lindex $range 1]]
        ad_complain [_ acs-tcl.lt_name_is_too_long__Ple $binding]
        return 0
    }
    return 1
}

ad_page_contract_filter string_length { name value length } {
    Checks whether the string is less or greater than the minimum or
    maximum length specified, inclusive
    e.g.address_1:notnull,string_length(max|100) will test address_1 for
    maximum length of 100.

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date August 2000
} {
    set actual_length [string length $value]
    lassign $length op nr
    if { $op eq "min" } {
        if { $actual_length < $nr } {
            set binding [list name $name actual_length $actual_length min_length $nr]
            ad_complain [_ acs-tcl.lt_name_is_too_short__Pl_1 $binding]
            return 0
        }
    } else {
        if { $actual_length > $nr } {
            set binding [list name $name actual_length $actual_length max_length $nr]
            ad_complain [_ acs-tcl.lt_name_is_too_long__Ple_1 $binding]
            return 0
        }
    }
    return 1
}

ad_page_contract_filter email { name value } {
    Checks whether the value is a valid email address (stolen from
                                                       philg_email_valid_p)

    @author Philip Greenspun (philip@mit.edu)
    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date 22 August 2000
} {
    set valid_p [util_email_valid_p $value]
    if { !$valid_p } {
        ad_complain [_ acs-tcl.lt_name_does_not_appear_]
        return 0
    }
    return 1
}

ad_page_contract_filter float { name value } {
    Checks to make sure that the value in question is a valid number,
    possibly with a decimal point
    - randyb took this from the ACS dev bboard

    @author Steven Pulito (stevenp@seas.upenn.edu)
    @creation-date 22 August 2000
} {
    # Check if the first character is a "+" or "-"
    set signum ""
    if {[regexp {^([\+\-])(.*)} $value match signum rest]} {
        set value $rest
    }

    # remove the first decimal point, the theory being that
    # at this point a valid float will pass an integer test
    regsub {\.} $value "" value_to_be_tested

    if { ![regexp {^[0-9]+$} $value_to_be_tested] } {
        ad_complain [_ acs-tcl.lt_Value_is_not_an_decim]
        return 0
    }

    set value [util::trim_leading_zeros $value]

    # finally add the signum character again
    set value "$signum$value"

    return 1
}

ad_page_contract_filter negative_float { name value } {
    Same as float but allows negative numbers too

    GN: this is deprecated, since "float" allows as well negative numbers

    @author Brian Fenton
    @creation-date 1 December 2004
} {
    # Check if the first character is a "+" or "-"
    set signum ""
    if {[regexp {^([\+\-])(.*)} $value match signum rest]} {
        set value $rest
    }

    # remove the first decimal point, the theory being that
    # at this point a valid float will pass an integer test
    regsub {\.} $value "" value_to_be_tested

    if { ![regexp {^[0-9]+$} $value_to_be_tested] } {
        ad_complain [_ acs-tcl.lt_Value_is_not_an_decim]
        return 0
    }

    set value [util::trim_leading_zeros $value]

    # finally add the signum character again
    set value "$signum$value"

    return 1
}


ad_page_contract_filter phone { name value } {

    Checks whether the value is more or less a valid phone number with
    the area code.  Specifically, area code excluding leading "1",
    optionally enclosed in parentheses; followed by phone number in
    the format xxx xxx xxxx (either spaces, periods or dashes
                             separating the number).  This filter matches the beginning of the
    value being checked, and considers any user input following the
    match as valid (to allow for extensions, etc.).  Add a
    $ at the end of the regexp to disallow extensions.  Examples:

    <ul>
    <li>(800) 888-8888 will pass
    <li>800-888-8888 will pass
    <li>800.888.8888 will pass
    <li>8008888888 will pass
    <li>(800) 888-8888 extension 405 will pass
    <li>(800) 888-8888abcd will pass
    <li>"" (the empty string) will pass
    <li>1-800-888-8888 will <b>fail</b>
    <li>10-10-220 800.888.8888 will <b>fail</b>
    <li>abcd(800) 888-8888 will <b>fail</b>
    </ul>

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date August 2000
} {
    if { [string trim $value] ne "" } {
        if { ![regexp {^\(?([1-9][0-9]{2})\)?(-|\.|\ )?([0-9]{3})(-|\.|\ )?([0-9]{4})} $value] } {
            ad_complain [_ acs-tcl.lt_value_does_not_appear]
            return 0
        }
    }
    return 1
}


ad_page_contract_filter -deprecated usphone { name value } {
    Checks whether the value is more or less a valid US phone number with
    the area code.
    Exact filter is XXX-XXX-XXXX

    DEPRECATED: this filter is US-specific. One should use less
                specific alternatives.

    @see ad_page_contract_filter_proc_phone

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date 22 August 2000
} {
    if { [string trim $value] ne ""
         && ![regexp {[1-9][0-9][0-9]-[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9]} $value]} {
        ad_complain [_ acs-tcl.lt_name_does_not_appear__1]
        return 0
    }
    return 1
}

ad_page_contract_filter boolean { name value } {
    Checks whether the value is boolean (1 or 0) or predicate (t or f)
    or otherwise
    a 2 state value (true or false, y or n, yes or no)

    @author Randy Beggs (randyb@arsdigita.com)
    @creation-date 23 August 2000
} {

    if {[string is boolean -strict $value]} {
        return 1
    }
    ad_complain [_ acs-tcl.lt_name_does_not_appear__2]
    return 0
}

ad_page_contract_filter word { name value } {
    Checks whether the value is a Tcl word, i.e. it consists of just
    characters, digits and underscore.

    @author Gustaf Neumann
    @creation-date 24 June 2015
} {

    if {[regexp {^\w+$} $value]} {
        return 1
    }
    ad_complain [_ acs-tcl.lt_name_is_not_a_word]
    return 0
}

ad_page_contract_filter token { name value } {
    Checks whether the value is a Tcl word, or contains a few
    rather safe other characters (".", ",", "-") used e.g. in orderby.

    @author Gustaf Neumann
    @creation-date 24 June 2015
} {

    if {[regexp {^[\w.,: -]+$} $value]} {
        return 1
    }
    ad_complain [_ acs-tcl.lt_name_contains_invalid]
    return 0
}

ad_page_contract_filter safetclchars { name value } {

    Checks whether the value contains just characters, which can be
    used safely in a Tcl eval or subst command. This means, that the characters
    '$', '[', ']' and '\' disallowed,.

    @author Gustaf Neumann
    @creation-date 15 Mar 2023
} {

    if {[info commands ns_valid_utf8] ne ""
        && ![ns_valid_utf8 $value]} {
        ad_complain [_ acs-tcl.lt_name_contains_invalid]
        return 0
    }

    if {[regexp {^[^\[\]\\\$]+$} $value]} {
        return 1
    }
    ad_complain [_ acs-tcl.lt_name_contains_invalid]
    return 0
}

ad_page_contract_filter printable { name value } {

    Checks whether the value contains only characters with a printable
    representation. This represents character class of the Tcl
    character class "print", which consists of the characters with a
    visible representation and space.  This filter is useful for
    e.g. avoiding invalid byte sequences for the database.

    @author Gustaf Neumann
    @creation-date 22 April 2021
} {

    if {![regexp {[^[:print:]]} $value]} {
        return 1
    }
    ad_complain [_ acs-tcl.lt_name_contains_invalid]
    return 0
}

ad_page_contract_filter path { name value } {
    Checks whether the value is a Tcl word, or contains a few
    rather safe other characters ("-", "/", ".") used
    in (file-system) paths

    @author Gustaf Neumann
    @creation-date 24 June 2015
} {

    if {[regexp {^[\w/.-]+$} $value]} {
        return 1
    }
    ad_complain [_ acs-tcl.lt_name_contains_invalid]
    return 0
}

ad_page_contract_filter localurl { name value } {
    Checks whether the value is an acceptable
    (non-external) url, which can be used
    in ad_returnredirect without throwing an error.

    @author Gustaf Neumann
    @creation-date 19 Mai 2016
} {
    set valid_p 1

    if { $value eq "" || [util::external_url_p $value]} {
        set valid_p 0
    } else {
        try {
            ns_parseurl $value
        } on error {errMsg} {
            set valid_p 0
        } on ok {d} {
            set valid_p [expr {![dict exists $d proto] || [dict get $d proto] in {http https}}]
        }
    }

    if {!$valid_p} {
        ad_complain [_ acs-tcl.lt_name_is_not_valid]
    }

    return $valid_p
}



####################
#
# Standard filter rules
#
####################

#
# GN: The following two rules cause warnings of the form
#     Multiple definitions of the ad_page_contract_filter_rule
#

ad_page_contract_filter_rule html { name filters } {
    Makes sure the filter nohtml gets applied, unless some other html filter (html or allhtml)
    is already specified.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    foreach flag $filters {
        if { $flag in { nohtml html allhtml integer naturalnum word token } } {
            return
        }
    }
    lappend filters nohtml
}

ad_page_contract_filter_rule tmpfile { name filters } {
    Makes sure the tmpfile filter gets applied for all vars named *.tmpfile.
    @author Lars Pind (lars@pinds.com)
    @creation-date 25 July 2000
} {
    if { [string match "*tmpfile" $name] && "tmpfile" ni $filters } {
        lappend filters tmpfile
    }
}


####################
#
# Templating system things
#
####################

ad_proc ad_page_contract_verify_datasources {} {
    Check if all the datasources (properties) promised in the page contract have
    actually been set.

    @author Christian Brechbuehler <christian@arsdigita.com>
    @creation-date 13 Aug 2000
} {
    # for now this is a dummy proc.
    # todo: check if all datasources are defined based on property declarations
    return 1;                # ok
}



ad_proc ad_page_contract_handle_datasource_error {error} {
    Output a diagnostic page.  Treats both special and generic error messages.

    @author Christian Brechbuehler <christian@arsdigita.com>
    @creation-date 13 Aug 2000
} {
    set complaint_template [parameter::get_from_package_key \
                                -package_key "acs-tcl" \
                                -parameter "ReturnComplaint" \
                                -default "/packages/acs-tcl/lib/ad-return-complaint"]
    set exception_count 1
    set exception_text $error
    ns_return 422 text/html [ad_parse_template \
                                 -params [list [list exception_count $exception_count] \
                                              [list exception_text $exception_text] \
                                              [list prev_url [util::get_referrer -trusted]] \
                                             ]  $complaint_template]
}

namespace eval ::template::csrf {
    ad_proc ::template::csrf::validate {
        -package_id
    } {
        validate a csrf token

        @author Gustaf Neumann
        @creation-date Feb 2, 2017
    } {
        if {![info exists package_id]} {
            if {![ns_conn isconnected]} {
                return 0
            }
            set package_id [ad_conn package_id]
        }
        set validateCSRF_p [parameter::get \
                                -package_id $package_id \
                                -parameter "ValidateCSRFP" \
                                -default 1]

        if {$validateCSRF_p ne "" && $validateCSRF_p} {
            security::csrf::validate
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
