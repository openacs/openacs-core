# Form widgets for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          Stanislav Freidin (sfreidin@arsdigita.com)
     
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public template::widget::search { element_reference tag_attributes } {

  upvar $element_reference element

  if { ! [info exists element(options)] } {

    # initial submission or no data (no options): a text box
    set output [input text element $tag_attributes]

  } else {
    
    # options provided so use a select list
    # include an extra hidden element to indicate that the 
    # value is being selected as opposed to entered

    set output "<input type=hidden name=$element(id):select value=t>"
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

  set output "<textarea name=$element(name)"

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
    append output [ns_quotehtml $element(value)]
  } 

  append output "</textarea>"

  return $output
}

# A static information widget that does not submit any data

ad_proc -public template::widget::inform { element_reference tag_attributes } {

  upvar $element_reference element

  return $element(value)
}

ad_proc -public template::widget::input { type element_reference tag_attributes } {

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output "<input type=$type name=$element(name)"

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

  append output ">"

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

  set output "<select name=$widget_name "

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
      append output "selected"
    }

    append output ">$label\n"
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

ad_proc -public template::widget::currency { element_reference tag_attributes } {

    upvar $element_reference element
    
    if { [info exists element(html)] } {
	array set attributes $element(html)
    }

    set default { $ 5 . 2 "" }
    if { ! [info exists element(format)] } {
	set format { {} {} {} {} {} }
    } else {
	set format [split $element(format) " "]
    }

    if { [info exists element(value)] } {
	ns_log Notice "element value $element(value)"
	ns_log Notice "sep [lindex $format 0][lindex $format 2][lindex $format 4]"
	ns_log Notice "checking [string index $element(value) 0] [lindex $format 0]"
	if { [string equal [string index $element(value) 0] [lindex $format 0] ] } {
	    ns_log Notice "in here"
	    set element(value) [string range $element(value) 1 end]
	}
	ns_log Notice "new element $element(value)"
	set values [split $element(value) "[lindex $format 0][lindex $format 2][lindex $format 4]"]
	ns_log Notice "values $values"
    }

    set i 0
    foreach format_property $format {
	if { $i == 0 || $i == 2 || $i == 4 } {
	    append output $format_property
	} elseif { $i == 1 || $i == 3 } {
	    set value [lindex $values 0]
	    set values [lrange $values 1 end]

	    if { [string equal $format_property 0] } {
		append output $value
	    } else {
		append output "<input text size=$format_property value=$value>"
	    }
	    ns_log Notice "Values $i: [lindex $values $i]"
	}
	incr i
    }

    return $output
}

ad_proc -public template::data::transform::currency { element_ref } {

  upvar $element_ref element
  set element_id $element(id)

    set format [split [ns_queryget "$element_id.format"] ""]
    
    set have_values 0

    foreach field { 
	leading_symbol whole_part seperator fractional_part trailing_symbol
    } {
	set key "$element_id.$field"    
	if { [ns_queryexists $key] } {
	    set value [ns_queryget $key]

	    # let's put a leading zero if the whole part is empty
	    if { [string equal $field whole_part] } {
		if { [string equal $value ""] } {
		    set value 0
		}
	    }

	    # and let's fill in the zeros at the end up to the precision
	    if { [string equal $field fractional_part] } {
		set fractional_part_format [lindex format 3]
		for { set i [string length $value] } { $i < $fractional_part_format } { set i [expr $i + 1] } {
		    append $value 0
		}
	    }

	    # If the value is not null, set it
	    if { ![string equal $value {}] } {
		lappend the_amount $value
		set have_values 1
	    }
	}
    }

    lappend the_amount $format

    ns_log Notice "The amount: $the_amount"

    if { $have_values } {
	return [list $the_amount]
    } else {
	return {}
    }
}

ad_proc -public template::data::transform::search { element_ref } {

  upvar $element_ref element
  set element_id $element(id)

  set value [ns_queryget $element_id]

  # there will no value for the initial request or if the form
  # is submitted with no search criteria (text box blank)
  if { [string equal $value {}] } { return [list] } 

  # check for a value that has been entered rather than selected
  if { ! [ns_queryexists $element_id:select] } {

    # perform a search based on the value
    if { ! [info exists element(search_query)] } { 
      error "No search query specified for search widget"
    }

    # FIXME: need to get a statement name here
    set query $element(search_query)

    template::query get_options options multilist $query

    set option_count [llength $options]

    if { $option_count == 0 } {

      # no search results so return text entry back to the user

      template::element::set_error $element(form_id) $element_id "
        No matches were found for \"$value\".<br>Please
        try again."

    } elseif { $option_count == 1 } {

      # only one option so just reset the value
      set value [lindex [lindex $options 0] 1]

    } else {

      # need to return a select list
      set element(options) $options
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

  set output "<textarea name=$element(name)"

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
