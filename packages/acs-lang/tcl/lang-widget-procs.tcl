ad_library {

    Widgets for acs-lang.

    Currently just a special version of the select widget which adds a "lang"
    attribute to each option, as required by accessibility standards.

    @author Don Baccus (dhogaza@pacifier.com)
    @creation-date November 3, 2006
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::widget {}

ad_proc -public template::widget::select_locales {
    element_reference
    tag_attributes
} {
    Generate a select widget for locales.  We need a custom widget for this one
    case because accessibility standards require us to put out a "lang" attribute
    if the text is not in the same language as the rest of the page.
} {

    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }
    if { [info exists element(values)] } {
         template::util::list_to_lookup $element(values) values
    }
    array set attributes $tag_attributes

    if { $element(mode) ne "edit" } {
        set selected_list [list]

        foreach option $element(options) {

            set label [lindex $option 0]
            set value [lindex $option 1]

            if { [info exists values($value)] } {
                lappend selected_list $label
                append output "<input type=\"hidden\" name=\"$element(name)\" value=\"[ad_quotehtml $value]\">"
            }
        }

        append output [join $selected_list ", "]

    } else {

        append output "<select name=\"$element(name)\" id=\"$element(name)\" "

        foreach name [array names attributes] {
            if {$attributes($name) eq {}} {
                append output " $name=\"$name\""
            } else {
                append output " $name=\"$attributes($name)\""
            }
        }
        append output ">\n"

        foreach option $element(options) {

            set label [lindex $option 0]
            set value [lindex $option 1]

            set value [ad_quotehtml $value]
            append output " <option lang=\"[string range $value 0 1]\" value=\"$value\""
            if { [info exists values($value)] } {
                append output " selected=\"selected\""
            }

            append output ">$label</option>\n"
        }
        append output "</select>"
    }

    return $output

}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
