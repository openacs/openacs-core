ad_library {
    Form element procedures for the OpenACS Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
    @author Stanislav Freidin (sfreidin@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation
#
# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval template {}
namespace eval template::element {}

ad_proc -public element { command form_id element_id args } {
    element is really template::element although when in the
    "template" namespace you may omit the template:: qualifier.
    See the template::form api for creating the form element container.

    @see template::element
    @see template::form
} -    

ad_proc -public template::element { command form_id element_id args } {
    Manage elements of form objects. 
    <p>
    see the individual commands for further information.
    @param command one of create, error_p, exists, get_property, get_value, 
                          get_values, querygetall, set_error, set_properties, set_value
    @param form_id string identifying the form 
    @param element_id string identifying the element

    @see template::element::create
    @see template::element::error_p
    @see template::element::exists
    @see template::element::get_property
    @see template::element::get_value
    @see template::element::get_values
    @see template::element::querygetall
    @see template::element::set_error
    @see template::element::set_properties
    @see template::element::set_value 
    
    @see template::form
} {
  template::element::$command $form_id $element_id {*}$args
}

ad_proc -public template::element::create { form_id element_id args } {
    Append an element to a form object.  If a submission is in progress,
    values for the element are prepared and validated.

    @param form_id        The identifier of the form to which the element is to
                          be added.  The form must have been previously created
                          with a <tt>form create</tt> statement.

    @param element_id     A keyword identifier for the element that is unique
                          in the context of the form.

    @option widget        The name of an input widget for the element.  Valid
                          widgets must have a rendering procedure defined in 
                          the <tt>template::widget</tt> namespace.

    @option datatype      The name of a datatype for the element values.  Valid
                          datatypes must have a validation procedure defined in
                          the <tt>template::data::validate</tt> namespace.

    @option label         The label for the form element.
    
    @option html          A list of name-value attribute pairs to include in
                          the HTML tag for widget.  Typically used for additional
                          formatting options, such as <tt>cols</tt> or 
                          <tt>rows</tt>, or for JavaScript handlers.

    @option maxlength     The maximum allowable length in bytes. Will be checked using
                          'string bytelength'. Will also cause 'input' widgets (text, integer, etc.)
                          to get a maxlength="..." attribute.

    @option options       A list of options for select lists and button groups 
                          (check boxes or radio buttons).  The list contains 
                          two-element lists in the form 
                          { {label value} {label value} {label value} ...}

    @option fieldset      A list of name-value attribute pairs to include in 
	                      the HTML tag for checkboxes and radio FIELDSET.

    @option legend        A list of name-value attribute pairs to include in 
	                      the HTML tag for checkboxes and radio LEGEND.

    @option legendtext    A text for the LEGEND tag to include in 
	                      the checkboxes and radio FIELDSET block

    @option value         The default value of the element

    @option values        The default values of the element, where multiple values
                          are allowed (checkbox groups and multiselect widgets)

    @option validate      A list of custom validation blocks in the form
                          { name { expression } { message } \
                            name { expression } { message } ...}
                          where name is a unique identifier for the validation
                          step, expression is a block to Tcl code that evaluates to
                          1 or 0, and message is to be displayed to the user when 
                          the validation step fails, that is, if the expression 
                          evaluates to 0. Use the special variable <tt>$value</tt> 
  			              to refer to the value entered by the user in that field.

    @option sign          specify for a hidden widget that its value should be
                          signed

    @option help_text     Text displayed with the element 

    @option help          Display helpful hints (date widget only?)

    @option optional      A flag indicating that no value is required for this
                          element.  If a default value is specified, the default
                          is used instead.

    @option mode          Valid values are 'display', 'edit', and the empty string.
                          If set to 'display', the element will render as static HTML
                          which doesn't allow editing of the value, instead of the 
                          HTML form element (e.g. &lt;input&gt;) which would otherwise
                          get used. If set to 'edit', the element is as normal, allowing
                          the user to edit the contents. If set to the empty string or
                          not specified at all, the form's 'mode' setting is used instead.

    @option nospell       A flag indicating that no spell-checking should be performed on
                          this element. This overrides the 'SpellcheckFormWidgets' parameter.

    @option before_html   A chunk of HTML displayed immediately before the rendered element.

    @option after_html    A chunk of HTML displayed immediately after the rendered element.

    @option display_value Alternative value used when the element is in display mode.
                          If specified, this value is used when the mode is set to 'display',
                          instead of asking the element widget to render itself in display mode.

    @see template::widget
    @see template::data::validate
    @see template::form::create
    @see template::form::section
} {
  set level [template::adp_level]

  # add the element to the element list
  upvar #$level $form_id:elements elements $form_id:properties form_properties
  if { ! [info exists elements] } {
    error "Form $form_id does not exist"
  }

  lappend elements $form_id:$element_id
  lappend form_properties(element_names) $element_id

  # add the reference to the elements lookup array for the form
  upvar #$level $form_id:$element_id opts

  if {[info exists opts]} {
      error "Element '$element_id' already exists in form '$form_id'."
  }

  set opts(id) $element_id
  set opts(form_id) $form_id

  # ensure minimal defaults for element parameters
  variable defaults
  array set opts $defaults

  # By default, the form/edit mode is set to the empty string
  # Can be set to something else if you want
  set opts(mode) {}

  # set the form section
  set opts(section) $form_properties(section)
  if { $opts(section) ne "" } {
    array set opts {sec_fieldset "" sec_legend "" sec_legendtext ""}
    if {[info exists form_properties(sec_fieldset)]}   {set opts(sec_fieldset)   $form_properties(sec_fieldset)}
    if {[info exists form_properties(sec_legend)]}     {set opts(sec_legend)     $form_properties(sec_legend)}
    if {[info exists form_properties(sec_legendtext)]} {set opts(sec_legendtext) $form_properties(sec_legendtext)}
  }

  template::util::get_opts $args

  # set a name if none specified
  if { ! [info exists opts(name)] } { set opts(name) $opts(id) }

  # set a label if none specified
  if { ! [info exists opts(label)] } { set opts(label) $element_id }

  # If the widget is a submit widget, remember it
  # All submit widgets are optional
  if { $opts(widget) eq "submit" || $opts(widget) eq "button" } {
    set form_properties(has_submit) 1
    set opts(optional) 1
    if { ! [info exists opts(value)] } { set opts(value) $opts(label) }
    if { ! [info exists opts(label)] } { set opts(label) $opts(value) }
  }

  # If the widget is a checkbox or radio widget, set attributes
    if { $opts(widget) eq "radio" || $opts(widget) eq "checkbox" } {

        # If there's no legend text, no point to generate the fieldset
        if { ![info exists opts(legendtext)] } {
            if { [info exists opts(legend)] || [info exists opts(fieldset)] } {
                ns_log Warning "template::element::create (form: $form_id, element: $opts(name)): you set fieldset and/or legend properties but not the legendtext one. You must provide text for the legend tag."
            }
        } else {

            # set fieldset attributes
            if { ![info exists opts(fieldset)] } {
                set opts(fieldset) {}
            }

            array set fs_attributes $opts(fieldset)
            set fs_options ""
            if {![info exists fs_attributes(class)]} {
                append fs_options " class=\"form-fieldset\""
            }
            foreach name [array names fs_attributes] {
                if {$fs_attributes($name) eq ""} {
                    append fs_options " $name"
                } else {
                    append fs_options " $name=\"$fs_attributes($name)\""
                }
            }
            set opts(fieldset) $fs_options

            # set legend attributes
            if { ![info exists opts(legend)] } {
                set opts(legend) ""
            }
            array set lg_attributes $opts(legend)
            set lg_options ""
            foreach name [array names lg_attributes] {
                if {$lg_attributes($name) eq ""} {
                    append lg_options " $name"
                } else {
                    append lg_options " $name=\"$lg_attributes($name)\""
                }
            }
            set opts(legend) $lg_options
        }
    }

  # Remember that the element has not been rendered yet
  set opts(is_rendered) f

  copy_value_to_values_if_defined

  # check for submission
  if { [template::form is_submission $form_id] || [info exists opts(param)] } {
    validate $form_id $element_id
  } elseif { [ns_queryget "__edit"] ne "" } {
    # If the magic __edit button was hit, try to get values from the form still
    # but don't do any validation
    set opts(values) [querygetall opts]

    # be careful not to clobber a default value if one has been specified
    if { [llength $opts(values)] || ! [info exists opts(value)] } {
      set opts(value) [lindex $opts(values) 0]
    }
  } 

  if { $opts(widget) eq "hidden"
       && [info exists opts(sign)] 
       && $opts(sign)
   } { 
      if {[info exists opts(value)] } {
          set val $opts(value)
      } else { 
          set val ""
      }
      template::element::create $opts(form_id) $opts(id):sig \
          -datatype text \
          -widget hidden \
          -section $opts(section) \
          -value [ad_sign $val]
  }
}

ad_proc -public template::element::set_properties { form_id element_id args } {
    Modify properties of an existing element.  The same options may be
    used as with the create command.  Most commonly used to set the
    default value for an element when a form page is initially requested.

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.

    @see template::element::create
} {
  get_reference

  # create a reference to opts as expected by get_opts
  upvar 0 element opts

  template::util::get_opts $args

    if { $opts(widget) eq "hidden"
         && [info exists opts(sign)] 
         && $opts(sign) 
         && [info exists opts(value)] } {
        if { [template::element::exists $form_id $element_id:sig] } {
            template::element::set_properties $form_id $element_id:sig \
                -value [ad_sign $opts(value)]

        } else {
            template::element::create $form_id $element_id:sig \
                -datatype text \
                -widget hidden \
                -value [ad_sign $opts(value)]
        }
    }

  copy_value_to_values_if_defined
}

ad_proc -public template::element::set_value { form_id element_id value } {
    Sets the value of an element

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.
    @param value       The value to apply
} {

  get_reference

  set element(value) $value
  set element(values) [list $value]
}

ad_proc -public template::element::set_values { form_id element_id values } {
    Sets the list of values of an element

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.
    @param values      The list of values to apply
} {

  get_reference

  set element(values) $values
}

ad_proc -public template::element::get_value { form_id element_id } {
    Retrieves the current value of an element.  Typically used following
    a valid form submission to retrieve the submitted value.

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.

    @return The current value of the element.
    @see template::element::get_values
} {
  get_reference

  if { [info exists element(value)] } {
    regsub {<script>} $element(value) {\<\s\c\r\i\p\t\>} element(value)
    return $element(value)
  } else {
    return ""
  }
}

ad_proc -public template::element::get_values { form_id element_id } {
    Retrieves the list current values for an element.  Typically used
    following a valid form submission where multiple values may have
    been submitted for a single element (i.e. for a checkbox group or
					 multiple select box).

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.

    @return A list of current values for the element.
    @see template::element::get_value
} {
  get_reference
  regsub {<script>} $element(values) {\<\s\c\r\i\p\t\>} element(values)
  return $element(values)
}

ad_proc -public template::element::get_property { form_id element_id property } {
    Retrieves the specified property of the element, such as value,
    datatype, widget, etc.

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.
    @param property    The property to be retrieved

    @return The value of the property, or "" if the property does not exist

    @see template::element::set_properties
} {
  get_reference

  if { ![info exists element($property)] } {
    return ""
  } else {
    return $element($property)
  }
}

ad_proc -private template::element::validate { form_id element_id } {
    Validates element values according to 3 criteria: 
    <ol>
    <li>required elements must have a not-null value; 
    <li>values must match the element's declared datatype; 
    <li>values must pass all special validation filters specified with 
        the -validate option when the element was created.  
    </ol>
    <p>
    If validation fails for any reason,
    one or more messages are added to the error list for the form,
    causing the submission to be invalidated and returned to the user
    for correction.

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element.
} {
  set level [template::adp_level]

  # use an array to hold error messages for this form
  upvar #$level $form_id:error formerror $form_id:$element_id element

  # set values [querygetall $element(id) $element(datatype)]
  set values [querygetall element]
  set is_optional [info exists element(optional)]

  # if the element is optional and the value is an empty string, then ignore
  if { $is_optional && [lindex $values 0] eq "" } {
    set values [list]

    # also clobber the value(s) for a submit widget
    if {$element(widget) eq "submit"} {
      if { [info exists element(value)] } { unset element(value) }
      if { [info exists element(values)] } { unset element(values) }
    }
  }

  # if no values were submitted then look for values specified in the
  # declaration (either values or value)
  if { [llength $values] == 0 && [info exists element(values)] } {
    set values $element(values)
  }

  # set a label for use in the template
  set label $element(label)
  if {$label eq ""} {
    set label $element(name)
  }

  # Element shouldn't be validated if it's an inform widget, or the element is not in edit mode.
  # The element will be in edit mode if its mode is either blank or set to 'edit'.
  set is_inform [expr {$element(widget) eq "inform" || ($element(mode) ne "edit" && $element(mode) ne "" )}]

  # Check for required element
  if { ! $is_inform  && ! $is_optional && ![llength $values] } {

    # no value was submitted for a required element
    set formerror($element_id) [_ acs-templating.Element_is_required]
    set formerror($element_id:required) [_ acs-templating.Element_is_required]

    if {$element(widget) in {hidden submit}} {
        ad_log warning "template::element::validate: No value for $element(widget) element $label"
     }
  }

  # Prepare custom validation filters

  if { [info exists element(validate)] } {
    
    set v_length [llength $element(validate)]

    if { $v_length == 2 } {

      # a single anonymous validation check was specified
      set element(validate) [linsert $element(validate) 0 "anonymous"]

    } elseif { $v_length % 3 } {

      error "Invalid number of parameters to validate option: 
             $element(validate) (Length is $v_length)"
    }

  } else {

    set element(validate) [list]
  }

  set v_errors [list]

  foreach value $values {
  
    # something was submitted, now check if it is valid

    if { $is_optional && $value eq "" } {
       # This is an optional field and it's empty... skip validation
       # (else things like the integer test will fail)
       continue
    }

    if { [info exists element(maxlength)] } {
      set value_bytelength [string bytelength $value]
      if {  $value_bytelength > $element(maxlength) } {
        set excess_no_bytes [expr { $value_bytelength - $element(maxlength) }]
      if { $excess_no_bytes == 1 } {
        set message [_ acs-templating.Element_is_too_long_Singular]
      } else {
        set message [_ acs-templating.Element_is_too_long_Plural]
      }
        lappend v_errors $message
        set formerror($element_id:maxlength) $message
      }
    }

    if { ! [template::data::validate $element(datatype) value message] } {

      # the submission is invalid
      lappend v_errors $message
      set formerror($element_id:data) $message

      if { $element(widget) in {hidden submit} } {
          ad_log warning "template::element::validate: Invalid value for $element(widget) element $label: $message"
      }
    }

    foreach { v_name v_code v_message } $element(validate) {

      if { ! [eval $v_code] } {
      
	# value is invalid according to custom validation code
        # Do some expansion on $value, ${value}, $label, and ${label}
	lappend v_errors [string map [list \$value $value \${value} $value \$label $label \${label} $label] $v_message]
	set formerror($element_id:$v_name) [lindex $v_errors end]
      }
    }
  }

  if { [llength $v_errors] } {
    # concatenate all validation errors encountered while looping over values
    set formerror($element_id) [join $v_errors "<br>\n"]
  }

  # make the value be the previously submitted value when returning the form
  set element(values) $values

  # be careful not to clobber a default value if one has been specified
  if { [llength $values] || ! [info exists element(value)] } {
    set element(value) [lindex $values 0]
  }
}

ad_proc -public template::element::set_error { form_id element_id message } {
    Manually set an error message for an element.  This may be used to
    implement validation filters that involve more than one form element
    ("Sorry, blue is not available for the model you selected, please
 choose another color.")

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element with which
                       the error message should be associated in the form
                       template.
    @param message     The text of the error message.
} {
  set level [template::adp_level]

  upvar #$level $form_id:error formerror

  # set the message
  set formerror($element_id) $message
}

ad_proc -public template::element::error_p { form_id element_id } {
    Return true if the named element has an error set.  Helpful for client code
    that wants to avoid overwriting an initial error message.

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element with which
                       the error message should be associated in the form
                       template.
} {
  set level [template::adp_level]

  upvar #$level $form_id:error formerror

  # set the message
  return [info exists formerror($element_id)]
}

ad_proc -public template::element::querygetall { element_ref } {
    Get all values for an element, performing any transformation defined
    for the datatype.
} {
  upvar $element_ref element

  set datatype $element(datatype)

  set transform_proc "::template::data::transform::$datatype"

  if {[info commands $transform_proc] eq ""} {

    set values [ns_querygetall $element(id)]

    # QUIRK: ns_querygetall returns a single-element list {{}} for no values
    if { [string equal $values {{}}] } { set values [list] }

  } else {
    set values [template::data::transform::$datatype element]
  }
    
  # Spell-checker
  array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]

  if { $spellcheck(perform_p) } {
	
    set values [template::data::transform::spellcheck -element_ref element -values $values]
  }

  return $values
}

ad_proc -public template::element::exists { form_id element_id } {
    Determine if an element exists in a specified form

    @param form_id     The identifier of the form containing the element.
    @param element_id  The unique identifier of the element within the form.

    @return 1 if the element exists in the form, or 0 otherwise
} {
  set level [template::adp_level]

  upvar #$level $form_id:$element_id element_properties

  return [info exists element_properties]
}

ad_proc -private template::element::get_reference {} {
    Gets a reference to the array containing the properties of an
    element, and throws and error if the element does not exist.  Called
    at the beginning of several of the element commands.
} {
  uplevel {

    set level [template::adp_level]
    upvar #$level $form_id:$element_id element

    if { ! [array exists element] } {
      error "Element \"$element_id\" does not exist in form \"$form_id\""
    }
  }
}

ad_proc -private template::element::render { form_id element_id tag_attributes } {
    Generate the HTML for a particular form widget.

    @param form_id        The identifier of the form containing the element.
    @param element_id     The unique identifier of the element within the form.
    @param tag_attributes A name-value list of addditional HTML
                          attributes to include in the tag, such as JavaScript
                          handlers or special formatting (i.e. ROWS and COLS
							  for a TEXTAREA).

    @return A string containing the HTML for an INPUT, SELECT or TEXTAREA
    form element.
} {
  get_reference

  # Remember that the element has been rendered already
  set element(is_rendered) t

  if { $element(mode) ne "edit" && [info exists element(display_value)] && $element(widget) ne "hidden" } {
    return "$element(before_html) $element(display_value) $element(after_html)"  
  } else {
    return "[string trim "$element(before_html) [template::widget::$element(widget) element $tag_attributes] $element(after_html)"]"
  }
}

ad_proc -private template::element::render_help { form_id element_id tag_attributes } {
    Render the -help_text text

    @param form_id        The identifier of the form containing the element.
    @param element_id     The unique identifier of the element within the form.
    @param tag_attributes Reserved for future use.
} {
  get_reference

  return $element(help_text)
}

ad_proc -private template::element::options { form_id element_id tag_attributes } {
    Prepares a multirow data source for use within a formgroup

    @param form_id        The identifier of the form containing the element.
    @param element_id     The unique identifier of the element within the form.
    @param tag_attributes A name-value list of addditional HTML
                          attributes to include in the INPUT tags for each
                          radio button or checkbox, such as JavaScript
                          handlers or special formatting.
} {
  get_reference

  if { ! [info exists element(options)] } {
    error "No options specified for element $element_id in form $form_id"
  }

  # Remember that the element has been rendered already
  set element(is_rendered) t

  # render the widget once with a placeholder for value
  set element(value) "\$value"
  lappend tag_attributes "\$checked" ""
  set widget "$element(before_html) [template::widget::$element(widget) element $tag_attributes] $element(after_html)"

  set options $element(options)
  if { [info exists element(values)] } {
    template::util::list_to_lookup $element(values) values 
  }

  # the data source is named formgroup by convention

  upvar #$level formgroup:rowcount rowcount
  set rowcount [llength $options]

  # Create a widget entry for each checkbox in the group
  for { set i 1 } { $i <= $rowcount } { incr i } {

    upvar #$level formgroup:$i formgroup
    
    set option [lindex $options $i-1]
    set value [lindex $option 1]

    if { ![info exists values($value)] } {
      set checked ""
    } else {
      set checked "checked=\"checked\""
    }

    set formgroup(label)   [lindex $option 0]
    set formgroup(widget)  [subst $widget]
    set formgroup(rownum)  $i
    set formgroup(checked) $checked
    set formgroup(option)  $value
  }
}

ad_proc -private template::element::copy_value_to_values_if_defined {} {
    define values from value, if the latter is more defined
} {
  upvar opts opts
  # opts(values) is always defined, init to "" from template::element::defaults
  if { [info exists opts(value)] && [llength $opts(values)] == 0 } {
      #
      # GN: the following test is broken, since "opts(value)" is never
      # empty; ... but changing this to a comparison with $opts(value)
      # breaks eg ad_form.
      #
    if { [string equal opts(value) {}] } {
      set opts(values) [list]
    } else {
      set opts(values) [list $opts(value)]
    }
  }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
