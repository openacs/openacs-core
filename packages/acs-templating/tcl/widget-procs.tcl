# Form widgets for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)
     
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html
ad_proc -public template::widget {} {
    The template::widget namespace contains the code 
    for the various input widgets.

    @see template::widget::ampmFragment
    @see template::widget::button
    @see template::widget::checkbox
    @see template::widget::comment
    @see template::widget::currency
    @see template::widget::date
    @see template::widget::dateFragment
    @see template::widget::file
    @see template::widget::hidden
    @see template::widget::inform
    @see template::widget::input
    @see template::widget::menu
    @see template::widget::monthFragment
    @see template::widget::multiselect
    @see template::widget::numericRange
    @see template::widget::password
    @see template::widget::radio
    @see template::widget::search
    @see template::widget::select
    @see template::widget::submit
    @see template::widget::text
    @see template::widget::textarea

    @see template::element::create
} -


ad_proc -public template::widget::search { element_reference tag_attributes } {

  upvar $element_reference element

  if { ! [info exists element(options)] } {
    
    # initial submission or no data (no options): a text box
    set output [input text element $tag_attributes]

  } else {

    # options provided so use a select list
    # include an extra hidden element to indicate that the 
    # value is being selected as opposed to entered

    set output "<input type=\"hidden\" name=\"$element(id):select\" value=\"t\" />"
    append output [select element $tag_attributes]

  }


  return $output
}

ad_proc -public template::widget::textarea { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output "<textarea name=\"$element(name)\""

  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">"

  if { [info exists element(value)] } {
    # As per scottwseago's request
    append output [ad_quotehtml $element(value)]
  } 

  append output "</textarea>"

  return $output
}

ad_proc -public template::widget::inform { element_reference tag_attributes } {
    A static information widget that does not submit any data
} {

  upvar $element_reference element

  if { [info exists element(value)] } {
    return $element(value)
  } else {
    return ""
  }
}

ad_proc -public template::widget::input { type element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  if { ( [string equal $type "checkbox"] || [string equal $type "radio"] ) && [info exists element(value)] } {
      # This can be used in the form template in a <label for="id">...</label> tag.
      set attributes(id) "$element(form_id):elements:$element(name):$element(value)"
  }

  set output "<input type=\"$type\" name=\"$element(name)\""

  if { [info exists element(value)] } {
    append output " value=\"[template::util::quote_html $element(value)]\""
  } 

  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output " />"

  return $output
}



ad_proc -public template::widget::text { element_reference tag_attributes } {

  upvar $element_reference element

  return [input text element $tag_attributes]
}



ad_proc -public template::widget::file { element_reference tag_attributes } {

  upvar $element_reference element

  return [input file element $tag_attributes]
}



ad_proc -public template::widget::password { element_reference tag_attributes } {

  upvar $element_reference element

  return [input password element $tag_attributes]
}


ad_proc -public template::widget::hidden { element_reference tag_attributes } {

  upvar $element_reference element

  return [input hidden element $tag_attributes]
}

ad_proc -public template::widget::submit { element_reference tag_attributes } {

  upvar $element_reference element

  # always ignore value for submit widget
  set element(value) $element(label) 

  return [input submit element $tag_attributes]
}

ad_proc -public template::widget::checkbox { element_reference tag_attributes } {

  upvar $element_reference element

  return [input checkbox element $tag_attributes]
}

ad_proc -public template::widget::radio { element_reference tag_attributes } {

  upvar $element_reference element

  return [input radio element $tag_attributes]
}

ad_proc -public template::widget::button { element_reference tag_attributes } {

  upvar $element_reference element

  return [input button element $tag_attributes]
}

ad_proc -public template::widget::menu { widget_name options_list values_list \
                              attribute_reference } {

  upvar $attribute_reference attributes

  set output "<select name=\"$widget_name\" "

  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">\n"

  # Create an array for easier testing of selected values
  template::util::list_to_lookup $values_list values 

  foreach option $options_list {

    set label [lindex $option 0]
    set value [lindex $option 1]

    append output "  <option value=\"[template::util::quote_html $value]\" "

    if { [info exists values($value)] } {
      append output "selected=\"selected\""
    }

    append output ">$label</option>\n"
  }

  append output "</select>"

  return $output
}

ad_proc -public template::widget::select { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  return [template::widget::menu \
    $element(name) $element(options) $element(values) attributes]
}

ad_proc -public template::widget::multiselect { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set attributes(multiple) {}

  # Determine the size automatically for a multiselect
  if { ! [info exists attributes(size)] } {
  
    set size [llength $element(options)]
    if { $size > 8 } {
      set size 8
    }
    set attributes(size) $size
  }

  return [template::widget::menu \
    $element(name) $element(options) $element(values) attributes]
}

ad_proc -public template::data::transform::search { element_ref } {

  upvar $element_ref element
  set element_id $element(id)

  set value [ns_queryget $element_id]

  # there will no value for the initial request or if the form
  # is submitted with no search criteria (text box blank)
  if { [string equal $value {}] } { return [list] } 

  if { [string equal $value ":search:"] } { 
      unset element(options)
      template::element::set_error $element(form_id) $element_id "
        Please enter a search string."
      return [list]
  }

  # check for a value that has been entered rather than selected
  if { ! [ns_queryexists $element_id:select] } {

    # perform a search based on the value
    if { ! [info exists element(search_query)] } { 
      error "No search query specified for search widget"
    }

    set query $element(search_query)
    if { [info exists element(search_query_name)] } {
        set query_name $element(search_query_name)
    } else {
        set query_name "get_options"
    }

    set options [db_list_of_lists $query_name $query]

    set option_count [llength $options]

    if { $option_count == 0 } {

      # no search results so return text entry back to the user

      unset element(options)

      template::element::set_error $element(form_id) $element_id "
        No matches were found for \"$value\".<br>Please
        try again."

    } elseif { $option_count == 1 } {

      # only one option so just reset the value
      set value [lindex [lindex $options 0] 1]

    } else {

      # need to return a select list
      set element(options) [concat $options { { "Search again..." ":search:" } }]
      template::element::set_error $element(form_id) $element_id "
        More than one match was found for \"$value\".<br>Please
        choose one from the list."

      set value [lindex [lindex $options 0] 1]
    }
  }

  if { [info exists element(result_datatype)] &&
       [ns_queryexists $element_id:select] } {
    set element(datatype) $element(result_datatype)
  }

  return [list $value]
}



ad_proc -public template::widget::textarea { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output "<textarea name=\"$element(name)\""

  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">"

  if { [info exists element(value)] } {
    append output "[template::util::quote_html $element(value)]"
  } 

  append output "</textarea>"
  return $output
}

ad_proc -public template::widget::comment { element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output {}

  if { [info exists element(history)] } {
      append output "$element(history)"
  }

  if { [info exists element(header)] } {
      append output "<p><b>$element(header)</b></p>"
  }

  append output "<textarea name=\"$element(name)\""

  foreach name [array names attributes] {
    if { [string equal $attributes($name) {}] } {
      append output " $name"
    } else {
      append output " $name=\"$attributes($name)\""
    }
  }

  append output ">"

  if { [info exists element(value)] } {
    # As per scottwseago's request
    append output [ad_quotehtml $element(value)]
  } 

  append output "</textarea>"

  return $output
}

