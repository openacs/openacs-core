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

    <p><a href="/doc/form-builder">Developer's Guide fo ad_form</a>
    <p>

    We use the standard OpenACS Templating System (ATS) form builder's form and element create 
    procedures to generate forms, and its state-tracking code to determine when to execute 
    various code blocks.  Because of this, you can use any form builder datatype or widget 
    with this procedure, and extending its functionality is a simple matter of implementing 
    new ones. Because ad_form is just a wrapper for the ATS, you <b>must</b> familiarize
    yourself with it to be able to use ad_form effectively.

    <p>

    In general the full functionality of the form builder is exposed by ad_form, but with a
    much more user-friendly and readable syntax and with state management handled automatically.

    <p>

    <blockquote style="border: 1px dotted grey; padding: 8px; background-color: #ddddff;">

    <b>Important note about how ad_form works:</b> ad_form operates in two modes:
    <ol>
    <li>Declaring the form
    <li>Executing the form
    </ol>
    Through the -extend switch, you can declare the form in multiple steps, adding elements.
    But as soon as you add an action block (on_submit, after_submit, new_data, edit_data, etc.), 
    ad_form will consider the form complete, and <b>execute</b> the form, meaning validating element values,
    and executing the action blocks. The execution will happen automatically the first time you 
    call ad_form with an action block, and after that point, you cannot -extend the form later.
    Also, if you don't supply any action blocks at all, the form will never be considered finished,
    and thus validation will not get executed. Instead, you will get an error when the form is rendered.
    
    <p>

    <b>Bottom line:</b> 
    <ol>
    <li>You must always have at least one action block, even if it's just -on_submit { }.
    <li>You cannot extend the form after you've supplied any action block.
    </ol>
    
    </blockquote>

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

    Here's an example of a simple page implementing an add/edit form and exporting different kinds of values:

    <blockquote><pre>

    ad_page_contract {


        Simple add/edit form

    } {
        {foo ""}
        my_table_key:optional
        many_values:multiple
        signed_var:verify
        big_array:array
    }

    ad_form -name form_name \
     -export {
        foo 
        {bar none} 
        many_values:multiple
        signed_var:sign
        big_array:array
      } -form {

        my_table_key:key(my_table_sequence)
        
        {value:text(textarea)             
            {label "Enter text"}
            {html {rows 4 cols 50}}
        }
        
    } -select_query {
        select value from my_table where my_table_key = :my_table_key
    } -validate {
        {value
         {[string length $value] >= 3}
         "\$value\" must be a string containing three or more characters"
        }
    } -on_submit {
        
        foreach val $many_values {
          # do stuff
        }
        
        if {[info exists big_array(some_key)]} {
            set some_value $big_array(some_key)
        }
        
        set safe_verified_value $signed_var
        
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
        snippets common to several data entry forms. Note that the full form block must be built up
        (extended) and completed before any action blocks such as select_query, new_request, edit_request etc.
        are defined.
        <p>This must be the first switch passed into ad_form
    </dd>

    <p><dt><b>-name</b></dt><p>
    <dd>Declares the name of the form.  Defaults to the name of the script being served.</dd>

    <p><dt><b>-action</b></dt><p>
    <dd>The name of the script to be called when the form is submitted.  Defaults to the name of the script
        being served.  
    </dd>

    <p><dt><b>-actions</b></dt><p>
    <dd>A list of lists of actions (e.g. {{"  Delete  " delete} {"  Resolve " resolve}} ), which gets 
        translated to buttons at the bottom of the form. You can find out what button was pressed 
        with [template::form get_action form_id], usually in the -edit_request block to perform whatever
        actions you deem appropriate. When the form is loaded the action will be empty.
    </dd>
    
    <p><dt><b>-mode { display | edit }</b></dt><p>
    <dd>If set to 'display', the form is shown in display-only mode, where the user cannot edit the fields. 
        Each widget knows how to display its contents appropriately, e.g. a select widget will show 
        the label, not the value. If set to 'edit', the form is displayed as normal, for editing. 
        Defaults to 'edit'. Switching to edit mode when a button is clicked in display mode is handled 
        automatically
    </dd>
    
    <p><dt><b>-has_edit { 0 | 1 }</b></dt><p>
    <dd>Set to 1 to suppress the Edit button automatically added by the form builder. Use this if you 
        include your own.
    </dd>

    <p><dt><b>-has_submit { 0 | 1 }</b></dt><p>
    <dd>Set to 1 to suppress the OK button automatically added by the form builder. Use this if you 
        include your own.
    </dd>

    <p><dt><b>-method</b></dt><p>
    <dd>The standard METHOD attribute to specify in the HTML FORM tag at the beginning of the rendered 
        form. Defaults to POST.
    </dd>

    <p><dt><b>-form</b></dt><p>
    <dd>Declare form elements (described in detail below)
    </dd>

    <p><dt><b>-cancel_url</b></dt><p>
    <dd>The URL the cancel button should take you to. If this is specified, a cancel button will show up
        during the edit phase.
    </dd>

    <p><dt><b>-cancel_label</b></dt><p>
    <dd>The label for the cancel button.
    </dd>

    <p><dt><b>-html</b></dt><p>
    <dd>The given html will be added to the "form" tag when page is rendered.  This is commonly used to
        define multipart file handling forms.
    </dd>

    <p><dt><b>-export</b></dt><p>
    <dd>This options allows to export data in current page environment to the page receiving the form.
        Variables are treated as "hidden" form elements which will be automatically generated. Each value is 
        either a name, in which case the Tcl variable at the caller's level is passed to the form if it exists, 
        or a name-value pair.
        The behavior of this option replicates that for <code>vars</code> argument in proc 
        <a href='/api-doc/proc-view?proc=export_vars&amp;source_p=1'>export_vars</a>, which in turn follows specification 
    for input page variables in <a href='/api-doc/proc-view?proc=ad_page_contract&amp;source_p=1'>ad_page_contract</a>.
        In particular, flags <code>:multiple</code>, <code>:sign</code> and <code>:array</code> are allowed and 
        their meaning is the same as in <code>export_vars</code>.
    </dd>
        
    <p><dt><b>-select_query</b></dt><p>
    <dd>
    Defines a query that returns a single row containing values for each
    element of the form meant to be modifiable by the user.  Can only be
    used if an element of type key has been declared. Values returned from
    the query are available in the form, but not the ADP template (for
    that, use -edit_request instead).
    </dd>

    <p><dt><b>-select_query_name</b></dt><p>
    <dd>
    Identical to -select_query, except instead of specifying the query
    inline, specifies a query name. The query with that name from the
    appropriate XQL file will be used. Use -select_query_name rather than
    -select_query whenever possible, as query files are the mechanism used
    to make the support of multiple RDMBS systems possible.
    </dd>

    <p><dt><b>-show_required_p { 0 | 1 }</b></dt><p>
    <dd>Should the form template show which elements are required. Use 1 or t for true, 0 or f for false. 
       Defaults to true.
    </dd>

    <p><dt><b>-on_request</b></dt><p>
    <dd>A code block which sets the values for each element of the form meant to be modifiable by
        the user when the built-in key management feature is being used or to define options for
        select lists etc. Set the values as local variables in the code block, and they'll get 
        fetched and used as element values for you. This block is executed <i>every time</i> the
        form is loaded <i>except</i> when the form is being submitted (in which case the -on_submit
        block is executed.)
    </dd>

    <p><dt><b>-edit_request</b></dt><p>
    <dd>    
    A code block which sets the values for each element of the form meant
    to be modifiable by the user.  Use this when a single query to grab
    database values is insufficient.  Any variables set in an -edit_request
    block are available to the ADP template as well as the form, while
    -select_query sets variables in the form only. Can only be used if an
    element of type key is defined.  This block is only executed if the
    page is called with a valid key, i.e. a self-submit form to add or edit
    an item called to edit the data. Set the values as local variables in
    the code block, and they'll get fetched and used as element values for
    you.
    </dd>

    <p><dt><b>-new_request</b></dt><p>
    <dd>A code block which sets the values for each element of the form meant to be modifiable by the user.  Use
        this when a single query to grab database values is insufficient.  Can only be used if an element of
        type key is defined.  This block complements the -edit_request block. You just need to set the values as local
        variables in the code block, and they'll get fetched and used as element values for you.
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

    <p><dt><b>-on_refresh</b></dt><p>
    <dd>Executed when the form comes back from being refreshed using javascript with the __refreshing_p flag set.
    </dd>

    <p><dt><b>-on_submit</b></dt><p>
    <dd>When the form is submitted, this code block will be executed before any new_data or edit_data code block.
        Use this if your form doesn't interact with the database or if the database type involved includes a Tcl
        API that works for both new and existing data. The values of the form's elements will be available as local variables.
        Calling 'break' inside this block causes the submission process to be aborted, and neither new_data, edit_data, nor 
        after_submit will get executed. Useful in combination with template::form set_error to display an error on a form 
        element.
    </dd>

    <p><dt><b>-new_data</b></dt><p>
    <dd>This code block will be executed when a form for a new database row is submitted.  This block should
        insert the data into the database or create a new database object or content repository item containing
        the data.
        Calling 'break' inside this block causes the submission process to be aborted, and  
        after_submit will not get executed. Useful in combination with template::form set_error to display an error on a form 
        element.
    </dd>

    <p><dt><b>-edit_data</b></dt><p>
    <dd>This code block will be executed when a form for an existing database row is submitted.  This block should
        update the database or create a new content revision for the exisiting item if the data's stored in the
        content repository.
        Calling 'break' inside this block causes the submission process to be aborted, and  
        after_submit will not get executed. Useful in combination with template::form set_error to display an error on a form 
        element.
    </dd>

    <p><dt><b>-after_submit</b></dt><p>
    <dd>This code block will be executed after the three blocks on_submit, new_data or edit_data have been
    executed. It is useful for putting in stuff like ad_returnredirect that is the same for new and edit.
    </dd>

    <p><dt><b>-validate</b></dt><p>
    <dd>A code block that validates the elements in the form. The elements are set as local values.
        The block has the following form:
       <pre>
{element_name
    {tcl code that returns 1 or 0}
    "Message to be shown by that element in case of error"
}
{...}
       </pre>
    </dd>


    <p><dt><b>-on_validation_error</b></dt><p>
    <dd>A code block that is executed if validation fails.  This can be done to set
        a custom page title or some similar action.
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
    elements.  The first member of each element sublist declares the form element name, datatype, widget, whether or
    not the element is a multiple element (multiselect, for instance), and optional conversion arguments.  The second,
    optional member consists of a list of form element parameters and values.  All parameters accepted by the form
    element create procedure are allowed.

    <p>
  
    <ul>
      <li>
        <a href="/api-doc/proc-search?query%5fstring=template%3a%3adata%3a%3avalidate">Available datatypes</a>. 
        For example, the procedure <code>template::data::validate::float</code> on this list implements the 'float' datatype.
      </li>
      <li>
        <a href="/api-doc/proc-search?query_string=template%3A%3Awidget">Available widgets</a>.
        For example, the procedure <code>template::widget::radio</code> implements the 'radio' widget. 
        Not all widgets are compatible with all datatypes.
      </li>
      <li>
        <a href="/api-doc/proc-view?proc=template%3a%3aelement%3a%3acreate">Form element parameters and values</a>.
        For example, the parameter <code>-label "My label"</code> is written <code>{label "My label"}</code> in the
        element sublist of the -form block to ad_form.
      </li>
    </ul>

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
    start_date:date,to_sql(linear_date),to_html(sql_date),optional
    </pre><p>

    Define the optional element "start_date" of type "date", get the sql_date property before executing
    any new_data, edit_data or on_submit block, set the sql_date property after performing any
    select_query. 

    <p>
    </blockquote>

    <blockquote><pre>
    {email:text,nospell                      {label "Email Address"}
                                              {html {size 40}}}
    </pre><p>

    Define an element of type text with spell-checking disabled. In case spell-checking is enabled globally
    for the widget of this element ("text" in the example), the "nospell" flag will override that parameter
    and disable spell-checking on this particular element. Currently, spell-checking can be enabled for
    these widgets: text, textarea, and richtext.

    <p>
    </blockquote>

    @see ad_form_new_p
    @see ad_set_element_value
    @see ad_set_form_values

} {
    set level [template::adp_level]

    # Are we extending the form?

    if {[lindex $args 0] eq "-extend"} {
        set extend_p 1
        set args [lrange $args 1 end]
    } else {
        set extend_p 0
    }

    # Parse the rest of the arguments

    if { [llength $args] == 0 } {
        return -code error "No arguments to ad_form"
    } 

    set valid_args { form method action mode html name select_query select_query_name new_data
                     on_refresh edit_data validate on_submit after_submit confirm_template
                     on_request new_request edit_request export cancel_url cancel_label
                     has_submit has_edit actions edit_buttons display_buttons show_required_p 
                     on_validation_error fieldset };

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
        return -code error "Can't extend form \"$form_name\" - a parameter block requiring the full form has already been declared"
    }

    # Allow an empty form to work until we see an action block, useful for building up
    # forms piecemeal.

    global af_element_names
    if { !$extend_p } {
        set af_element_names($form_name) [list]
    }

    global af_parts

    foreach valid_arg $valid_args {
        if { [info exists $valid_arg] } {
            if { [info exists af_parts(${form_name}__$valid_arg)] 
                 && $valid_arg ni { form name validate export }
             } {
                return -code error "Form \"$form_name\" already has a \"$valid_arg\" section"
            }

            set af_parts(${form_name}__$valid_arg) ""

            # Force completion of the form if we have any action block.  We only allow the form
            # and validation block to be extended, for now at least until I get more experience
            # with this ...

            if {$valid_arg ni {
                name form method action html validate export mode cancel_url
                has_edit has_submit actions edit_buttons display_buttons
                fieldset on_validation_error
            }} {
                set af_parts(${form_name}__extend) ""
            }
        }
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

    global af_flag_list
    global af_to_sql
    global af_from_sql
    global af_to_html

    # Track element names and their parameters locally as we'll generate those in this form
    # or extend block on the fly

    set element_names [list]
    array set af_element_parameters [list] 

    if { [info exists form] } {
        
        # Remove comment lines in form section (DanW)
        regsub -all -line -- {^\s*\#.*$} $form "" form
        
        foreach element $form {
            set element_name_part [lindex $element 0]

            # This can easily be generalized if we add more embeddable form commands ...

            if {$element_name_part eq "-section"} {
                lappend af_element_names($form_name) [concat -section [uplevel [list subst [lrange $element 1 end]]]]
            } else {
                set element_name_part [uplevel [list subst $element_name_part]]
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
                        if { [string index $flag end] ne ")" } {
                            return -code error "Missing or misplaced end parenthesis for flag '$flag' on argument '$element_name'"
                        }
                        set flag_stem [string range $flag 0 $left_paren-1]
                        lappend af_element_parameters($element_name:$flag_stem) \
                            [string range $flag $left_paren+1 [string length $flag]-2]
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
    if { !$extend_p } {
        set af_validate_elements($form_name) [list]
    }

    if { [info exists validate] } {

        # Remove comment lines in validate section (DanW)
        regsub -all -line -- {^\s*\#.*$} $validate "" validate

        foreach validate_element $validate {
            if { [llength $validate_element] != 3 } {
                return -code error "Validate block must have three arguments: element name, expression, error message"
            }

            set element_name [lindex $validate_element 0]
            if {$element_name ni $af_element_names($form_name) 
                && ![template::element::exists $form_name $element_name]
            } {
                return -code error "Element \"$element_name\" is not a form element"
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

        if { [info exists mode] } {
            lappend create_command "-mode" $mode
        }

        if { [info exists cancel_url] } {
            lappend create_command "-cancel_url" $cancel_url
        }

        if { [info exists cancel_label] } {
            lappend create_command "-cancel_label" $cancel_label
        }

        if { [info exists html] } {
            lappend create_command "-html" $html
        }

        if { [info exists has_edit] } {
            lappend create_command "-has_edit" $has_edit
        }

        if { [info exists has_submit] } {
            lappend create_command "-has_submit" $has_submit
        }

        if { [info exists actions] } {
            lappend create_command "-actions" $actions
        }

        if { [info exists edit_buttons] } {
            lappend create_command "-edit_buttons" $edit_buttons
        }

        if { [info exists display_buttons] } {
            lappend create_command "-display_buttons" $display_buttons
        }

        if { [info exists fieldset] } {
            lappend create_command "-fieldset" $fieldset
        }

        if { [info exists show_required_p] } {
            lappend create_command "-show_required_p" $show_required_p
        }

        # Create the form

        {*}$create_command

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

        # add the hidden button element
        template::element create $form_name "__submit_button_name" -datatype text -widget hidden -value ""
        template::element create $form_name "__submit_button_value" -datatype text -widget hidden -value ""
    }

    # Antonio Pisano: now ad_form supports :multiple, 
    # :array and :sign flags in exported variables.
    if { [info exists export] } {
        foreach value $export {
            set has_value_p [expr {[llength $value] >= 2}]
            lassign $value name value

            # recognize supported flags
            lassign [split $name ":"] name mode
            set modes [split $mode ,]

            # verify variable existence and nature
            set var_exists_p [uplevel [list info  exists $name]]
            set is_array_p   [uplevel [list array exists $name]]

            # arrays are automatically recognized, even if not specified
            set array_p    [expr {$is_array_p || "array" in $modes}]
            set sign_p     [expr {"sign"     in $modes}]
            set multiple_p [expr {"multiple" in $modes}]
            
            if {$array_p} {
              # no explicit value:
              if {!$has_value_p} {
                # if array in caller stack exists, get its value from there
                if {$is_array_p} {
                  set value [uplevel [list array get $name]]
                # else, if a variable exists but it's not an array, throw error (as in export_vars)
                } elseif {$var_exists_p} {
                    error "variable \"$name\" should be an array"
                # else, just ignore this export
                } else {continue}
              }
              # arrays generate one hidden formfield for each key
              foreach {key val} $value {
                set val [uplevel [list subst $val]]
                # field is multiple: use '-values' instead of '-value'
                if {$multiple_p} {
                  template::element create $form_name ${name}.${key} \
                      -datatype text -widget hidden \
                      -values $val
                } else {
                  template::element create $form_name ${name}.${key} \
                      -datatype text -widget hidden \
                      -value $val
                }
              }
            } else {
              # no explicit value:
              if {!$has_value_p} {
                # if variable in caller stack exists, get its value from there
                if {$var_exists_p} {
                  set value [uplevel [list set $name]]
                # else, just ignore this export
                } else {continue}
              } else {
                #
                # substitute only the explicitly specified value
                #
                set value [uplevel [list subst $value]]
              }
              # field is multiple: use '-values' instead of '-value'
              if {$multiple_p} {
                template::element create $form_name $name \
                    -datatype text -widget hidden \
                    -values $value
              } else {
                template::element create $form_name $name \
                    -datatype text -widget hidden \
                    -value $value
              }
            }
            if {$sign_p} {
                # value is signed and its signature sent as another hidden field.
                # lsort is required for arrays, as 'array get' doesn't specify
                # the order of extraction of elements and we could have different
                # signature for the same array
                template::element create $form_name $name:sig \
                  -datatype text -widget hidden \
                  -value [ad_sign [lsort $value]]
            }
        }
    }

    # We need to track these for submission time and for error checking

    global af_type
    global af_key_name
    global af_sequence_name

    foreach element_name $element_names {
        if { [lindex $element_name 0] eq "-section" } {
            set command [list template::form section]
            foreach option [lrange $element_name 2 end] {
                lassign $option switch args
                switch $switch {
                    fieldset -
                    legendtext -
                    legend {
                        lappend command -$switch $args
                    }
                    default {return -code error "\"$switch\" is not a legal -section option"}
                }
            }
            lappend command $form_name [lindex $element_name 1]
            {*}$command
        } else {
            set form_command [list template::element create $form_name $element_name]
            foreach flag $af_flag_list(${form_name}__$element_name) {
                switch $flag {

                    key {
                        if { [info exists af_key_name($form_name)] } {
                            return -code error "element $element_name: a form can only declare one key"
                        }
                        set af_key_name($form_name) $element_name
                        set af_type(${form_name}__$element_name) integer
                        if { $af_element_parameters($element_name:key) ne "" } {
                            if { [info exists af_sequence_name($form_name)] } {
                                return -code error "element $element_name: duplicate sequence"
                            }
                            set af_sequence_name($form_name) $af_element_parameters($element_name:key)
                        }
                        lappend form_command "-datatype" "integer" "-widget" "hidden"
                        template::element create $form_name __key_signature -datatype text -widget hidden -value ""
                        template::element create $form_name __key -datatype text -widget hidden -value $element_name
                        template::element create $form_name __new_p -datatype integer -widget hidden -value 0
                    }

                    multiple {
                        if { $af_element_parameters($element_name:$flag) ne "" } {
                            return -code error "element $element_name: $flag attribute can not have a parameter"
                        }
                    }

                    nospell -
                    optional {
                        if { $af_element_parameters($element_name:$flag) ne "" } {
                            return -code error "element $element_name: $flag attribute can not have a parameter"
                        }
                        lappend form_command "-$flag"
                    }

                    from_sql -
                    to_sql -
                    to_html {
                        if { $af_element_parameters($element_name:$flag) eq "" } {
                            return -code error "element $element_name: \"$flag\" attribute must have a parameter"
                        }
                        set name af_$flag
                        global af_$flag
                        append name "(${form_name}__$element_name)"
                        if { [info exists $name] } {
                            return -code error "element $element_name: \"$flag\" appears twice"
                        }
                        set $name $af_element_parameters($element_name:$flag)
                    }

                    default {
                        if { [info commands "::template::data::validate::$flag"] eq "" } {
                           return -code error "element $element_name: data type \"$flag\" is not valid"
                        }
                        lappend form_command "-datatype" $flag
                        set af_type(${form_name}__$element_name) $flag
                        if { $af_element_parameters($element_name:$flag) eq "" } {
                            if { [info commands "::template::widget::$flag"] ne "" } {
                                lappend form_command "-widget" $flag
                            }
                        } else {
                            if { [info commands "::template::widget::$af_element_parameters($element_name:$flag)"] eq ""} {
                                return -code error "element $element_name: widget \"$af_element_parameters($element_name:$flag)\" does not exist"
                            }
                            lappend form_command "-widget" $af_element_parameters($element_name:$flag)
                        }
                    }
                }
            }
              
            foreach extra_arg $af_extra_args($element_name) {
                lappend form_command "-[lindex $extra_arg 0]" [uplevel [list subst [lindex $extra_arg 1]]]
            }
            {*}$form_command

        }
    }

    # Check that any acquire and get_property attributes are supported by their element's datatype
    # These are needed at submission and fill-the-form-with-db-values time 
    foreach element_name $af_element_names($form_name) {
        if { [llength $element_name] == 1 } {
            if { [info exists af_from_sql(${form_name}__$element_name)] } {
                if { [info commands "::template::util::$af_type(${form_name}__$element_name)::acquire"] eq "" } {
                    return -code error "\"from_sql\" not valid for type \"$af_type(${form_name}__$element_name)\""
                }
            }
            if { [info exists af_to_sql(${form_name}__$element_name)] } {
                if { [info commands ::template::util::$af_type(${form_name}__$element_name)::get_property] eq "" } {
                    return -code error "\"to_sql\" not valid for type \"$af_type(${form_name}__$element_name)\""
                }
            }
            if { [info exists af_to_html(${form_name}__$element_name)] } {
                if { [info commands ::template::util::$af_type(${form_name}__$element_name)::get_property] eq "" } {
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

    if { ![info exists af_parts(${form_name}__form)] } {
        return -code error "No \"form\" block has been specified for form \"$form_name\""
    }

    if { [template::form is_request $form_name] } {

        upvar #$level __ad_form_values__ values

        if { [template::form is_request $form_name] && [info exists on_request] } {
            ad_page_contract_eval uplevel #$level $on_request
            foreach element_name $af_element_names($form_name) {
                if { [llength $element_name] == 1 } {
                    if { [uplevel \#$level [list info exists $element_name]] } {
                        set values($element_name) [uplevel \#$level [list set $element_name]]
                        if { [info exists af_from_sql(${form_name}__$element_name)] } {
                            set values($element_name) [template::util::$af_type(${form_name}__$element_name)::acquire \
                                                       $af_from_sql(${form_name}__$element_name) $values($element_name)]
                        }
                    }
                }
            }
        }

        if { [info exists af_key_name($form_name)] } {

            set key_name $af_key_name($form_name)
            upvar #$level $key_name $key_name

            # Check to see if we're editing an existing database value
            if { [info exists $key_name] } {
                if { [info exists edit_request] } {
                    if { [info exists select_query] || [info exists select_query_name] } {
                        return -code error "Edit request block conflicts with select query"
                    }
                    ad_page_contract_eval uplevel #$level $edit_request
                    foreach element_name $af_element_names($form_name) {
                        if { [llength $element_name] == 1 } {
                            if { [uplevel \#$level [list info exists $element_name]] } {
                                set values($element_name) [uplevel \#$level [list set $element_name]]
                            }
                        }
                    }            

                } else {

                    # The key exists, grab the existing values if we have an select_query clause

                    if { ![info exists select_query] && ![info exists select_query_name] } {
                        return -code error "Key \"$key_name\" has the value \"[set $key_name]\" but no select_query, select_query_name, or edit_request clause exists.  (This can be caused by having ad_form request blocks in the wrong order.)" 
                    }

                    if { [info exists select_query_name] } {
                        set select_query ""
                    } else {
                        set select_query_name ""
                    }

                    if { ![uplevel #$level [list db_0or1row $select_query_name [join $select_query " "] -column_array __ad_form_values__]] } {
                        return -code error "Error when selecting values: No rows returned."
                    }

                    foreach element_name $af_element_names($form_name) {
                        if { [llength $element_name] == 1 } {
                            if { [info exists af_from_sql(${form_name}__$element_name)] } {
                                set values($element_name) [template::util::$af_type(${form_name}__$element_name)::acquire \
                                                           $af_from_sql(${form_name}__$element_name) $values($element_name)]
                            } elseif { [info commands ::template::data::from_sql::$af_type(${form_name}__$element_name)] ne "" } {
                                set values($element_name) [template::data::from_sql::$af_type(${form_name}__$element_name) $values($element_name)]
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

                if { [catch {set values($key_name) [db_nextval $sequence_name]} errmsg]} {
                    return -code error "Couldn't get the next value from sequence: $errmsg\""
                }
                set values(__new_p) 1
                
                if { [info exists new_request] } {
                    ad_page_contract_eval uplevel #$level $new_request
                    # LARS: Set form values based on local vars in the new_request block
                    foreach element_name $af_element_names($form_name) {
                        if { [llength $element_name] == 1 } {
                            if { [uplevel \#$level [list info exists $element_name]] } {
                                set values($element_name) [uplevel \#$level [list set $element_name]]
                            }
                        }
                    }            
                }
            }
            set values(__key_signature) [ad_sign -- "$values($key_name):$form_name"]
        }

        foreach element_name $properties(element_names) {
            if { [info exists values($element_name)] } {
                if { [info exists af_flag_list(${form_name}__$element_name)] 
                     && "multiple" in $af_flag_list(${form_name}__$element_name)
                 } {
                    template::element set_values $form_name $element_name $values($element_name)
                } else {
                    template::element set_value $form_name $element_name $values($element_name)
                }
            }
        }

    } elseif { [template::form is_submission $form_name] } { 

        # Handle form submission.  We create the form values in the caller's context and execute validation
        # expressions if they exist

        # Get all the form elements.  We can't call form get_values because it doesn't handle multiples
        # in a reasonable way.

        foreach element_name $properties(element_names) {
            if { [info exists af_flag_list(${form_name}__$element_name)] 
                 && "multiple" in $af_flag_list(${form_name}__$element_name)
             } {
                set values [uplevel #$level [list template::element get_values $form_name $element_name]]
                uplevel #$level [list set $element_name $values]
#                 "get_values $values"
            } else {
                set value [uplevel #$level [list template::element get_value $form_name $element_name]]
                uplevel #$level [list set $element_name $value]
            }
        }

        # Update the clicked button if it does not already exist
        uplevel #$level {
                if {![exists_and_not_null ${__submit_button_name}]} {
                    set ${__submit_button_name} ${__submit_button_value}
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
                if { ![template::element error_p $form_name $element_name] 
                     && ![uplevel #$level [list expr $validate_expr]] 
                 } {
                    template::element set_error $form_name $element_name [uplevel [list subst $error_message]]
                }
            }
        }
    }

    if { [template::form is_submission $form_name] } {
        upvar #$level __refreshing_p __refreshing_p __confirmed_p __confirmed_p
        #
        # The values for __refreshing_p and __confirmed_p are returend
        # from the client.  Since Submitting invalid data to hidden
        # elements is a common attack vector, we react harsh if we see
        # an invalid input here.
        #
        if {![string is boolean -strict $__refreshing_p] 
            || ![string is boolean -strict $__confirmed_p] } {
            ad_return_complaint 1 "Your request is invalid."
            ns_log Warning "Validation error in hidden form element.\
                This may be part of a vulnerability scan or attack reconnaissance: \
                fish values __refreshing_p '$__refreshing_p' or __confirmed_p '$__confirmed_p'"
            ad_script_abort
        }
        if { $__refreshing_p } {
            uplevel array unset ${form_name}:error

            if { [info exists on_refresh] } {
                ad_page_contract_eval uplevel #$level $on_refresh
            }
        } else {
            # Not __refreshing_p 

            if { [template::form is_valid $form_name] } {

                # Run confirm and preview templates before we do final processing of the form

                if { [info exists confirm_template] && ! $__confirmed_p } {

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

                # Lars: We're wrapping this in a catch to allow people to throw a "break" inside
                # the code block, causing submission to be canceled
                # In order to make this work, I had to eliminate the ad_page_contract_eval's below
                # and replace them with simple uplevel's. Otherwise, we'd get an error saying
                # 'break used outside of a loop'.
                set errno [catch {
                    if { [info exists on_submit] } {
                        uplevel #$level $on_submit
                    }

                    upvar #$level __new_p __new_p

                    if {[info exists __new_p] && ![string is boolean -strict $__new_p]} {
                        ad_return_complaint 1 "Your request is invalid."
                        ns_log Warning "Validation error in hidden form element.\
                This may be part of a vulnerability scan or attack reconnaissance: fish values __new_p"
                        ad_script_abort
                    }

                    if { [info exists new_data] && $__new_p } {
                        uplevel #$level $new_data
                        template::element::set_value $form_name __new_p 0
                    } elseif { [info exists edit_data] && !$__new_p } {
                        uplevel #$level $edit_data
                    }

                    if { [info exists after_submit] } {
                        uplevel #$level $after_submit
                    }
                } error]

                # Handle or propagate the error. Can't use the usual
                # "return -code $errno..." trick due to the db_with_handle
                # wrapped around this loop, so propagate it explicitly.
                switch $errno {
                    0 {
                        # TCL_OK
                    }
                    1 {
                        # TCL_ERROR
                        error $error $::errorInfo $::errorCode
                    }
                    2 {
                        # TCL_RETURN
                        error "Cannot return from inside an ad_form block"
                    }
                    3 {
                        # TCL_BREAK
                        # nothing -- this is what we want to support
                    }
                    4 {
                        # TCL_CONTINUE
                        continue
                    }
                    default {
                        error "Unknown return code: $errno"
                    }
                }
           
            } elseif { [info exists on_validation_error] } {
                uplevel #$level $on_validation_error
            }
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
            ad_set_element_value -element $arg -- $value
        } else {
            set value [uplevel subst \{[lindex $arg 1]\}]
            ad_set_element_value -element [lindex $arg 0] -- $value
        }
    }
}

ad_proc -public ad_form_new_p {
    -key:required
} {

    This is for pages built with ad_form that handle edit and add requests in one file.
    It returns 1 if the current form being built for the entry of new data, 0 if for
    the editing of existing data.

    <p>

    It does not make sense to use this in pages that don't use ad_form.

    <p>

    @param key The database key for the form, which must be declared to be of type "key"

    <p>

    Example usage:
    <pre>
    if { [ad_form_new_p -key item_id] } {
        permission::require_permission -object_id $package_id -privilege create
        set page_title "New Item"
    } else {
        permission::require_permission -object_id $item_id -privilege write
        set page_title "Edit Item"
    }

    </pre>

    @param key the name of the key element. In the above example: <code>ad_form_new_p -key item_id</code>
} {

    set form [ns_getform]

    return [expr {$form eq "" || [ns_set find $form $key] == -1 || [ns_set get $form __new_p] == 1 }]

}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

