# Form management for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Commands for managing dynamic templated forms.

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
    @see template::form::exists
    @see template::form::export
    @see template::form::get_combined_values
    @see template::form::get_values
    @see template::form::is_request
    @see template::form::is_submission
    @see template::form::is_valid
    @see template::form::section
    @see template::form::set_values
    @see template::form::size
    @see template::element
} {
  eval template::form::$command $args
}

ad_proc -public template::form::create { id args } {
    Initialize the data structures for a form.

    @param id A keyword identifier for the form, such as "add_user" or
              "edit_item".  The ID must be unique in the context of a 
              single page.

    @option method The standard METHOD attribute to specify in the HTML FORM
                   tag at the beginning of the rendered form. Defaults to POST.

    @option html A list of additional name-value attribute pairs to
                 include in the HTML FORM tag at the beginning of the 
                 rendered form. Common attributes include JavaScript 
                 event handlers and multipart form encoding.  For example, 
                 "-html { enctype multipart/form-data onSubmit validate() }"

    @option elements A block of element specifications.
} {
  set level [template::adp_level]

  # keep form properties and a list of the element items
  upvar #$level $id:elements elements $id:properties opts

  # ensure minimal defaults for form properties
  variable defaults
  array set opts $defaults

  template::util::get_opts $args

  set elements [list]

  # check whether this form is being submitted
  upvar #$level $id:submission submission

  if { [string equal $id request] } {

    # request is the magic ID for the form holding query parameters
    set submission 1

  } else {

    set submission [string equal $id [ns_queryget form:id]]
  }

  # add elements specified at the time the form is created
  if { [info exists opts(elements)] } {

    # strip carriage returns
    regsub -all {\r} $opts(elements) {} element_data

    foreach element [split $element_data "\n"] {

      set element [string trim $element]
      if { [string equal $element {}] } { continue }

      eval template::element create $id $element
    }
  }
}
 
ad_proc -public template::form::exists { id } {
    Determine whether a form exists by checking for its data structures.

    @param id  The ID of an ATS form object.

    @return 1 if a form with the specified ID exists. 0 if it does not.
} {
  set level [template::adp_level]
  upvar #$level $id:elements elements 

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

  set elements:rowcount 0

  foreach element_ref $elements {

    incr elements:rowcount

    # get a reference by index for the multirow data source
    upvar #$level $element_ref elements:${elements:rowcount} 
    set "elements:${elements:rowcount}(rownum)" ${elements:rowcount}
  }
    
  if { [string equal $style {}] } { set style standard }
  set file_stub [template::get_resource_path]/forms/$style

  # set the asset url for images
  set assets "[template::get_resource_path]/assets"
  # assume resources are under page root (not safe)
  regsub "^[ns_info pageroot]" $assets {} assets

  # ensure that the style template has been compiled and is up-to-date
  template::adp_init adp $file_stub

  # get result of template output procedure into __adp_output
  # the only data source on which this template depends is the "elements"
  # multirow data source.  The output of this procedure will be
  # placed in __adp_output in this stack frame.

  template::code::adp::$file_stub

  # unprotect registered tags and variable references
  set __adp_output [string map { ~ < + @ } $__adp_output]

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
  upvar #$level $id:elements $id:elements formerror formerror 
  upvar #$level $id:properties form_properties

  foreach element_ref [set $id:elements] { 

    # get a reference by element ID for formwidget and formgroup tags
    upvar #$level $element_ref $element_ref
  }

  # evaluate the code and return the rendered HTML for the form
  return [template::adp_eval code]
}

ad_proc -public template::form::section { id section } {
    Set the name of the current section of the form.  A form may be
    divided into any number of sections for layout purposes.  Elements
    are tagged with the current section name as they are added to the
    form.  A form style template may insert a divider in the form
    whenever the section name changes.

    @param id      The form identifier.
    @param section The name of the current section.
} {
  get_reference

  set properties(section) $section
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

  # make a reference to the formerror array with any validation messages
  upvar #$level $id:error $id:error

  if { [info exists $id:error] } {

    uplevel #$level "upvar 0 $id:error formerror"

  } else {

    # no errors on this form.  Clear the formerror array if it has
    # been set by another form on the same page
    upvar #$level formerror formerror
    if { [info exists formerror] } { unset formerror }
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
  
  set output "<form name=\"$id\" method=\"$properties(method)\" 
                    action=\"$properties(action)\""

  # append attributes to form tag
  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">"

  append output "<input type=\"hidden\" name=\"form:id\" value=\"$id\" />"

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
    if { [string equal $element(is_rendered) f] } {

      # If the element is hidden, render it
      if { [string equal $element(widget) hidden] } {

        append output [template::element render $id $element(id) {} ]
        append output "\n"
        set element(is_rendered) t

      } else {

        ns_log notice "MISSING FORMWIDGET: $id\:$element_ref"
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
  return [expr ! [is_submission $id]]
}

ad_proc -public template::form::is_submission { id } {
    Return true if a submission in progress.  The submission may or may not
    be valid.

    @param id               The form identifier

    @return 1 if true or 0 if false
} {
  set level [template::adp_level]

  upvar #$level $id:submission submission

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
  set level [template::adp_level]

  upvar #$level $id:submission submission

  if { ! $submission } { 
    return 0 
  }

  upvar #$level $id:error formerror

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

    @param id            The form identifier
    @param args          A list of element identifiers. If the list is empty,
                         retrieve all form elements
} {
  if { [llength $args] > 0 } {
    set elements $args
  } else {
    # Get all the form elements 
    set level [template::adp_level]
    upvar #$level $id:properties properties
    set elements $properties(element_names)
  }

  foreach element_id $elements {
    upvar 2 $element_id value
    set value [template::element get_value $id $element_id]
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

    @param id               The form identifier
    @param array_ref        The name of a local array variable whose
                            keys correspond to element identifiers in the form
} {
  upvar 2 $array_ref values
  
  foreach name [array names values] {
    
    template::element set_properties $id $name -value $values($name) 
    # Resolve single value  / multiple value issues ?
    template::element set_properties $id $name -values [list $values($name)]
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
  if { $form == "" } { return "" }

  set export_data ""

  for { set i 0 } { $i < [ns_set size $form] } { incr i } {
    
    set key [ns_set key $form $i]
    set value [ns_set value $form $i]

    append export_data "
      <input type=\"hidden\" name=\"$key\" 
             value=\"[template::util::quote_html $value]\" />"
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

    upvar #$level $id:elements elements $id:properties properties 
    upvar #$level $id:properties form_properties

    if { ! [info exists elements] } {
      error "Form $id does not exist"
    }
  }
}
