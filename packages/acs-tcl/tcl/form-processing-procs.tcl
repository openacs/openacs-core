ad_library {

    Form processing utilities.

    @author Don Baccus (dhogaza@pacifier.net)
}

ad_proc -public ad_form_prototype {
    args
} {
    I'll be adding more documentation as I get time (obviously)

    I know error checking's incomplete, too ...

    Three hidden values of interest are available to the caller of gp_form when processing
    a submit:

    1. __new_p

       If a database key has been declared, __new_p will be set true if the form
       submission is for a new value.  If false, the key refers to an existing
       values.  This is useful for forms that can easily process either operation
       in a single on_submit block, rather than use separate new_data and edit_data
       blocks.

    2. __confirmed_p

       If a confirm_template name has been specified, it is returned to the user until
       it sets _confirmed_p true.

    3. __refreshing_p

       This should be set true by Javascript widgets which change a form element then
       submit the form to refresh values.

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

    set valid_args { form method action html name select_query select_query_name new_data \
                     edit_data validate on_submit confirm_template \
                     new_request edit_request }; 

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
                 ![lsearch { form name validate } $valid_arg] == -1 } {
                return -code error "Form \"$form_name\" already has a \"$valid_arg\" section"
            }

            set af_parts(${form_name}__$valid_arg) ""

            # Force completion of the form if we have any action block.  We only allow the form
            # and validation block to be extended, for now at least until I get more experience
            # with this ...

            if { [lsearch { name form method action html validate } $valid_arg ] == -1 } {
                set af_parts(${form_name}__extend) ""
            }
        }
    }

    if { ![info exists af_parts(${form_name}__form)] } {
        return -code error "No \"form\" block has been specified for form \"$form_name\""
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

    # Check the validation block for boneheaded errors if it exists.  We explicitly allow a form element
    # to appear twice in the validation block so the caller can pair different error messages to different
    # checks.  We implement this by building a global list of validation elements

    global af_validate_elements

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
                        append name "($element_name)"
                        if { [info exists $name] } {
                            return -code error "element $element_name: \"$flag\" appears twice"
                        }
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
                    value {
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

    global af_from_sql
    global af_to_sql
    global af_to_html

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
        upvar #$level __gp_form_values__ values

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
                    template::element set_error $form_name $element_name $error_message
                }
            }
        }
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
        # 2. an new_data block (when form_name:add_p is true)
        # 3. an edit_data block (when form_name:add_p is false)

        # We don't need to interrogate the af_parts structure because we know we're in the last call to
        # to ad_form at this point and that this call contained the "action blocks".

        if { [info exists on_submit] } {
            ad_page_contract_eval uplevel #$level $on_submit
        }

        # Execute our to_sql filters, if any, before passing control to the caller's
        # new_data or edit_data blocks

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

        upvar #$level __new_p __new_p

        if { [info exists new_data] && $__new_p } {
            ad_page_contract_eval uplevel #$level $new_data
            template::element::set_value $form_name __new_p 0
        } elseif { [info exists edit_data] && !$__new_p } {
            ad_page_contract_eval uplevel #$level $edit_data
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
    gp_form.

    @param element The name of the element
    @parma value The value to set

} {
    upvar #[template::adp_level] __gp_form_values__ values
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
            gp_set_element_value -element $arg $value
        } else {
            gp_set_element_value -element [lindex $arg 0] [lindex $arg 1]
        }
    }
}

