ad_library {
    Form widgets for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
    @author Stanislav Freidin (sfreidin@arsdigita.com)
     
    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval template {}
namespace eval template::widget {}
namespace eval template::data {}
namespace eval template::data::transform {}

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
    @see template::widget::party_search
    @see template::widget::radio
    @see template::util::richtext
    @see template::widget::search
    @see template::widget::select
    @see template::widget::submit
    @see template::widget::text
    @see template::widget::textarea
    @see template::widget::block
    @see template::element::create
    @see template::widget::select_text
    @see template::wdiget::radio_text
    @see template::widget::checkbox_text
} -


ad_proc -public template::widget::party_search { element_reference tag_attributes } {

    A widget that searches for parties (persons, groups and relational_segments) and lets
    the user select one from the search results.

    <p>

    It only searches in all parties from the system currently. It should propably be extended to
    allow to restrict the search to a specific subsite, as well as searching only 
    for groups or persons.

    @author Tilmann Singer

} {

    upvar $element_reference element

    if { ![info exists element(options)] } {

        # initial submission or no data (no options): a text box
        set output [input text element $tag_attributes]

    } else {

        set output "<input type=\"hidden\" name=\"$element(id):select\" value=\"t\" >"
        append output "<input type=\"hidden\" name=\"$element(id):search_string\" value=\"$element(search_string)\" >"

        if { ![info exists element(confirmed_p)] } {
            append output "<input type=\"hidden\" name=\"$element(id):confirmed_p\" value=\"t\" >"
        }

        append output [select $element_reference $tag_attributes]
    }
    return $output
}

ad_proc -public template::data::validate::party_search { 
    value_ref
    message_ref
} {
    Validate the party search entry form.

    @param value_ref A reference to the value input by the user.
    @param message_ref A reference to the form element error field.

    @return true - all input for this datatype is valid.
} {
    return 1
}

ad_proc -private template::data::transform::party_search {
    element_ref
} {
    Do the actual search of parties using the input value and return a list of lists
    consisting of (party_name, party_id).

    DRB: The blank string check should actually be in the validate procedure.

    @param element_ref Reference variable to the form element.
    @return search result or error

} {
    upvar $element_ref element
    set element_id $element(id)

    set value [string trim [ns_queryget $element_id]]
    set is_optional [info exists element(optional)]

    if { $value eq "" } {
        if { [string is true $is_optional] } {
	    return ""
	} else {
	    template::element::set_error $element(form_id) $element_id "Please enter a search string."
	    return [list]
	}
    }

    if {$value eq ":search:"} {
        # user has selected 'search again' previously
        template::element::set_error $element(form_id) $element_id "Please enter a search string."
        return [list]
    }

    if { [ns_queryexists $element_id:search_string] } {
        # request comes from a page with a select widget and the
        # search string has been passed as hidden value
        set search_string [ns_queryget $element_id:search_string]
        set element(search_string) $search_string

        # the value to be returned
        set value [ns_queryget $element_id]
    } else {
        # request is an initial search
        set search_string $value
        set element(search_string) $value
    }

    # search in persons
    set persons [db_list_of_lists search_persons {}]

    # search in groups and relsegs
    set groups_relsegs [db_list_of_lists search_groups_relsegs {}]

    # Localize the groups 
    set groups_relsegs [lang::util::localize_list_of_lists -list $groups_relsegs]

    if { [llength $persons] == 0 && [llength $groups_relsegs] == 0 } {
        # no search results so return text entry back to the user

        catch { unset element(options) }

        template::element::set_error $element(form_id) $element_id "
        No matches were found for \"$search_string\".<br>Please
        try again."

    } else {
        # we need to return a select list

        set options [list]

        if { [llength $persons] > 0 } {
            set options $persons
            set options [concat $options [list [list "---" ""]]]
        }
        if { [llength $groups_relsegs] > 0 } {
            set options [concat $options $groups_relsegs]
            set options [concat $options [list [list "---" ""]]]
        }
        set element(options) [concat $options { { "Search again..." ":search:" } }]
        if { ![info exists value] } {
            # set value to first item
            set value [lindex $options 0 1]
        }

        if { ![ns_queryexists $element_id:confirmed_p] } {
            template::element::set_error $element(form_id) $element_id "Please choose an entry."
        }
    }

    if { [info exists element(result_datatype)] &&
         [ns_queryexists $element_id:select] } {
        set element(datatype) $element(result_datatype)
    }

    return $value
}


ad_proc -public template::widget::search {
    element_reference
    tag_attributes
} {
    Return a widget consisting of either a search box or a search pull-down list.

    Here is an example of using the search widget with ad_form:

<pre>
    ad_form -name test -form {
        {user:search,optional
            {result_datatype integer}
            {label "Email"}
            {help_text "Search for a user by email address"}
            {search_query {
                select email from cc_users where lower(email) like '%'||lower(:value)||'%'
            }}
        }
    }
</pre>
    Can be either a select widget initially if options supplied 
    or a text box which on submit changes to a select widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes If the "options" attribute is passed in, a select widget
           is created, otherwise a search text box.

    @return Form HTML for widget

} {
    upvar $element_reference element

    if { ! [info exists element(options)] } {

        # initial submission or no data (no options): a text box
        set output [input text element $tag_attributes]

    } else {

        # options provided so use a select list
        # include an extra hidden element to indicate that the
        # value is being selected as opposed to entered

        set output "\n<input type=\"hidden\" name=\"$element(id):select\" value=\"t\" >"
        append output [select element $tag_attributes]

    }


    return $output
}

ad_proc -public template::widget::textarea {
    element_reference
    tag_attributes
} {
    A widget for the HTML form input textarea element.  Includes spellchecker.

    @see template::util::spellcheck::spellcheck_properties

    @param element_reference Reference to the form element.
    @param tag_attributes Html attributes to set in the widget.

    @return Form HTML for widget

} {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }
    array set attributes $tag_attributes
    
    if { [info exists element(value)] } {
        set value $element(value)
    } else {
        set value {}
    }

    if { [info exists element(mode)] } {
        set mode $element(mode)
    } else {
        set mode {}
    }

	set attributes(id) $element(name)
    set output [textarea_internal $element(name) attributes $value $mode]

    # Spell-checker
    array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]
    
    if { $element(mode) eq "edit" && $spellcheck(render_p) } {
        append output "<br>[_ acs-templating.Spellcheck]: 
[menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) {}]"
  }   

  return $output
}

ad_proc -private template::widget::textarea_internal { 
    name 
    attribute_reference
    {value {}}
    {mode edit}
} {
    Do the actual construction of a textarea widget, called by various user-callable
    widgets.

    @param name Name of the widget.
    @param attribute_reference Reference variable to the tag_attributes passed to the calling
           widget proc.
    @param value Optional value
    @param mode If edit, output the textarea HTML, otherwise pass along the value (if
           it exists) in a hidden HTML input tag

    @return Form HTML for widget
} {
    upvar $attribute_reference attributes

    if { $mode ne "edit" } {
        set output {}
        if { $value ne "" } {
            append output "[ns_quotehtml $value]<input type=\"hidden\" name=\"$name\" value=\"[ns_quotehtml $value]\">"
        }
    } else {
        set output "<textarea name=\"$name\""
        
        foreach attribute_name [array names attributes] {
            if {$attributes($attribute_name) eq {}} {
                append output " $attribute_name"
            } else {
                append output " $attribute_name=\"$attributes($attribute_name)\""
            }
        }
        
        append output ">[ns_quotehtml $value]</textarea>"
    }
    
    return $output
}



ad_proc -public template::widget::inform { element_reference tag_attributes } {
    A static information widget that does not submit any data
} {

    upvar $element_reference element

    if { [info exists element(value)] } {
        return "$element(value)[input hidden element $tag_attributes]"
    } else {
        return [input hidden element $tag_attributes]
    }
}

ad_proc -public template::widget::input {
    type
    element_reference
    tag_attributes
} {
    General proc used by a wide variety of widgets to output input HTML tags.

    @param type The type of widget (checkbox, radio, text etc)
    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to hang on the input tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    array set attributes $tag_attributes

    if { ( $type eq "checkbox" || $type eq "radio" ) && [info exists element(value)] } {
        # This can be used in the form template in a <label for="id">...</label> tag.
        set attributes(id) "$element(form_id):elements:$element(name):$element(value)"
    } elseif { $type in {"password" "text" "button" "file" }} { 
	set attributes(id) "$element(name)" 
    }

    # Handle display mode of visible normal form elements, i.e. not hidden, not submit, not button, not clear
    if { $element(mode) ne "edit" && $type ni { hidden submit button clear checkbox radio } } {
        set output ""
        if { [info exists element(value)] } {
            append output [ns_quotehtml $element(value)]
            append output [subst {<input type="hidden" name="$element(name)" value="[ns_quotehtml $element(value)]">}]
        }
    } else {
        set output [subst {<input type="$type" name="$element(name)"}]

        if { $element(mode) ne "edit" && $type ni { hidden submit button clear } } {
            append output " disabled"
        }

        if { [info exists element(value)] } {
            append output [subst { value="[ns_quotehtml $element(value)]"}]
        } 

        foreach name [array names attributes] {
            if {$attributes($name) eq {}} {
                append output " $name"
            } else {
                append output [subst { $name="$attributes($name)"}]
            }
        }

        if { [info exists element(maxlength)] } {
            append output [subst { maxlength="$element(maxlength)"}]
        }

        append output " >"

    }

    return $output
}

ad_proc -public template::widget::text {
    element_reference
    tag_attributes
} {

    Generate a text widget (not to be confused with textarea)

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    # Spell-checker
    array set spellcheck [template::util::spellcheck::spellcheck_properties -element_ref element]

    if { $element(mode) eq "edit" && $spellcheck(render_p) } {
        return "[input text element $tag_attributes] <br>[_ acs-templating.Spellcheck]: 
[menu "$element(id).spellcheck" [nsv_get spellchecker lang_options] $spellcheck(selected_option) {}]"
  } else {
      return [input text element $tag_attributes]
  }
}



ad_proc -public template::widget::file {
    element_reference
    tag_attributes
} {
    Generate a file widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    return [input file element $tag_attributes]
}



ad_proc -public template::widget::password {
    element_reference
    tag_attributes
} {
    Generate a password input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    return [input password element $tag_attributes]
}

ad_proc -public template::widget::hidden {
    element_reference
    tag_attributes
} {

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {
    upvar $element_reference element

    # Antonio Pisano: 
    # before 2015-09-03 we didn't enter this 'if' when element(value) existed.
    # This means that even if we had multiple values in element(values) those
    # were ignored, preventing the export of multiple values by hidden formfields.
    # I changed this by saying that field is multiple whenever element(values) 
    # exists and is not null.
    if { [info exists element(values)] && $element(values) ne "" } {
      #ns_log notice "hidden form element with multiple values: <$element(values)>"
      set output {}
      set count 0
      foreach itemvalue $element(values) {
	append output [subst {
	  <input type="hidden" id="$element(form_id):$element(name):$count" name="$element(name)" value="[ns_quotehtml $itemvalue]">
	}]
        incr count
      }
      return $output

    } else {

      #
      # Standard case
      #
      return [input hidden element $tag_attributes]
    }

}


ad_proc -public template::widget::submit {
    element_reference
    tag_attributes
} {
    Render a submit input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    # always ignore value for submit widget
    set element(value) $element(label) 

    return [input submit element $tag_attributes]
}

ad_proc -public template::widget::attachment {
    element_reference
    tag_attributes
} {
    Render an attachment input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    set output [input file element $tag_attributes]

    set element(name) $element(attach_name)
    set element(label) $element(attach_label)
    set element(html) $element(attach_html)

    append output [submit element $tag_attributes]

    return $output
}

ad_proc -public template::widget::checkbox {
    element_reference
    tag_attributes
} {
    Render a checkbox input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    return [input checkbox element $tag_attributes]
}

ad_proc -public template::widget::radio {
    element_reference
    tag_attributes
} {
    Render a radio input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    return [input radio element $tag_attributes]
}

ad_proc -public template::widget::button {
    element_reference
    tag_attributes
} {
    Render a button input widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    return [input button element $tag_attributes]
}

ad_proc -public template::widget::menu { 
    widget_name
    options_list
    values_list
    attribute_reference
    {mode edit}
    {widget_type select}
} {
    Render a menu widget (a "select" dropdown menu by default).

    @param widget_name Name of the widget
    @param options_list List of option/value pairs (i.e. dropdown menu items)
    @param values_list List of values (i.e. the selected default value)
    @param attribute_reference Reference variable to the caller's tag_attributes param
    @param mode If "edit" the widget is rendered, otherwise values are passed along
           using hidden input HTML tags
    @param widget_type Select, checkbox, etc

    @return Form HTML for widget

} {

    upvar $attribute_reference attributes

    # Create an array for easier testing of selected values
    template::util::list_to_lookup $values_list values

    set output {}
    if { $mode ne "edit" } {
        set selected_list [list]

        foreach option $options_list {

            set label [lindex $option 0]
            set value [lindex $option 1]

            if { [info exists values($value)] } {
                lappend selected_list $label
                append output [subst {<input type="hidden" name="$widget_name" value="[ns_quotehtml $value]">}]
            }
        }

        append output [join $selected_list ", "]
    } else {
        switch -exact -- $widget_type {
            checkbox -
            radio {
                if {![info exists attributes(multiple)]} {
                    set widget_type radio
                }
                foreach option $options_list {

                    set label [lindex $option 0]
                    set value [lindex $option 1]

                    append output [subst { <input type="$widget_type" name="$widget_name" value="[ns_quotehtml $value]"}]
                    if { [info exists values($value)] } {
                        append output [subst { checked="checked"}]
                    }

                    append output [subst {>[ns_quotehtml $label]<br>\n}]
                }
            }
            default {
                append output [subst {<select name="$widget_name" id="$widget_name" }]

                foreach name [array names attributes] {
                    if {$attributes($name) eq {}} {
                        append output [subst { $name="$name"}]
                    } else {
                        append output [subst { $name="$attributes($name)"}]
                    }
                }
                append output ">\n"

                foreach option $options_list {
                    lassign $option label value

                    append output [subst { <option value="[ns_quotehtml $value]"}]
                    if { [info exists values($value)] } {
                        append output [subst { selected="selected"}]
                    }
                    # Whe option element contains "normal" character data,
                    # which must not contain any "<". For details, see:
                    # https://www.w3.org/TR/html-markup/syntax.html#normal-character-data
                    append output [subst {>[string map {< "&lt;" > "&gt;"} $label]</option>\n}]
                }
                append output "</select>"
            }
        }
    }

    return $output
}

ad_proc -public template::widget::select {
    element_reference
    tag_attributes
} {
    Render a select widget which allows only one value to be selected.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    array set attributes $tag_attributes

    return [template::widget::menu \
                $element(name) $element(options) $element(values) attributes $element(mode)]
}

ad_proc -public template::widget::multiselect {
    element_reference
    tag_attributes
} {
    Render a select widget which allows any number of values to be selected.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

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
                $element(name) $element(options) $element(values) attributes $element(mode)]
}

ad_proc -public template::data::transform::search {
    element_ref
} {
    Process a submitted search widget's data.

    @param element_ref Reference variable to the form element

    @return Transformed value
} {

    upvar $element_ref element
    set element_id $element(id)

    set value [ns_queryget $element_id]

    # there will no value for the initial request or if the form
    # is submitted with no search criteria (text box blank)
    if {$value eq {}} { return [list] } 

    if {$value eq ":search:"} { 
        if { [info exists element(options)] } {
            unset element(options)
        }
        template::element::set_error $element(form_id) $element_id \
            "Please enter a search string."
        return [list]
    }

    # check for a value that has been entered rather than selected
    if { ! [ns_queryexists $element_id:select] } {

        # perform a search based on the value
        if { ! [info exists element(search_query)] } { 
            error "No search query specified for search widget"
        }

        set query $element(search_query)

        set options [db_list_of_lists get_options $query]

        set option_count [llength $options]

        if { $option_count == 0 } {

            # no search results so return text entry back to the user

            if { [info exists element(options)] } {
                unset element(options)
            }

            template::element::set_error $element(form_id) $element_id \
                "No matches were found for \"$value\".<br>Please\ntry again."

        } elseif { $option_count == 1 } {

            # only one option so just reset the value
            set value [lindex $options 0 1]

        } else {

            # need to return a select list
            set element(options) [concat $options { { "Search again..." ":search:" } }]
            template::element::set_error $element(form_id) $element_id \
                "More than one match was found for \"$value\".<br>Please\nchoose one from the list."

            set value [lindex $options 0 1]
        }
    }

    if { [info exists element(result_datatype)] &&
         [ns_queryexists $element_id:select] } {
        set element(datatype) $element(result_datatype)
    }

    return [list $value]
}

ad_proc -public template::widget::comment {
    element_reference
    tag_attributes
} {
    Render a comment widget.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    array set attributes $tag_attributes

    set output {}

    if { [info exists element(history)] } {
        append output "$element(history)"
    }

    if {$element(mode) eq "edit"} {
        if { [info exists element(header)] } {
            append output "<p><b>$element(header)</b></p>"
        }
        
        append output [textarea $element_reference $tag_attributes]

        if { [info exists element(format_element)] && [info exists element(format_options)] } {
            append output "<br>Format: [menu $element(format_element) $element(format_options) {} {}]"
        }
    }
    
    return $output
}

ad_proc -public template::widget::block {
    element_reference
    tag_attributes
} {
    Widget for blocks of radio-buttoned questions

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag

    @return Form HTML for widget
} {
    upvar $element_reference element
    
    if { [info exists element(html)] } {
	array set attributes $element(html)
    }
    
    if { [info exists element(value)] } {
	set value $element(value)
    } else {
	set value {}
    }

    array set attributes $tag_attributes
    
    set output ""
    set options $element(options)
    set count 0
    foreach option $options {
	if {$count == 0} {
	    # answer descriptions in a list: {{desc1 no_of_answers} {desc2 no_of_answers} ...}
	    append output "<tr align='center'><td></td><td></td>"
	    foreach answer_desc $option {
		set answer_description [lindex $answer_desc 0]
		set no_of_answers [lindex $answer_desc 1]
		append output "<th colspan=\"[expr {$no_of_answers + 1}]\" align=\"center\">$answer_description</th>"
	    }
	    append output "</tr>"
	} elseif {$count == 1} {
	    append output "<tr><td><span style=\"font-weight: bold\">[lindex $option 0]</span></td>"
	    foreach answer_set [lindex $option 1] {
		append output "<td>required?</td>"
		foreach answer $answer_set {
		    append output "<td>$answer</td>"
		}
	    }
	    append output "</tr>"
	} else {
	    append output "<tr><td><span style=\"font-weight: bold\">[lindex $option 0]</span></td>"
	    foreach question [lindex $option 1] {
		set name [lindex $question 0]
		set required_p [lindex $question 1]
		append output "<td>[ad_decode $required_p "t" "<span style=\"color: #f00;\">*</span>" "&nbsp;"]</td>"
		foreach choice [lindex $question 2] {
		    if {$choice ni $value} {
			append output "<td><input type=\"radio\" name=\"$name\" value=\"$choice\"></td>"
		    } else {
			append output "<td><input type=\"radio\" name=\"$name\" value=\"$choice\" checked></td>"
		    }
		}
	    }
	    append output "</tr>"
	}
	incr count
    }

    return "<table>$output</table>"
}

###############################################################################
# radio/select/checkbox widgets with a textbox associated for other
###############################################################################

namespace eval template::util::select_text {}
namespace eval template::util::radio_text {}
namespace eval template::util::checkbox_text {}

ad_proc -public template::data::validate::select_text {
    value_ref
    message_ref
} {
    validate a select_text datatype
} {
    # FIXME do something?
    return 1
}

ad_proc -public template::data::transform::select_text {
    element_ref
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-07-18

    @param element_ref
    @return 
    @error 
} {
    upvar $element_ref element
    set element_id $element(id)
    set text_value [ns_queryget $element_id.text]
    set select_value [ns_queryget $element_id]
    return [list [list $select_value $text_value]]
}

ad_proc -public template::util::select_text::get_property {
    what
    select_text_list
} {
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-07-18
    
    @param what
    @param select_text_list
    @return 
    @error 
} {
    switch $what {
        select_value - select {
            return [lindex $select_text_list 0]
        }
        text_value - text {
            return [lindex $select_text_list 1]
        }
        default {
            error "Parameter supplied to util::select_text::get_property 'what' must be one of: select_value, text_value. You specified: '$what'."
        }
    }
}

ad_proc -public template::widget::select_text {
    element_reference
    tag_attributes
} {
    Implements the complex widget select_text which combines
    a select widget with a text widget 
    @author Dave Bauer (dave@thedesignexperience.org)
    @creation-date 2004-07-18

    @param element_reference
    @param tag_attributes
    @return 
    @error 
} {

    upvar $element_reference element
    if { [info exists element(html)] } {
	array set attributes $element(html)
    }
    
    array set attributes $tag_attributes
    
    if { [info exists element(value)] } {
	set select [template::util::select_text::get_property select_value $element(value)]
	set text   [template::util::select_text::get_property text_value $element(value)]
    } else {
	set select {}
	set text {}
    }

    set output {}
    if {$element(mode) eq "edit"} {
	# edit mode
	set element(value) $select
	append output [template::widget::menu $element(name) $element(options) $select attributes $element(mode)]

	if {![info exists element(other_label)]} {
	    set element(other_label) "[_ acs-templating.Other]"
	}
	append output " $element(other_label): "
	set element(value) $text
	set element(name) $element(name)\.text
	append output [template::widget::input text element $tag_attributes]
    } else {
	# display mode
	if { [info exists element(value)] } {
	    append output [template::util::select_text::get_property select_value $element(value)]
	    append output "&nbsp;"
	    append output [template::util::select_text::get_property text_value $element(value)]          
	    append output "<input type=\"hidden\" name=\"$element(id).text\" value=\"[ns_quotehtml $text]\">"
	    append output "<input type=\"hidden\" name=\"$element(id)\" value=\"[ns_quotehtml $select]\">"
	}
    }
    
    return $output
}


##########################


ad_proc -public template::data::validate::radio_text {
    value_ref
    message_ref
} {
    validate a radio_other datatype
} {
    return 1
}

ad_proc -public template::data::transform::radio_text {
    element_ref
} {
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2004-10-17

    @param element_ref
    @return 
    @error 
} {
    upvar $element_ref element
    set element_id $element(id)
    set text_value [ns_queryget $element_id\.text]
    set radio_value [ns_queryget $element_id]
    return [list [list $radio_value $text_value]]
}

ad_proc -public template::util::radio_text::get_property {
    what
    radio_list
} {
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2004-10-17
    
    @param what
    @param radio_list
    @return 
    @error 
} {
    switch $what {
        radio_value - radio {
            return [lindex $radio_list 0]
        }
        text_value - text {
            return [lindex $radio_list 1]
        }
        default {
            error "Parameter supplied to util::radio_text::get_property 'what' must be one of: radio_value, text_value. You specified: '$what'."
        }
    }
}

ad_proc -public template::widget::radio_text {
    element_reference
    tag_attributes
} {
    Implements the complex widget radio_text which combines
    a radio widget with a text widget 

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2004-10-17

    @param element_reference
    @param tag_attributes
    @return 
    @error 
} {
    upvar $element_reference element
    if { [info exists element(html)] } {
	array set attributes $element(html)
    }
    
    array set attributes $tag_attributes
    
    if { [info exists element(value)] } {
	set radio [template::util::radio_text::get_property radio_value $element(value)]
	set text  [template::util::radio_text::get_property text_value $element(value)]
    } else {
	set radio {}
	set text {}
    }
    set output {}

    # edit mode
    set radio_text "<input type='radio' name='$element(name)'"

    foreach name [array names attributes] {
        if {$attributes($name) eq {}} {
            append radio_text " $name"
        } else {
            append radio_text " $name=\"$attributes($name)\""
        }
    }

    # Create an array for easier testing of selected values
    template::util::list_to_lookup $radio values 
    set output ""
    foreach option $element(options) {
        set label [lindex $option 0]
        set value [lindex $option 1]

        append output "$radio_text value=\"$value\""
        if { [info exists values($value)] } {
            append output " checked=\"checked\""
        }
        if {$element(mode) ne "edit"} {
            append output " disabled"
        }
        append output ">$label<br>"
    }
    if {![info exists element(other_label)]} {
        set element(other_label) "[_ acs-templating.Other]"
    }
    append output "$element(other_label): "
    set element(value) $text
    set element(name) $element(name)\.text
    append output [template::widget::input text element $tag_attributes]

    return $output
}


##########################


ad_proc -public template::data::validate::checkbox_text {
    value_ref
    message_ref
} {
    validate a checkbox_other datatype
} {
    # FIXME do something?
    return 1
}

ad_proc -public template::data::transform::checkbox_text {
    element_ref
} {
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2004-10-17

    @param element_ref
    @return 
    @error 
} {
    upvar $element_ref element
    set element_id $element(id)
    set text_value [ns_queryget $element_id\.text]
    set checkbox_value [ns_queryget $element_id]
    return [list [list $checkbox_value $text_value]]
}

ad_proc -public template::util::checkbox_text::get_property {
    what
    checkbox_list
} {
    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2004-10-17
    
    @param what
    @param checkbox_list
    @return 
    @error 
} {
    switch $what {
        checkbox_value - checkbox {
            return [lindex $checkbox_list 0]
        }
        text_value - text {
            return [lindex $checkbox_list 1]
        }
        default {
            error "Parameter supplied to util::checkbox_text::get_property 'what' must be one of: checkbox_value, text_value. You specified: '$what'."
        }
    }
}

ad_proc -public template::widget::checkbox_text {
    element_reference
    tag_attributes
} {
    Implements the complex widget checkbox_other which combines
    a checkbox widget with a text widget 

    @author Timo Hentschel (timo@timohentschel.de)
    @creation-date 2004-10-17

    @param element_reference
    @param tag_attributes
    @return 
    @error 
} {
    upvar $element_reference element
    if { [info exists element(html)] } {
	array set attributes $element(html)
    }
    
    array set attributes $tag_attributes
    
    if { [info exists element(values)] } {
	set checkbox [template::util::checkbox_text::get_property checkbox_value $element(values)]
	set text     [template::util::checkbox_text::get_property text_value $element(values)]
    } else {
	set checkbox {}
	set text {}
    }

    set output {}
    
    # edit mode
    set checkbox_text [subst {<input type="checkbox" name="$element(name)"}]

    foreach name [array names attributes] {
	if {$attributes($name) eq {}} {
	    append checkbox_text " $name"
	} else {
	    append checkbox_text [subst { $name="$attributes($name)"}]
	}
    }
    
    # Create an array for easier testing of selected values
    template::util::list_to_lookup $checkbox values 
    
    foreach option $element(options) {
	set label [lindex $option 0]
	set value [lindex $option 1]
	
	append output "$checkbox_text value=\"$value\""
	if { [info exists values($value)] } {
	    append output " checked=\"checked\""
	}
	append output ">$label<br>"
    }
    if {![info exists element(other_label)]} {
	set element(other_label) "[_ acs-templating.Other]"
    }
    append output "$element(other_label): "
    set element(value) $text
    set element(name) $element(name)\.text
    append output [template::widget::input text element $tag_attributes]
    
    return $output
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

