ad_library {

    Form processing utilities.

    @author Don Baccus (dhogaza@pacifier.net)
}

ad_proc -public ad_form {
    args
} {

    This procedure implements a high-level, declarative syntax for the generation and
    handling of HTML forms.  It includes special syntax for the handling of forms tied to
    database entries, including the automatic generation and handling of primary keys generated
    from sequences.   You can declare code blocks to be executed when the form is submitted, new
    data is to be added, or existing data modified.   You can declare form validation blocks that
    are similar in spirit to those found in ad_page_contract.

    <p>

    We use the standard ATS form builder's form and element create procedures to generate forms,
    and its state-tracking code to determine when to execute various code blocks.  Because of
    this, you can use any form builder datatype or widget with this procedure, and extending its
    functionality is a simple matter of implementing new ones.

    <p>

    In general the full functionality of the form builder is exposed by ad_form, but with a
    much more user-friendly and readable syntax and with state management handled automatically.
    
    <p>

    In order to make it possible to use ad_form to build common form snippets within procs, code
    blocks are executed at the current template parse level.   This is necessary if validate and
    similar blocks are to have access to the form's contents but may cause surprises for the
    unwary.  So be wary.

    <p>

    On the other hand when subst is called, for instance when setting values in the form, the
    caller's level is used.  Why do this?  A proc building a common form snippet may need to
    build a list of valid select elements or similarly compute values that need to be set in
    the form, and these should be computed locally.

    <p>

    Yes, this is a bit bizarre and not necessarily well thought out.  The semantics were decided
    upon when I was writing a fairly complex package for Greenpeace, International and worked well
    there so for now, I'm leaving them the way they are.

    <p>

    Here's an example of a simple page implementing an add/edit form:

    <blockquote><pre>

    ad_page_contract {

        Simple add/edit form

    } {
        my_table_key:optional
    }

    ad_form -name form_name -export {foo {bar none}} -form {

        my_table_key:key(my_table_sequence)

        {value:text(textarea)             {label "Enter text"}
                                           {html {rows 4 cols 50}}}
    } -select_query {
        select value from my_table where my_table_key = :my_table_key
    } -validate {
        {value
         {[string length $value] >= 3}
         "\"value\" must be a string containing three or more characters"
        }
    } -new_data {
        db_dml do_insert "
            insert into my_table
              (my_table_key, value)
            values
              (:key, :value)"
    } -edit_data {
        db_dml do_update "
            update my_table
            set value = :value
            where my_table_key = :key"
    } -after_submit {
        ad_returnredirect "somewhere"
        ad_script_abort
    }

    </pre></blockquote>

    <p>

    In this example, ad_form will first check to see if "my_table_key" was passed to the script.  If
    not, the database will be called to generate a new key value from "my_table_sequence" (the sequence
    name defaults to acs_object_id_seq).   If defined, the query defined by "-select_query" will be used
    to fill the form elements with existing data (an error will be thrown if the query fails).

    <p>

    The call to ad_return_template then renders the page - it is your responsibility to render the form
    in your template by use of the ATS formtemplate tag.
 
    <p>

    On submission, the validation block checks that the user has entered at least three characters into the
    textarea (yes, this is a silly example).  If the validation check fails the "value" element will be tagged
    with the error message, which will be displayed in the form when it is rendered.

    If the validation check returns true, one of the new_data or edit_data code blocks will be executed depending
    on whether or not "my_table_key" was defined during the initial request.  "my_table_key" is passed as a hidden
    form variable and is signed and verified, reducing the opportunity for key spoofing by malicious outsiders.
    
    <p>

    This example includes dummy redirects to a script named "somewhere" to make clear the fact that after
    executing the new_data or edit_data block ad_form returns to the caller.

    <p>

    <b>General information about parameters</b>

    <p>Parameters which take a name (for instance "-name" or "-select_query_name") expect a simple name
    not surrounded by curly braces (in other words not a single-element list).  All other parameters expect
    a single list to be passed in.
    <p>

    Here's a complete list of switches that are supported by ad_form:

    <p>

    <dl>
    <p><dt><b>-extend</b></dt><p>
    <dd>Extend an existing form.  This allows one to build forms incrementally.  Forms are built at the
        template level.  As a consequence one can write utility procs that use -extend to build form
        snippets common to several data entry forms.  
        <p>This must be the first switch passed into ad_form
    </dd>

    <p><dt><b>-name</b></dt><p>
    <dd>Declares the name of the form.  Defaults to the name of the script being served.</dd>

    <p><dt><b>-action</b></dt><p>
    <dd>The name of the script to be called when the form is submitted.  Defaults to the name of the script
        being served.  
    </dd>

    <p><dt><b>-html</b></dt><p>
    <dd>The given html will be added to the "form" tag when page is rendered.  This is commonly used to
        define multipart file handling forms.
    </dd>

    <p><dt><b>-export</b></dt><p>
    <dd>Similar to the utility <b>export_vars</b>.  Takes a list of values to insert in the form as 
        "hidden" elements.   Each value is either a name, in which case the Tcl variable at the caller's
        level is passed to the form if it exists, or a name-value pair.   "multiple", "array", "sign" and
        similar flags are not allowed though it would be good to do so in the future.
    </dd>
        
    <p><dt><b>-form</b></dt><p>
    <dd>Declare form elements (described in detail below)
    </dd>

    <p><dt><b>-select_query</b></dt><p>
    <dd>Defines a query that returns a single row containing values for each element of the form meant to be
        modifiable by the user.
    </dd>

    <p><dt><b>-select_query_name</b></dt><p>
    <dd>The name of a query to be looked up in the appropriate query file that returns a single row containing
        values for each element of the form meant to be modifiable by the user.  In the OpenACS 4 environment this
        should normally be used rather than -select_query, as query files are the mechanism used to make the
        support of multiple RDMBS systems possible.
    </dd>

    <p><dt><b>-edit_request</b></dt><p>
    <dd>A code block which sets the values for each element of the form meant to be modifiable by the user.  Use
        this when a single query to grab database values is insufficient.
    </dd>

    <p><dt><b>-confirm_template</b></dt><p>
    <dd>The name of a confirmation template to be called before any on_submit, new_data or edit_data block.  When
        the user confirms input control will be passed to the appropriate submission block.  The confirmation
        template can be used to provide a bboard-like preview/confirm page.  Your confirmation template should
        render the form contents in a user-friendly way then include "/packages/acs-templating/resources/forms/confirm-button".
        The "confirm-button" template not only provides a confirm button but includes the magic incantation that
        tells ad_form that the form has been confirmed by the user and that it is safe to call the proper submission
        block.
    </dd>

    <p><dt><b>-on_submit</b></dt><p>
    <dd>When the form is submitted, this code block will be executed before any new_data or edit_data code block.
        Use this if your form doesn't interact with the database or if the database type involved includes a Tcl
        API that works for both new and existing data.
    </dd>

    <p><dt><b>-new_data</b></dt><p>
    <dd>This code block will be executed when a form for a new database row is submitted.  This block should
        insert the data into the database or create a new database object or content repository item containing
        the data.
    </dd>

    <p><dt><b>-edit_data</b></dt><p>
    <dd>This code block will be executed when a form for an existing database row is submitted.  This block should
        update the database or create a new content revision for the exisiting item if the data's stored in the
        content repository.
    </dd>

    <p><dt><b>-after_submit</b></dt><p>
    <dd>This code block will be executed after the three blocks on_submit, new_data or edit_data have been
    executed. It is useful for putting in stuff like ad_returnredirect that is the same for new and edit.
    </dd>

    </dl>

    Two hidden values of interest are available to the caller of ad_form when processing a submit:

    <p>
    <dl>
    <p><dt><b>__new_p</b></dt><p>
    <dd>
       If a database key has been declared, __new_p will be set true if the form
       submission is for a new value.  If false, the key refers to an existing
       values.  This is useful for forms that can easily process either operation
       in a single on_submit block, rather than use separate new_data and edit_data
       blocks.
    </dd>

    <p><dt><b>__refreshing_p</b></dt><p>
    <dd>
       This should be set true by Javascript widgets which change a form element then
       submit the form to refresh values.
    </dd>
    </dl>

    <p><b>Declaring form elements</b><p>

    ad_form uses the form builder's form element create procedure to generate elements declared in the -form
    block.   ad_form does rudimentary error checking to make sure the data type and widget exist, and
    that options are legal.

    <p>

    The -form block is a list of form elements, which themselves are lists consisting of one or two
    elements.  The first member of each element sublist declares the form element name, type, widget, whether or
    not the element is a multiple element (multiselect, for instance), and optional conversion arguments.  The second,
    optional member consists of a list of form element parameters and values.  All parameters accepted by the form
    element create procedure are allowed.

    <p>

    Some form builder datatypes build values that do not directly correspond to database types.  When using
    the form builder directly these are converted by calls to datatype::get_property and datatype::acquire.
    When using ad_form, "to_html(property)", "to_sql(property)" and "from_sql(property)" declare the appropriate
    properties to be retrieved or set before calling code blocks that require the converted values.  The "to_sql"
    operation is performed before any on_submit, new_data or edit_data block is executed.  The "from_sql" operation
    is performed after a select_query or select_query_name query is executed.   No automatic conversion is performed
    for edit_request blocks (which manually set form values).  The "to_html" operation is performed before execution
    of a confirm template.

    <p>

    Currently only the date and currency datatypes require these conversion operations.

    <p>

    In the future the form builder will be enhanced so that ad_form can determine the proper conversion operation
    automatically, freeing the programmer from the need to specify them.  When this is implemented the current notation
    will be retained for backwards compatibility.

    <p>

    ad_form defines a "key" pseudotype.  Only one element of type "key" is allowed per form, and it is assigned
    the integer datatype.  Only keys which are generated from a database sequence are managed automatically by
    ad_form.  If the sequence name is not specified, the sequence acs_object_id_seq is used to generate new keys.

    Examples:
    
    <blockquote><pre>
    my_key:key
    </pre><p>

    Define the key "my_key", assigning new values by calling acs_object_id_seq.nextval

    <p>
    </blockquote>
    
    <blockquote><pre>
    my_key:key(some_sequence_name)
    </pre><p>

    Define the key "my_key", assigning new values by calling some_sequence_name.nextval

    <p>
    </blockquote>
    
    <blockquote><pre>
    {my_key:text(multiselect),multiple       {label "select some values"}
                                              {options {first second third fourth fifth}}
                                              {html {size 4}}}
                                  
    </pre><p>

    Define a multiple select element with five choices, in a four-line select box.

    <p>
    </blockquote>
    
    <blockquote><pre>
    {hide_me:text(hidden)                     {value 3}}
    </pre><p>

    Define the hidden form element "hide_me" with the value 3

    <p>
    </blockquote>
    
    <blockquote><pre>
    start_date:date,to_sql(sql_date),from_html(sql_date),optional
    </pre><p>

    Define the optional element "start_date" of type "date", get the sql_date property before executing
    any new_date, edit_date or on_submit block, set the sql_date property after performing any
    select_query. 

    <p>
    </blockquote>

} {

    set level [template::adp_level]

    # Are we extending the form?

    if { [string equal [lindex $args 0] "-extend"] } {
        set extend_p 1
        set args [lrange $args 1 end]
    } else {
        set extend_p 0
    }

    # Parse the rest of the arguments

    if { [llength $args] == 0 } {
        return -code error "No arguments to ad_form"
    } 

    set valid_args { form method action html name select_query select_query_name new_data on_refresh
                     edit_data validate on_submit after_submit confirm_template new_request edit_request
                     export};

    ad_arg_parser $valid_args $args

    # Set the form name, defaulting to the name of the template that called us

    if { [info exists name] } {
        if { [string first "__" $name] >= 0 } {
            return -code error "Form name \"$name\" may not contain \"__\""
        }
        set form_name $name
    } else {
        set form_name [file rootname [lindex [ad_conn urlv] end]]
    }

    if { [info exists af_parts(${form_name}__extend)] } {
        report -code error "Can't extend form \"$form_name\" - a parameter block requiring the full form has already been declared"
    }

    global af_parts

    if { $extend_p && ![info exists af_parts(${form_name}__form)] } {
        return -code error "You can't extend form \"$form_name\" until you've created the form"
    }

    foreach valid_arg $valid_args {
        if { [info exists $valid_arg] } {
            if { [info exists af_parts(${form_name}__$valid_arg)] &&
                 ![lsearch { form name validate export } $valid_arg] == -1 } {
                return -code error "Form \"$form_name\" already has a \"$valid_arg\" section"
            }

            set af_parts(${form_name}__$valid_arg) ""

            # Force completion of the form if we have any action block.  We only allow the form
            # and validation block to be extended, for now at least until I get more experience
            # with this ...

            if { [lsearch { name form method action html validate export } $valid_arg ] == -1 } {
                set af_parts(${form_name}__extend) ""
            }
        }
    }

    if { ![info exists af_parts(${form_name}__form)] } {
        return -code error "No \"form\" block has been specified for form \"$form_name\""
    }

    # If we're not extending - this needs integration with the ATS form builder ...
    if { !$extend_p } {
        # incr ad_conn(form_count)
    }

    ####################
    #
    # Step 1: Parse the form specification
    #
    ####################

    # We need the full list of element names and their flags during submission, so track
    # them globally.  (Future implementation note: the form builder tracks these already
    # and we should extend its data and use it directly, but there's not time to do this
    # right for Greenpeace so I'm hacking the hell out of it)

    global af_element_names
    global af_flag_list

    # Track element names and their parameters locally as we'll generate those in this form
    # or extend block on the fly

    set element_names [list]
    array set af_element_parameters [list] 

    if { [info exists form] } {
        foreach element $form {
            set element_name_part [lindex $element 0]

            # This can easily be generalized if we add more embeddable form commands ...

            if { [string equal $element_name_part "-section"] } {
                lappend af_element_names($form_name) "[list "-section" [uplevel [list subst [lindex $element 1]]]]"
            } else {
                if { ![regexp {^([^ \t:]+)(?::([a-zA-Z0-9_,(|)]*))?$} $element_name_part match element_name flags] } {
                    return -code error "Form element '$element_name_part' doesn't have the right format. It must be var\[:flag\[,flag ...\]\]"
                }

                lappend af_element_names($form_name) $element_name
                set af_extra_args($element_name) [lrange $element 1 end]
                set pre_flag_list [split [string tolower $flags] ,]
                set af_flag_list(${form_name}__$element_name) [list]

                # find parameterized flags.  We only allow one parameter.
                foreach flag $pre_flag_list {
                    set af_element_parameters($element_name:$flag) [list]
                    set left_paren [string first "(" $flag]
                    if { $left_paren != -1 } {
                        if { ![string equal [string index $flag end] ")"] } {
                            return -code error "Missing or misplaced end parenthesis for flag '$flag' on argument '$element_name'"
                        }
                        set flag_stem [string range $flag 0 [expr $left_paren - 1]]
                        lappend af_element_parameters($element_name:$flag_stem) [string range $flag [expr $left_paren + 1] [expr [string length $flag]-2]]
                        lappend af_flag_list(${form_name}__$element_name) $flag_stem
                    } else {
                        lappend af_flag_list(${form_name}__$element_name) $flag
                    }
                }
            }
            lappend element_names [lindex $af_element_names($form_name) end]
        }
    }

    # Check the validation block for boneheaded errors if it exists.  We explicitly allow a form element
    # to appear twice in the validation block so the caller can pair different error messages to different
    # checks.  We implement this by building a global list of validation elements

    global af_validate_elements
    set af_validate_elements($form_name) [list]

    if { [info exists validate] } {
        foreach validate_element $validate {
            if { [llength $validate_element] != 3 } {
                return -code error "Validate block must have three arguments: element name, expression, error message"
            }

	    if { [lsearch $af_element_names($form_name) [lindex $validate_element 0]] == -1 } {
	        return -code error "Element \"[lindex $validate_element 0]\" is not a form element"
            }
            lappend af_validate_elements($form_name) $validate_element
	}
    }

    if { !$extend_p } {
        set create_command [list template::form create $form_name]

        if { [info exists action] } {
            lappend create_command "-action" $action
        }

        if { [info exists method] } {
            lappend create_command "-method" $method
        }

        if { [info exists html] } {
            lappend create_command "-html" $html
        }

        # Create the form

        eval $create_command

        # Now make it impossible to add params specific to form creation to an extend
        # block

        # if a confirm template has been specified, it will be returned unless __confirmed_p is set
        # true.  This is most easily done by including resources/forms/confirm-button in the confirm
        # template.

        template::element create $form_name __confirmed_p -datatype integer -widget hidden -value 0

        # javascript widgets can change a form value and submit the result in order to allow the
        # generating script to fill in a value such as an image.   The widget must set __refreshing_p
        # true.

        template::element create $form_name __refreshing_p -datatype integer -widget hidden -value 0

    }

    if { [info exists export] } {
        foreach value $export {
            set name [lindex $value 0]
            if { [llength $value] == 1 } {
                template::element create $form_name $name -datatype text -widget hidden -value [uplevel [list set $name]]
            } else {
                template::element create $form_name $name -datatype text -widget hidden -value [uplevel [list subst [lindex $value 1]]]
            }
        }
    }

    # We need to track these for submission time and for error checking

    global af_type
    global af_key_name
    global af_sequence_name

    foreach element_name $element_names {
        if { [llength $element_name] == 2 } {
            switch [string range [lindex $element_name 0] 1 end] {
                section { template::form section $form_name [lindex $element_name 1] }
            }
        } else {
            set form_command [list template::element create $form_name $element_name]
            foreach flag $af_flag_list(${form_name}__$element_name) {
                switch $flag {

                    key {
                        if { [info exists af_key_name($form_name)] } {
                            return -code error "element $element_name: a form can only declare one key"
                        }
                        set af_key_name($form_name) $element_name
                        if { ![empty_string_p $af_element_parameters($element_name:key)] } {
                            if { [info exists af_sequence_name($form_name)] } {
                                return -code error "element $element_name: duplicate sequence"
                            }
                            set af_sequence_name($form_name) $af_element_parameters($element_name:key)
                        }
                        lappend form_command "-datatype" "integer" "-widget" "hidden"
                        template::element create $form_name __key_signature -datatype text -widget hidden -value ""
                        template::element create $form_name __new_p -datatype integer -widget hidden -value 0
                    }

                    multiple {
                        if { ![empty_string_p $af_element_parameters($element_name:$flag)] } {
                            return -code error "element $element_name: $flag attribute can not have a parameter"
                        }
                    }

                    optional {
                        if { ![empty_string_p $af_element_parameters($element_name:$flag)] } {
                            return -code error "element $element_name: $flag attribute can not have a parameter"
                        }
                        lappend form_command "-$flag"
                    }

                    from_sql -
                    to_sql -
                    to_html {
                        if { [empty_string_p $af_element_parameters($element_name:$flag)] } {
                            return -code error "element $element_name: \"$flag\" attribute must have a parameter"
                        }
                        set name af_$flag
                        append name "(${form_name}__$element_name)"
                        if { [info exists $name] } {
                            return -code error "element $element_name: \"$flag\" appears twice"
                        }
                        global $name
                        set $name $af_element_parameters($element_name:$flag)
                    }

                    default {
                        if { [empty_string_p [info commands "::template::data::validate::$flag"]] } {
                           return -code error "element $element_name: data type \"$flag\" is not valid"
                        }
                        lappend form_command "-datatype"
                        lappend form_command $flag
                        set af_type(${form_name}__$element_name) $flag
                        if { [empty_string_p $af_element_parameters($element_name:$flag)] } {
                            if { ![empty_string_p [info command "::template::widget::$flag"]] } {
                                lappend form_command "-widget" $flag
                            }
                        } else {
                            if { [empty_string_p [info commands "::template::widget::$af_element_parameters($element_name:$flag)"]] } {
                                return -code error "element $element_name: widget \"$af_element_parameters($element_name:$flag)\" does not exist"
                            }
                            lappend form_command "-widget" $af_element_parameters($element_name:$flag)
                        }
                    }
                }
            }
              
            foreach extra_arg $af_extra_args($element_name) {
                lappend form_command "-[lindex $extra_arg 0]"
                switch [lindex $extra_arg 0] {
                    html -
                    values -
                    validate -
                    options {
                        lappend form_command [uplevel [list subst [lindex $extra_arg 1]]]
                    }
                    help_text -
                    label -
                    format -
                    value -
                    before_html -
                    after_html {
                        if { [llength $extra_arg] > 2 || [llength $extra_arg] == 1 } {
                            return -code error "element $element_name: \"$extra_arg\" requires exactly one argument"
                        }
                        lappend form_command [uplevel [list subst [lindex $extra_arg 1]]]
                    }
                }
            }
            eval $form_command

        }
    }

    # Check that any acquire and get_property attributes are supported by their element's datatype
    # These are needed at submission and fill-the-form-with-db-values time 

    foreach element_name $af_element_names($form_name) {
        if { [llength $element_name] == 1 } {
            if { [info exists af_from_sql(${form_name}__$element_name)] } {
                if { [empty_string_p [info commands "::template::util::$af_type(${form_name}__$element_name)::acquire"]] } {
                    return -code error "\"from_sql\" not valid for type \"$af_type(${form_name}__$element_name)\""
                }
            }
            if { [info exists af_to_sql(${form_name}__$element_name)] } {
                if { [empty_string_p [info commands "::template::util::$af_type(${form_name}__$element_name)::get_property"]] } {
                    return -code error "\"to_sql\" not valid for type \"$af_type(${form_name}__$element_name)\""
                }
            }
            if { [info exists af_to_html(${form_name}__$element_name)] } {
                if { [empty_string_p [info commands "::template::util::$af_type(${form_name}__$element_name)::get_property"]] } {
                    return -code error "\"to_html\" not valid for type \"$af_type(${form_name}__$element_name)\""
                }
            }
        }
    }

    # Check for consistency if database operations are to be triggered by this form

    if { [info exists af_sequence_name($form_name)] && ![info exists af_key_name($form_name)] } {
        return -code error "You've supplied a sequence name no \"key_name\" parameter"
    }

    # Handle a request form that triggers database operations

    upvar #$level $form_name:properties properties

    # If we haven't seen an "action block" that requires the entire form, return.  If the calling
    # script never finishes its form, tough.  It won't work.

    if { ![info exists af_parts(${form_name}__extend)] } {
        return
    }

    if { [template::form is_request $form_name] && [info exists af_key_name($form_name)] } {

        set key_name $af_key_name($form_name)
        upvar #$level $key_name $key_name
        upvar #$level __ad_form_values__ values

        # Check to see if we're editing an existing database value
        if { [info exists $key_name] } {
            if { [info exists edit_request] } {
                if { [info exists select_query] || [info exists select_query_name] } {
                    return -code error "Edit request block conflicts with select query"
                }
                ad_page_contract_eval uplevel #$level $edit_request
            } else {

                # The key exists, grab the existing values if we have an select_query clause

                if { ![info exists select_query] && ![info exists select_query_name] } {
                    return -code error "Key \"$key_name\" has the value \"[set $key_name]\" but no select_query or select_query_name clause exists"
                }

                if { [info exists select_query_name] } {
                    set select_query ""
                } else {
                    set select_query_name ""
                }

                if { ![uplevel #$level [list db_0or1row $select_query_name [join $select_query " "] -column_array __ad_form_values__]] } {
                    return -code error "Error when selecting values"
                }

                foreach element_name $af_element_names($form_name) {
                    if { [llength $element_name] == 1 } {
                        if { [info exists af_from_sql(${form_name}__$element_name)] } {
                            set values($element_name) [template::util::$af_type(${form_name}__$element_name)::acquire \
                                                       $af_from_sql(${form_name}__$element_name) $values($element_name)]
                        }
                    }
                }
            }

            set values($key_name) [set $key_name]
            set values(__new_p) 0

        } else {

            # Make life easy for the OACS 4.5 hacker by automagically generating a value for
            # our new database row.  Set a local so the query can use bindvar notation (the driver
            # doesn't support array bind vars)

            if { [info exists af_sequence_name($form_name)] } {
                set sequence_name $af_sequence_name($form_name)
            } else {
                set sequence_name "acs_object_id_seq"
            }

            if { ![db_0or1row get_key "" -column_array values] } {
                return -code error "Couldn't get the next value from sequence \"$af_sequence_name($form_name)\""
            }
            set values(__new_p) 1
        }

        set values(__key_signature) [ad_sign "$values($key_name):$form_name"]

        foreach element_name $properties(element_names) {
            if { [info exists values($element_name)] } {
                if { [info exists af_flag_list(${form_name}__$element_name)] && \
                     [lsearch $af_flag_list(${form_name}__$element_name) multiple] >= 0 } {
                    template::element set_properties $form_name $element_name -values $values($element_name)
                } else {
                    template::element set_properties $form_name $element_name -value $values($element_name)
                }
            }
        }

    } elseif { [template::form is_submission $form_name] } { 

        # Handle form submission.  We create the form values in the caller's context and execute validation
        # expressions if they exist

        # Get all the form elements.  We can't call form get_values because it doesn't handle multiples
        # in a reasonable way.

        foreach element_name $properties(element_names) {
            if { [info exists af_flag_list(${form_name}__$element_name)] && \
                 [lsearch $af_flag_list(${form_name}__$element_name) multiple] >= 0 } {
                set values [uplevel #$level [list template::element get_values $form_name $element_name]]
                uplevel #$level [list set $element_name $values]
            } else {
                set value [uplevel #$level [list template::element get_value $form_name $element_name]]
                uplevel #$level [list set $element_name $value]
            }
        }

        if { [info exists key_name] } {
            upvar #$level $key_name __key
            upvar #$level __key_signature __key_signature

            if { [info exists __key] && ![ad_verify_signature "$__key:$form_name" $__key_signature] } {
                ad_return_error "Bad key signature" "Verification of the database key value failed"
            }
        }

        # Execute validation expressions.  We've already done some sanity checks so know the basic structure
        # is OK

        foreach validate_element $af_validate_elements($form_name) {
            foreach {element_name validate_expr error_message} $validate_element {
                if { ![template::element error_p $form_name $element_name] && \
                    ![uplevel #$level [list expr $validate_expr]] } {
                    template::element set_error $form_name $element_name [subst $error_message]
                }
            }
        }
    }

    if { [template::form is_submission $form_name] &&
         [uplevel #$level {set __refreshing_p}] &&
         [info exists on_refresh] } {
        ad_page_contract_eval uplevel #$level $on_refresh
    }

    if { [template::form is_valid $form_name] && ![uplevel #$level {set __refreshing_p}] } {

        # Run confirm and preview templates before we do final processing of the form

        if { [info exists confirm_template] && ![uplevel #$level {set __confirmed_p}] } {

            # Pass the form variables to the confirm template, applying the to_html filter if present

            set args [list]
            foreach element_name $af_element_names($form_name) {
                if { [llength $element_name] == 1 } {
                    if { [info exists af_to_html(${form_name}__$element_name)] } {
                        uplevel #$level [list set $element_name \
                            [uplevel #$level [list template::util::$af_type(${form_name}__$element_name)::get_property \
                                          $af_to_html(${form_name}__$element_name) \
                                          [uplevel #$level [list set $element_name]]]]]
                    }
                    lappend args [list $element_name [uplevel #$level [list set $element_name]]]
                }
            }

            # This is serious abuse of ad_return_exception_template, but hell, I wrote it so I'm entitled ...

            ad_return_exception_template -status 200 -params $args $confirm_template

        }

        # We have three possible ways to handle the form

        # 1. an on_submit block (useful for forms that don't touch the database or can share smart Tcl API
        #    for both add and edit forms)
        # 2. an new_data block (when __new_p is true)
        # 3. an edit_data block (when __new_p is false)
        # 4. an after_submit block (for ad_returnredirect and the like that is the same for new and edit)

        # We don't need to interrogate the af_parts structure because we know we're in the last call to
        # to ad_form at this point and that this call contained the "action blocks".

        # Execute our to_sql filters, if any, before passing control to the caller's
        # on_submit, new_data, edit_data or after_submit blocks

        foreach element_name $af_element_names($form_name) {
            if { [llength $element_name] == 1 } {
                if { [info exists af_to_sql(${form_name}__$element_name)] } {
                    uplevel #$level [list set $element_name \
                        [uplevel #$level [list template::util::$af_type(${form_name}__$element_name)::get_property \
                                      $af_to_sql(${form_name}__$element_name) \
                                      [uplevel #$level [list set $element_name]]]]]
                }
            }
        }

        if { [info exists on_submit] } {
            ad_page_contract_eval uplevel #$level $on_submit
        }

        upvar #$level __new_p __new_p

        if { [info exists new_data] && $__new_p } {
            ad_page_contract_eval uplevel #$level $new_data
            template::element::set_value $form_name __new_p 0
        } elseif { [info exists edit_data] && !$__new_p } {
            ad_page_contract_eval uplevel #$level $edit_data
        }

        if { [info exists after_submit] } {
            ad_page_contract_eval uplevel #$level $after_submit
        }
    }

    template::element::set_value $form_name __refreshing_p 0
    template::element::set_value $form_name __confirmed_p 0

}

ad_proc -public ad_set_element_value {
    -element:required
    value
} {
    Set the value of a particular element in the current form being built by 
    ad_form.

    @param element The name of the element
    @param value The value to set

} {
    upvar #[template::adp_level] __ad_form_values__ values
    set values($element) $value
}

ad_proc -public ad_set_form_values {
    args
} {

    Set multiple values in the current form.

    @param args A list of values to set.   Each two-element value in the list is evaluated as
                a name, value pair.  Each single-element value is assumed to have its value
                set in a variable of the same name local to our caller.

    Example:

        set_element_values language_id { some_var some_value } { another_var another_value }

} {
    foreach arg $args {
        if { [llength $arg] == 1 } {
            upvar $arg value
            ad_set_element_value -element $arg $value
        } else {
            ad_set_element_value -element [lindex $arg 0] [lindex $arg 1]
        }
    }
}

ad_proc -public ad_form_new_p {
    -key
} {

    This is for pages built with ad_form that handle edit and add requests in one file.
    It determines wether the current request is for editing an existing item, 
    in which case it returns 0, or adding a new one, which will return 1.
    
    <p>

    For this to work there needs to be an element defined in the form that is of
    the ad_form pseudo datatype "key". If you don't specify -key then this proc
    will try to guess it from the existing variables - if there is exactly one that 
    ends on _id then it takes that one, otherwise you have to specify it manually.

    <p>

    It does not make sense to use this in pages that don't use ad_form.

    <p>

    Example usage:
    <pre>
    if { [ad_form_new_p] } {
        ad_require_permission $package_id create
        set page_title "New Item"
    } else {
        ad_require_permission $item_id write
        set page_title "Edit Item"
    }

    </pre>

    @param key the name of the key element. In the above example: <code>ad_form_new_p -key item_id</code>
} {

    set form [ns_getform]
    if { [empty_string_p $form] } {
        # no form. assume new
        return 1
    }
    
    if { ![info exists key] } {
        # no key name given. loop through form and try to guess one

        for { set i 0 } { $i < [ns_set size $form] } { incr i } {
            
            if { [regexp {_id$} [ns_set key $form $i]] } {
                # this could be a key
                
                if { [info exists key] } {
                    # we found one before already, bad. throw an error
                    unset key
                    break
                }
                set key [ns_set key $form $i]
            }
        }
        if { ![info exists key] } {
            ad_return_error "ad_form_new_p failed" "Could not guess key element. Please specify it by using \"ad_form_new_p -key your_key_id\"."
            ad_script_abort
        }
    }

    if { [ns_set find $form $key] == -1 } {
        # no key
        return 1
    }

    if { [ns_set get $form __new_p] == 1 } {
        # there is a key, but __new_p is also set
        return 1
    }
    
    # not new
    return 0
}
