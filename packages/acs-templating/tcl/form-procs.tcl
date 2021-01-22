ad_library {
    Form management for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
    @author Stanislav Freidin (sfreidin@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


# Commands for managing dynamic templated forms.
namespace eval template {}
namespace eval template::form {}

ad_proc -public form {command args} { 
    form is really template::form although when in 
    the "template" namespace you may omit the
    template::

    @see template::form
    @see template::element
} -

ad_proc -public template::form { command args } {

    template::form command invokes form functions.  Please see the
    individual functions for their arguments.  The template::element
    api is used to manipulate form elements.
    
    @see template::form::create
    @see template::form::get_button
    @see template::form::get_action
    @see template::form::set_properties
    @see template::form::get_properties
    @see template::form::exists
    @see template::form::export
    @see template::form::get_combined_values
    @see template::form::get_values
    @see template::form::get_elements
    @see template::form::get_errors
    @see template::form::set_error
    @see template::form::is_request
    @see template::form::is_submission
    @see template::form::is_valid
    @see template::form::section
    @see template::form::set_values
    @see template::form::size
    @see template::element
} {
  template::form::$command {*}$args
}

ad_proc -public template::form::create { id args } {
    Initialize the data structures for a form.

    @param id               A keyword identifier for the form, such as "add_user" or
                            "edit_item".  The ID must be unique in the context of a 
                            single page.

    @option method          The standard METHOD attribute to specify in the HTML FORM
                            tag at the beginning of the rendered form. Defaults to POST.

    @option html            A list of additional name-value attribute pairs to
                            include in the HTML FORM tag at the beginning of the 
                            rendered form. Common use for this option is to set multipart
                            form encoding by specifying "-html { enctype multipart/form-data }".
                            Please note that to comply with newer security features, such as CSP,
                            one should not specify javascript event handlers here, as they will
                            be rendered inline.
    
    @option mode            If set to 'display', the form is shown in display-only mode, where 
                            the user cannot edit the fields. Each widget knows how to display its contents
                            appropriately, e.g. a select widget will show the label, not the value. If set to
                            'edit', the form is displayed as normal, for editing. Defaults to 'edit'. Switching
                            to edit mode when a button is clicked in display mode is handled automatically.
    
    @option cancel_url      A url to redirect to when the user hits the Cancel button. 
                            If you do not supply a cancel_url, there will be no Cancel button.
    
    @option cancel_label    The label of the Cancel button, if cancel_url is supplied.
                            Default is "Cancel".
    
    @option actions         A list of actions available on the form, which in practice means 
                            a list of buttons to show when the form is in display mode. 
                            The value should be a list of lists, with the first element being the form label
                            and the second element being the name of the name of the form element. Defaults to
                            { { "Edit" edit } }. The name of the button clicked can be retrieved using 
                            template::form::get_button. The name of the button clicked while in display mode
                            is called the 'action', and can be retrieved using template::form::get_action. 
                            The action is automatically carried forward to the form submission, so that the value
                            that you get from calling template::form::get_action on the final form submission
                            is the name of the button which was called when the form changed from display 
                            mode to edit mode.

    @option display_buttons List of buttons to show when the form is in display mode. 
                            Equivalent to actions. If both actions and display_buttons are present, 
                            'actions' is used. 'display_buttons' is deprecated.


    @option edit_buttons    List of buttons to show when the form is in edit mode. 
                            The value should be a list of lists, with the first element being the button label
                            and the second element being the name. Defaults to
                            { { "Ok" ok } }. The name of the button clicked can be retrieved using 
                            template::form::get_button. 
    
    @option has_submit      Set to 1 to suppress the OK or submit button automatically
                            added by the form builder. Use this if your form already includes its own 
                            submit button.

    @option has_edit        Set to 1 to suppress the Edit button automatically added by the
                            form builder. Use this if you include your own.

    @option elements        A block of element specifications.

    @option show_required_p Should the form template show which elements are required. 
                            Use 1 or t for true, 0 or f for false. Defaults to true.

    @see template::form::get_button
    @see template::form::get_action

} {
  set level [template::adp_level]

  # bump the form_count for widgets that use javascript to navigate through
  # the form (liberated from my Greenpeace work ages ago)

  incr ::ad_conn(form_count)

  # keep form properties and a list of the element items
  upvar #$level $id:elements elements $id:properties opts

  # ensure minimal defaults for form properties
  variable defaults
  array set opts $defaults

  template::util::get_opts $args

  set elements [list]

  # check whether this form is being submitted
  upvar #$level $id:submission submission

  if {$id eq "request"} {
    # request is the magic ID for the form holding query parameters
    set submission 1
  } else {
    # If there's a form:id argument, and it's the ID of this form,
    # we're being submitted
    set submission [string equal $id [ns_queryget form:id]]
  }

  set formbutton [get_button $id]

  # If the user hit a button named "cancel", redirect and about
  if { $submission && $formbutton eq "cancel" && [info exists opts(cancel_url)] && $opts(cancel_url) ne ""} {
      ad_returnredirect $opts(cancel_url)
      ad_script_abort
  }

  set formaction [get_action $id]
  # If we were in display mode, and a button was clicked, we should be in edit mode now
  if { $submission && [ns_queryget "form:mode"] eq "display" } {
    set opts(mode) "edit"
    set submission 0
  }

  # add elements specified at the time the form is created
  if { [info exists opts(elements)] } {

    # strip carriage returns
    regsub -all {\r} $opts(elements) {} element_data

    foreach element [split $element_data "\n"] {
      set element [string trim $element]
      if {$element eq {}} { continue }
      template::element create $id {*}$element
    }
  }
}
 
ad_proc -public template::form::set_properties { id args } {
    Set properties for a form

    @param id  The ID of an ATS form object.
    @param args Properties to set 
} {
  # form properties 
  upvar #[template::adp_level] $id:properties opts

  template::util::get_opts $args
}

ad_proc -public template::form::get_properties { id } {
    Get properties of a form

    @param id  The ID of a form
} {
    # form properties 
    upvar #[template::adp_level] $id:properties formprop

    if { [info exists formprop] } {
        # properties exist in the form, return them
        return [array get formprop]
    } else {
        # no props exist in the form, return the empty list
        return [list]
    }
}

ad_proc -public template::form::get_button { id } {
    Find out which button was clicked

    @param id  The ID of an ATS form object.
    @return the name of the button clicked
} {
  # keep form properties and a list of the element items
  upvar #[template::adp_level] $id:button formbutton
    
  # If we've already found the button, just return that
  if { [info exists formbutton] } {
    return $formbutton
  }

  # Otherwise, find out now

  set formbutton {}

  # If the form isn't being submitted at all, no button was clicked
  if { $id ne [ns_queryget form:id] } {
    return {}
  }

  # Search the submit form for the button
  set form [ns_getform]

  if { $form ne "" } {
      set size [ns_set size $form]
      for { set i 0 } { $i < $size } { incr i } {
          if { [string match "formbutton:*" [ns_set key $form $i]] } {
              set formbutton [string range [ns_set key $form $i] [string length "formbutton:"] end]
              break
          }
      }
  }

  return $formbutton
}

ad_proc -public template::form::get_action { id } {
    Find out which action is in progress. This is the name of the button
    which was clicked when the form was in display mode.

    @param id  The ID of an ATS form object.
    @return the name of the action in progress
} {
  # keep form properties and a list of the element items
  upvar #[template::adp_level] $id:formaction formaction
    
  # If we've already found the action, just return that
  if { [info exists formaction] } {
    return $formaction
  }

  # Otherwise, find out now

  set formaction {}

  # If the form isn't being submitted at all, there's no action
  if { $id ne [ns_queryget "form:id"] } {
    return {}
  }

  set formbutton [get_button $id]

  # If we were in display mode, and a button was clicked, we should be in edit mode now
  if { [ns_queryget "form:mode"] eq "display" && $formbutton ne "" } {
    set formaction $formbutton
    return $formaction
  }

  # Otherwise, there should be a form:formaction variable in the form
  set formaction [ns_queryget "form:formaction"]

  return $formaction
}

ad_proc -public template::form::exists { id } {
    Determine whether a form exists by checking for its data structures.

    @param id  The ID of an ATS form object.

    @return 1 if a form with the specified ID exists. 0 if it does not.
} {
  upvar #[template::adp_level] $id:elements elements 

  return [info exists elements]
}

ad_proc -private template::form::template { id { style "" } } {
    Auto-generate the template for a form

    @param id      The form identifier
    @param style   The style template to use when generating the form.
                   Form style templates must be placed in the forms
                   subdirectory of the ATS resources directory.

    @return A string containing a template for the body of the form.
} {

  get_reference 

  #
  # Elements
  # RAL: moved this below so we could take advantage of the template::element
  # API in the button loop above.  The buttons multirow in standard.adp is
  # no longer necessary.
  #
  set elements:rowcount 0

  foreach element_ref $elements {

    incr elements:rowcount

    # get a reference by index for the multirow data source
    upvar #$level $element_ref elements:${elements:rowcount} 
    set "elements:${elements:rowcount}(rownum)" ${elements:rowcount}
  }

  if {$style eq {}} { 
      set style [parameter::get \
                     -package_id [ad_conn subsite_id] \
                     -parameter DefaultFormStyle \
                     -default [parameter::get \
                                   -package_id [apm_package_id_from_key "acs-templating"] \
                                   -parameter DefaultFormStyle \
                                   -default "standard-lars"]]
  }

  set file_stub [template::resource_path -type forms -style $style]

  if { ![file exists "$file_stub.adp"] } {
      # We always have a template named 'standard'
      set file_stub [template::resource_path -type forms -style standard]
  }

  # the following block seems useless, deactivated for the time being
  if {0} {
      # set the asset url for images
      set assets "[template::get_resource_path]/assets"
      # assume resources are under page root (not safe)
      regsub "^$::acs::pageroot" $assets {} assets
  }

  # ensure that the style template has been compiled and is up-to-date
  template::adp_init adp $file_stub

  # get result of template output procedure into __adp_output
  # the only data source on which this template depends is the "elements"
  # multirow data source.  The output of this procedure will be
  # placed in __adp_output in this stack frame.

  template::code::adp::$file_stub

  return $__adp_output
}

ad_proc -private template::form::generate { id { style "" } } {
    Render the finished HTML output for a dynamic form.

    @param id      The form identifier
    @param style   The style template to use when generating the form.
                   Form style templates must be placed in the forms
                   subdirectory of the ATS resources directory.

    @return A string containing the HTML for the body of the form.
} {
  set __adp_output [template $id $style]
  
  set level [template::adp_level]

  # compile the template
  set code [template::adp_compile -string $__adp_output]

  # these variables are expected by the formwidget and formgroup tags
  set form:id $id
  upvar #$level $id:elements $id:elements formerror formerror $id:properties form_properties

  foreach element_ref [set $id:elements] { 
    # get a reference by element ID for formwidget and formgroup tags
    upvar #$level $element_ref $element_ref
  }

  # evaluate the code and return the rendered HTML for the form
  return [template::adp_eval code]
}

ad_proc -public template::form::section { 
	{-fieldset ""}
	{-legendtext ""}
	{-legend ""}
	id 
	section 
} {
    Set the current section (fieldset) of the form. A form may be
    divided into any number of fieldsets to group related
    elements. Elements are tagged with the current fieldset properties
    as they are added to the form. A form style template may insert a
    divider in the form whenever the fieldset identifier changes.

    @param id          The form identifier.
    @param section     The current fieldset identifier
    @param fieldset    A list of name-value attribute pairs for the FIELDSET tag
    @param legendtext  The legend text
    @param legend      A list of name-value attribute pairs for the LEGEND tag
} {
    get_reference

    # legend can't be empty
    if { $section ne "" && $legendtext eq "" } {
        ad_log Warning "template::form::section (form: $id, section: $section): The legend-text of this section is empty. You must provide text for the legend-text otherwise the section fieldset won't be created."
        return
    }

    set properties(section) $section
    set properties(sec_legendtext) $legendtext

    # fieldset attributes
    set properties(sec_fieldset) ""
    array set fs_attributes $fieldset
    foreach name [array names fs_attributes] {
	if {$fs_attributes($name) eq ""} {
	    append properties(sec_fieldset) " $name"
	} else {
	    append properties(sec_fieldset) " $name=\"$fs_attributes($name)\""
	}
    }

    # legend attributes
    set properties(sec_legend) ""
    if { $legendtext ne "" } {
	array set lg_attributes $legend
        if {![info exists lg_attributes(class)]} {
            append properties(sec_legend) " class=\"form-legend\""
        }
	foreach name [array names lg_attributes] {
	    if {$lg_attributes($name) eq ""} {
		append properties(sec_legend) " $name"
	    } else {
		append properties(sec_legend) " $name=\"$lg_attributes($name)\""
	    }
	}
    }
}

ad_proc -private template::form::render { id tag_attributes } {
    Render the HTML FORM tag along with a hidden element that identifies
    the form object.

    @param id               The form identifier
    @param tag_attributes   A name-value list of special attributes to add
                            to the FORM tag, such as JavaScript event handlers.

    @return A string containing the rendered tags.
} {
  get_reference

  #----------------------------------------------------------------------
  # Check for errors on form
  #----------------------------------------------------------------------

  # make a reference to the formerror array with any validation messages
  upvar #$level $id:error $id:error

  # Clear the formerror array if it has
  # been set by another form on the same page
  upvar #$level formerror formerror
  if { [info exists formerror] } { unset formerror }

  if { [info exists $id:error] } {

      uplevel #$level "upvar 0 $id:error formerror"
    
      # There were errors on the form, force edit mode
      set properties(mode) edit
  }

  #----------------------------------------------------------------------
  # Buttons
  #----------------------------------------------------------------------

  if { [info exists form_properties(cancel_url)] && $form_properties(cancel_url) ne ""} {
    if {![info exists form_properties(cancel_label)] || $form_properties(cancel_label) eq ""} {
      set form_properties(cancel_label) [_ acs-kernel.common_Cancel]
    }
    lappend form_properties(edit_buttons) [list $form_properties(cancel_label) cancel]
  }

  if { [info exists form_properties(has_submit)] 
       && [template::util::is_true $form_properties(has_submit)] 
     } {
    set form_properties(edit_buttons) {}
  }
  
  if { [info exists form_properties(has_edit)] 
       && [template::util::is_true $form_properties(has_edit)] 
     } {
    set form_properties(display_buttons) {}
  }

  if { [info exists form_properties(actions)] 
       && $form_properties(actions) ne "" 
     } {
    set form_properties(display_buttons) $form_properties(actions)
  }
    
  # We keep this, so if anyone has an old form template that still loops over this multirow, it won't break hard
  # We should remove this later, maybe 6.0
  set buttons:rowcount 0

  foreach button $form_properties(${form_properties(mode)}_buttons) {
    lassign $button label name

    if {$name eq "ok"} {
      # We hard-code the OK button to be wider than it otherwise would
      set label "       $label       "
    }
    set name "formbutton:$name"
    
    template::element create $id $name -widget submit -label $label -datatype text
  }

  # Propagate form mode to all form elements
  foreach element_ref $elements { 
 
    # get a reference by element ID 
    upvar #$level $element_ref element
   
    # Check if the element has an empty string mode, and in 
    # that case, set to form mode
    if {$element(mode) eq ""} {
      set element(mode) $properties(mode)
    }
  }

  # Check for errors in hidden elements
  foreach element_ref $elements { 
    
    # get a reference by element ID 
    upvar #$level $element_ref element
   
    if { $element(widget) eq "hidden" && 
	 [info exists $id:error($element(id))] && [set $id:error($element(id))] ne "" 
       } {
      # Submitting invalid data to hidden elements is a common attack vector.  
      # This does not give them much information in the response.
      ad_return_complaint 1 "Your request is invalid."
      ad_log Warning "Validation error in hidden form element.\
	This may be part of a vulnerability scan or attack reconnaissance: \
	'[set $id:error($element(id))]' on element '$element(id)'."
      ad_script_abort
    }
  }

  # get any additional attributes developer specified to include in form tag
  if { [info exists properties(html)] } {
    array set attributes $properties(html)
  }

  # add on or replace with attributes specified by designer in formtemplate tag
  array set attributes $tag_attributes

  # set the form to point back to itself if action is not specified
  if { ! [info exists properties(action)] } {
    set properties(action) [ns_conn url]
  }
  
  set output "<form id=\"$id\" name=\"$id\" method=\"$properties(method)\" 
                    action=\"$properties(action)\""

  ### 2/17/2007
  ### Adding a default class for forms if one does not exist 
  if {![info exists attributes(class)]} {
      append output " class=\"margin-form\""
  }

  # make sure, that event handlers have IDs
  foreach name [array names attributes] {
      if {[regexp -nocase {^on(.*)%} $name . event]} {
          if {![info exists attributes(id)]} {
              set attributes(id) "id[clock clicks -microseconds]"
          }
      }
  }
    
  # append attributes to form tag
  foreach name [array names attributes] {
    if {[regexp -nocase {^on(.*)%} $name . event]} {
        #
        # Convert automatically on$event attribute into event listener
        #
        ns_log notice "automatically adding event listener for attribute $name in form with id $id"
        template::add_event_listener \
            -event $event
            -id $attributes(id) \
            -script $attributes($name)
    } elseif {$attributes($name) eq {}} {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">"

  ### 2/11/2007
  ### Adding Form Fieldset legend and attributes
  if { [info exists properties(fieldset)] } {
    # Fieldset
    append output " <fieldset"
    array set fs_attributes [lindex $properties(fieldset) 0]
    if {![info exists fs_attributes(class)]} {
      append output " class=\"form-fieldset\""
    }
    foreach name [array names fs_attributes] {
      if {$fs_attributes($name) eq {}} {
	append output " $name"
      } else {
	append output " $name=\"$fs_attributes($name)\""
      }
    }
    append output ">"

    # Legend
    set fieldset_legend [lindex $properties(fieldset) 1]
    append output "<legend>$fieldset_legend</legend>"
  }

  # Export form ID and current form mode
  append output [export_vars -form { { form\:id $id } { form\:mode $properties(mode) } }]
  
  # If we're in edit mode, output the action
  upvar #$level $id:formaction formaction
  if { $properties(mode) eq "edit" && ([info exists formaction] && $formaction ne "") } {
    upvar #$level $id:formaction action
    append output [export_vars -form { { form\:formaction $formaction } }]
  }

  return $output
}

ad_proc -private template::form::check_elements { id } {
    Iterates over all declared elements, checking for hidden widgets and
    rendering those that have not been rendered yet.  Called after rendering
    a custom form template as a debugging aid.

    @param id               The form identifier
} {
  get_reference

  set output ""

  foreach element_ref $elements { 
 
    # get a reference by element ID 
    upvar #$level $element_ref element
   
    # Check if the element has been rendered already
    if {$element(is_rendered) == "f"} {

      # If the element is hidden, render it
      if {$element(widget) eq "hidden"} {

        append output "<div>[template::element render $id $element(id) {} ]</div>\n"
        set element(is_rendered) t

      } else {

        ad_log Warning "template::form::check_elements: MISSING FORMWIDGET: $id\:$element_ref"
        # Throw an error ?
      }
    }
  }
 
  return $output
}

ad_proc -public template::form::is_request { id } {
    Return true if preparing a form for an initial request (as opposed
    to repreparing a form that is returned to the user due to validation
    problems).  This command is used to conditionally set default values 
    for form elements.

    @param id               The form identifier

    @return 1 if preparing a form for an initial request; or 0 if 
            repreparing a form that is returned to the user due to 
            validation problems
} {
  return [expr {! [is_submission $id]}] 
}

ad_proc -public template::form::is_submission { id } {
    Return true if a submission in progress.  The submission may or may not
    be valid.

    @param id               The form identifier

    @return 1 if true or 0 if false
} {
  upvar #[template::adp_level] $id:submission submission

  return $submission
}

ad_proc -public template::form::is_valid { id } {
    Return true if submission in progress and submission was valid.
    Typically used to conditionally execute DML and redirect to the next
    page, as opposed to returning the form back to the user to report
    validation errors.

    @param id               The form identifier

    @return 1 if id is the form identifier of a valid submission or 0 otherwise
} {
  upvar #[template::adp_level] $id:submission submission $id:error formerror

  if { ! $submission } { 
    return 0 
  }

  if { [info exists formerror] } {
    # errors exist in the form so it is not valid
    return 0 
  } else {
    # no errors exist in the form, submission approved
    return 1
  }
}

ad_proc -public template::form::get_values { id args } {
    Set local variables for form variables (assume they are all single values).
    Typically used when processing the form submission to prepare for DML
    or other type of transaction.

    NB! This proc must always be called through "form get_values" 
    or "template::form get_values", or it won't be able to find 
    the variable.


    @param id            The form identifier
    @param args          A list of element identifiers. If the list is empty,
                         retrieve all form elements
} {
  if { [llength $args] > 0 } {
    set elements $args
  } else {
    # Get all the form elements 
    set elements [get_elements $id]
  }

  foreach element_id $elements {
    upvar 2 $element_id value
    set value [template::element get_value $id $element_id]
  }
}

ad_proc -public template::form::get_elements { 
    {-no_api:boolean}
    id 
} {
    Return a list of element names for the form with given id.

    @param no_api If provided, filter out form builder and ad_form API element names
                     that start with the double underscore

    @author Peter Marklund
} {
    upvar #[template::adp_level] $id:properties properties
    set elements $properties(element_names)

    if { $no_api_p } {
        set elements_no_api [list]
        foreach element $elements {
            if { ![regexp {^__} $element] } {
                lappend elements_no_api $element
            }
        }

        return $elements_no_api
    } else {
        return $elements
    }
}


ad_proc -public template::form::get_errors { id } {
    @param id               The form identifier
    @return the list of form errors
} {
  upvar #[template::adp_level] $id:error formerror

  if { [info exists formerror] } {
    # errors exist in the form, return them
    return [array get formerror]
  } else {
    # no errors exist in the form, return the empty list
    return [list]
  }
}

ad_proc -public template::form::get_combined_values { id args } {
    Return a list which represents the result of getting combined values
    from multiple form elements

    @param id             The form identifier
    @param args           A list of element identifiers. Each identifier may be
                          a regexp. For example, 
                          <code>form get_combined_values "foo.*"</code>
                          will combine the values of all elements starting with
                          "foo"

    @return               The combined list of values
} {
  get_reference 

  set exp [join $args "|"]
  set values [list]

  foreach element_name $properties(element_names) {
    if { [regexp $exp $element_name match] } {
      set values [concat $values \
        [template::element get_values $id $element_name]]
    }
  }

  return $values
}

ad_proc -public template::form::set_values { id array_ref } {
    Convenience procedure to set individual values of a form (useful for
    simple update forms).  Typical usage is to query a onerow data
    source from database and pass the resulting array reference to
    set_values for setting default values in an update form.

    NB! This proc must always be called through "form set_values" 
    or "template::form set_values", or it won't be able to find 
    the variable.

    @param id               The form identifier
    @param array_ref        The name of a local array variable whose
                            keys correspond to element identifiers in the form
} {
  upvar 2 $array_ref values
  
  foreach name [array names values] {
    
    template::element set_value $id $name $values($name) 
  }
}

ad_proc -public template::form::export {} {
    Generates hidden input tags for all values in a form submission.
    Typically used to create a confirmation page following an initial
    submission.

    @return A string containing hidden input tags for inclusion in a
            form.
} {
  set form [ns_getform]
  if { $form eq "" } { return "" }

  set export_data ""

  for { set i 0 } { $i < [ns_set size $form] } { incr i } {
    
    set key [ns_set key $form $i]
    set value [ns_set value $form $i]

    append export_data "
      <div><input type=\"hidden\" name=\"$key\" value=\"[ns_quotehtml $value]\"></div>"
  }

  return $export_data
}

ad_proc -public template::form::size { id } {
    @param id               The form identifier
    @return the number of elements in the form identified by id
} {
  template::form::get_reference
  return [llength $elements]
}

ad_proc -private template::form::get_reference {} {
    Helper procedure used to access the basic data structures of a form object.
    Called by several of the form commands.
} {
  uplevel {
    set level [template::adp_level]
    
    # GN: why does it alias "$id:properties" to "properties" and
    # "form_properties"?
    upvar #$level $id:elements elements $id:properties properties $id:properties form_properties

    if { ! [info exists elements] } {
      error "Form $id does not exist"
    }
  }
}

ad_proc -public template::form::set_error {
    id
    element
    error
} {

    Set an error on a form element. Can be called from the -on_submit or 
    -after_submit block of an ad_form. Will cause the form to no longer 
    be considered valid, and thus the form will be redisplayed with the 
    error message embedded, provided that 'break' is also called, so any 
    code that redirects away from the form (e.g. in the after_submit block)
    isn't called either.

    @param id      The ID of the form

    @param element The element that contains the error.

    @param error   The error message.
} {
    # use an array to hold error messages for this form
    upvar #[template::adp_level] $id:error formerror
    
    set formerror($element) $error
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
