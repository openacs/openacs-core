ad_library {

    Form processing utilities.

    @author Don Baccus (dhogaza@pacifier.net)
}

ad_proc -public ad_form_prototype {
    args
} {
    We'll document this when it works and has been committed 

    This version tracks the number of forms emitted for use with javascript widgets
    and includes a hidden variable to determine if you're refreshing a form, not
    really submitting it.

    I've renamed this ad_form_prototype to re-emphasize the fact that it's going
    to be changing in the future, though it's damned useful in its current form.

} {

    ####################
    #
    # Parse arguments
    #
    ####################


    if { [llength $args] == 0 } {
        return -code error "No arguments to ad_form"
    } 

    set valid_args { form method action html name select_query select_query_name add_data \
                     edit_data from_sql to_sql validate on_submit confirm_template extend}; 

    ad_arg_parser $valid_args $args

    set extending_p 0
    if { [info exists extend] } {
        if { [llength args] == 2 && ![info exists name] || \
             [llength args] > 2 } {
            return -code error "\"name\" is the only additional parameter allowed when extending a form"
           }
        set form $extend
        set extending_p 1
    } elseif { ![info exists form] } {
        return -code error "No \"form\" argument to ad_form"
    }

    if { [info exists on_submit] && ([info exists add_data] || [info exists edit_data]) } {
        return -code Error "\"on_submit\" not allowed in form with \"add_data\" or \"edit_data\""
    }

    # Set the form name, defaulting to the name of the template that called us

    if { [info exists name] } {
        set form_name $name
    } else {
        set form_name [file rootname [lindex [ad_conn urlv] end]]
    }

    ####################
    #
    # Step 1: Parse the form specification
    #
    ####################
    # BASIC STUFF:
    # list af_element_names                                list of form elements
    # array af_element_parameters($element_name:$flag:):   contains a list of the parameters for an element

    set af_element_names [list]

    array set af_element_parameters [list]

    foreach element $form {
        set element_name_part [lindex $element 0]

        # This can easily be generalized if we add more embeddable form commands ...

        if { [string equal $element_name_part "-section"] } {
            lappend af_element_names "[list "-section" [uplevel [list subst [lindex $element 1]]]]"
        } else {
            if { ![regexp {^([^ \t:]+)(?::([a-zA-Z0-9_,(|)]*))?$} $element_name_part match element_name flags] } {
                return -code error "Form element '$element_name_part' doesn't have the right format. It must be var\[:flag\[,flag ...\]\]"
            }

            lappend af_element_names $element_name
            set af_extra_args($element_name) [lrange $element 1 end]
            set pre_flag_list [split [string tolower $flags] ,]
            set af_flag_list($element_name) [list]

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
                    lappend af_flag_list($element_name) $flag_stem
                } else {
                    lappend af_flag_list($element_name) $flag
                }
            }
        }
    }

    # Check the validation block for boneheaded errors if it exists

    set af_validate_names [list]
    if { [info exists validate] } {
        foreach validate_element $validate {
            if { [llength $validate_element] != 3 } {
                return -code error "Validate block must have three arguments: element name, expression, error message"
            }

	    if { [lsearch $af_element_names [lindex $validate_element 0]] == -1 } {
	        return -code error "Element \"[lindex $validate_element 0]\" is not a form element"
            }

	    if { [lsearch $af_validate_names [lindex $validate_element 0]] != -1 } {
	        return -code error "Element \"[lindex $validate_element 0]\" appears in the validation block twice"
            }
	}
    }

    if { !$extending_p } {
        set create_command [list template::form create $form_name]

        if { [info exists action] } {
            lappend create_command "-action" $action
        }

        if { [info exists method] } {
            lappend create_command "-method" $method
        }

        # Create the form

        eval $create_command

        # if a confirm template has been specified, it will be returned unless __confirmed_p is set
        # true.  This is most easily done by including resources/forms/confirm-button in the confirm
        # template.

        template::element create $form_name __confirmed_p -datatype integer -widget hidden -value 0

        # javascript widgets can change a form value and submit the result in order to allow the
        # generating script to fill in a value such as an image.   The widget must set __refreshing_p
        # true.

        template::element create $form_name __refreshing_p -datatype integer -widget hidden -value 0
    }

    foreach element_name $af_element_names {
        if { [llength $element_name] == 2 } {
            switch [string range [lindex $element_name 0] 1 end] {
                section { template::form section $form_name [lindex $element_name 1] }
            }
        } else {
            set form_command [list template::element create $form_name $element_name]
            foreach flag $af_flag_list($element_name) {
                switch $flag {

                    key {
                        if { [info exists key_name] } {
                            return -code error "element $element_name: a form can only declare one key"
                        }
                        set key_name $element_name
                        if { ![empty_string_p $af_element_parameters($element_name:key)] } {
                            if { [info exists sequence_name] } {
                                return -code error "element $element_name: duplicate sequence"
                            }
                            set sequence_name $af_element_parameters($element_name:key)
                        }
                        lappend form_command "-datatype" "integer" "-widget" "hidden"
                        template::element create $form_name __key_signature -datatype text -widget hidden -value ""
                        template::element create $form_name __add_p -datatype integer -widget hidden -value 0
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
                        set af_type($element_name) $flag
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

    foreach element_name $af_element_names {
        if { [llength $element_name] == 1 } {
            if { [info exists af_from_sql($element_name)] } {
                if { [empty_string_p [info commands "::template::util::$af_type($element_name)::acquire"]] } {
                    return -code error "\"from_sql\" not valid for type \"$af_type($element_name)\""
                }
            }
            if { [info exists af_to_sql($element_name)] } {
                if { [empty_string_p [info commands "::template::util::$af_type($element_name)::get_property"]] } {
                    return -code error "\"to_sql\" not valid for type \"$af_type($element_name)\""
                }
            }
            if { [info exists af_to_html($element_name)] } {
                if { [empty_string_p [info commands "::template::util::$af_type($element_name)::get_property"]] } {
                    return -code error "\"to_html\" not valid for type \"$af_type($element_name)\""
                }
            }
        }
    }

    # Check for consistency if database operations are to be triggered by this form

    if { [info exists sequence_name] && ![info exists key_name] } {
        return -code error "You've supplied a sequence name no \"key_name\" parameter"
    }

    if { ([info exists from_sql] || [info exists to_sql])  && ![info exists key_name] } {
        return -code error "You've supplied a database transaction but no \"key_name\" parameter"
    }

    if { ([info exists select_query] || [info exists select_query_name]) && \
         ![info exists key_name] } {
        return -code error "You've supplied a select query but no \"key_name\" parameter"
    }

    if { [info exists select_query] && [info exists select_query_name] } {
        return -code error "You can only have one of \"select_query\" and \"select_query_name\""
    }

    # Handle a request form that triggers database operations

    if { [template::form is_request $form_name] && [info exists key_name] } { 
        upvar $key_name $key_name
        upvar __ad_form_values__ values

        # Check to see if we're editing an existing database value
        if { [info exists $key_name] } {

            # The key exists, grab the existing values if we have an select_query clause

            if { ![info exists select_query] && ![info exists select_query_name] } {
                return -code error "Key \"$key_name\" has the value \"[set $key_name]\" but no select_query or select_query_name clause exists"
            }

            if { [info exists select_query_name] } {
                set select_query ""
            } else {
                set select_query_name ""
            }

            if { ![uplevel [list db_0or1row $select_query_name [join $select_query " "] -column_array __ad_form_values__]] } {
                return -code error "Error when selecting values"
            }

            foreach element_name $af_element_names {
                if { [llength $element_name] == 1 } {
                    if { [info exists af_from_sql($element_name)] } {
                        set values($element_name) [template::util::$af_type($element_name)::acquire \
                                                   $af_from_sql($element_name) $values($element_name)]
                    }
                }
            }

            set values($key_name) [set $key_name]
            set values(__add_p) 0

        } else {

            # Make life easy for the OACS 4.5 hacker by automagically generating a value for
            # our new database row.

            if { ![info exists sequence_name] } {
                set sequence_name "acs_object_id_seq"
            }

            if { ![db_0or1row get_key "" -column_array values] } {
                return -code error "Couldn't get the next value from sequence \"$sequence_name\""
            }
            set values(__add_p) 1
        }

        set values(__key_signature) [ad_sign "$values($key_name):$form_name"]
        template::form set_values $form_name values

    } elseif { [template::form is_submission $form_name] } {

        # Handle form submission.  We create the form values in the caller's context and execute validation
        # expressions if they exist

        uplevel [list template::form get_values $form_name]

        if { [info exists key_name] } {
            upvar $key_name __key
            upvar __key_signature __key_signature

            if { [info exists __key] && ![ad_verify_signature "$__key:$form_name" $__key_signature] } {
                ad_return_error "Bad key signature" "Verification of the database key value failed"
            }
        }

        # Execute validation expressions.  We've already done some sanity checks so know the basic structure
        # is OK

        if { [info exists validate] } {
            foreach validate_element $validate {
                foreach {element_name validate_expr error_message} $validate_element {
                    if { ![template::element error_p $form_name $element_name] && \
                          [uplevel [list expr $validate_expr]] } {
                        template::element set_error $form_name $element_name $error_message
                    }
                }
            }
        }
    }

    if { [template::form is_valid $form_name] && ![uplevel {set __refreshing_p}] } {

        # Run confirm and preview templates before we do final processing of the form

        if { [info exists confirm_template] && ![uplevel {set __confirmed_p}] } {

            # Pass the form variables to the confirm template, applying the to_html filter if present

            set args [list]
            foreach element_name $af_element_names {
                if { [llength $element_name] == 1 } {
                    if { [info exists af_to_html($element_name)] } {
                        uplevel [list set $element_name \
                            [uplevel [list template::util::$af_type($element_name)::get_property \
                                          $af_to_html($element_name) \
                                          [uplevel [list set $element_name]]]]]
                    }
                    lappend args [list $element_name [uplevel [list set $element_name]]]
                }
            }

            # This is serious abuse of ad_return_exception_template, but hell, I wrote it so I'm entitled ...

            ad_return_exception_template -status 200 -params $args $confirm_template

        }

        # We have three possible ways to handle the form

        # 1. an on_submit block (useful for forms that don't touch the database)
        # 2. an add_data block (when form_name:add_p is true)
        # 3. an edit_data block (when form_name:add_p is false)

        # These three are mutually exclusive, which was checked above

        if { [info exists on_submit] } {
            ad_page_contract_eval uplevel 1 $on_submit
        } else {

            # Execute our to_sql filters, if any, before passing control to the caller's
            # add_data or edit_data blocks

            foreach element_name $af_element_names {
                if { [llength $element_name] == 1 } {
                    if { [info exists af_to_sql($element_name)] } {
                        uplevel [list set $element_name \
                            [uplevel [list template::util::$af_type($element_name)::get_property \
                                          $af_to_sql($element_name) \
                                          [uplevel [list set $element_name]]]]]
                    }
                }
            }

            upvar __add_p __add_p

            if { [info exists add_data] && $__add_p } {
                ad_page_contract_eval uplevel 1 $add_data
                template::element::set_value $form_name __add_p 0
            } elseif { [info exists edit_data] && !$__add_p } {
                ad_page_contract_eval uplevel 1 $edit_data
            }
        }
    }
    template::element::set_value $form_name __refreshing_p 0
    template::element::set_value $form_name __confirmed_p 0
}
