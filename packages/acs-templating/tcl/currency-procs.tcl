ad_library {
    Currency widgets for the OpenACS Templating System
    
    @author Don Baccus (dhogaza@pacifier.com)
}

# These are modelled somewhat after the date procs.

# DRB: This was totally non-functional in ACS 4.2 Classic.  It's now partly
# functional in that we accept and process currency values.  We really need
# to tie this in with the acs-lang money database as this code's far too
# simplistic.    

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval template {}
namespace eval template::util {}
namespace eval template::util::currency {}
namespace eval template::data::validate::currency {}
namespace eval template::data::transform::currency {}
namespace eval template::util::currency::set_property {}
namespace eval template::widget::currency {}
 
ad_proc -public template::util::currency { command args } {
    Dispatch procedure for the currency object
} {
  template::util::currency::$command {*}$args
}

ad_proc -public template::util::currency::create {
  {leading_symbol {}}
  {whole_part {}}
  {separator {}}
  {fractional_part {}}
  {trailing_money {}}
  {format "$ 5 . 2"}
} {
    Create a currency form element.

    @param leading_symbol The leading symbol for the currency format (default: "$")
    @param whole_part The number of digits in the whole part of the value (default: 5)
    @param separator The character the separates the whole part from the fractional part
           (default ".")
    @param fractional_part The number of digits allowed in the fractional part of the
           value (default: 2, i.e. US Pennies)
    @param trailing_money For those currencies that use a trailing rather than leading
           character in their normal representation
    @param format The actual format to use in list form

    @return The parameters joined in a six-element list 
} {
    return [list $leading_symbol $whole_part $separator $fractional_part $trailing_money $format]
}

ad_proc -public template::util::currency::acquire {
    type
    { value "" }
} {
    Create a new currency value with some predefined value
    Basically, create and set the currency value

    @param type The set_property type to set (only sql_number supported currently)

    @return The new currency value set to the predefined value
} {
  set currency_list [template::util::currency::create]
  return [template::util::currency::set_property $type $currency_list $value]
}

ad_proc -public template::data::validate::currency {
    value_ref
    message_ref
} {
    form validation for currency type.

    Should validate according to locale for example, the following forms: "$2.03"
    "Rs 50.42" "12.52L" "Y5,13c"

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning error messages

    @return true (1) if valid, false (0) if not

} {
    upvar 2 $message_ref message $value_ref value

    # a currency is a 6 element list supporting, for example, the following forms: "$2.03" "Rs 50.42" "12.52L" "Y5,13c"
    # equivalent of date::unpack
    set leading_symbol  [lindex $value 0]
    set whole_part      [lindex $value 1]
    set separator       [lindex $value 2]
    set fractional_part [lindex $value 3]
    set trailing_money  [lindex $value 4]
    set format          [lindex $value 5]

    set format_whole_part      [lindex $format 1]
    set format_fractional_part [lindex $format 3]

    set whole_part_valid_p [template::data::validate integer whole_part message]
    if { $fractional_part ne "" } {
        set fractional_part_valid_p [template::data::validate integer fractional_part message]
    } else {
        set fractional_part_valid_p 1
    }

    if { ! $whole_part_valid_p || ! $fractional_part_valid_p } {
	set message "[_ acs-templating.Invalid_currency] [join [lrange $value 0 4] ""]"
	return 0
    } else {
	return 1
    }
}

ad_proc -private template::data::transform::currency {
    element_ref
} {
    Transform the previously-validated submitted form data into a six-element currency list

    @param element_ref Reference variable to the form element

} {

    upvar $element_ref element
    set element_id $element(id)

    set format [ns_queryget $element_id.format]
    for { set i [llength $format] } { $i < 5 } { incr i } {
        lappend format ""
    }

    # a currency is a 6 element list supporting, for example, the following forms: "$2.03" "Rs 50.42" "12.52L" "Y5,13c"

    set have_values 0

    for { set i 0 } { $i <= 4 } { incr i } {
	set key "$element_id.$i"    
	if { [ns_queryexists $key] } {
	    set value [ns_queryget $key]

	    # let's put a leading zero if the whole part is empty
	    if { $i == 1 } {
		if {$value eq ""} {
		    set value 0
		} else {
                    set have_values 1
                }
	    }

	    # and let's fill in the zeros at the end up to the precision
	    if { $i == 3 } {
		if { $value ne "" } {
                    set have_values 1
                }
		set fractional_part_format [lindex $format 3]
		for { set j [string length $value] } { $j < $fractional_part_format } { incr j } {
		    append $value 0
		}
	    }

	    lappend the_amount $value

	} else {
            lappend the_amount ""
        }
    }

    lappend the_amount [ns_queryget $element_id.format]

    ns_log debug "template::data::transform::currency: the_amount: $the_amount length: [llength $the_amount]"

    if { $have_values } {
	return [list $the_amount]
    } else {
	return [list]
    }
}

ad_proc -public template::util::currency::set_property {
    what
    currency_list
    value
} {
    Set a currency value to a set value, with that value being of "what"
    form.  Currently the only "what" supported is sql_number, it being assumed
    (somewhat reasonably) that SQL's NUMERIC datatype will be used to store
    currency data in the database, regardless of locale.

    @param what What kind of value is being passed in (sql_number is the only
           format supported)
    @param currency_list A currency data type value
    @param value The value to set currency_list to

    @return currency_list set to value
    
} {

    # Erase leading zeroes from the value, but make sure that 00
    # is not completely erased
    set value [util::trim_leading_zeros $value]

    set format [lindex $currency_list 5]

    switch $what {
        sql_number {

            if { $value eq ""} {
                return ""
            }

            foreach {whole_part fractional_part} [split $value "."] {
                # Make sure we have at least one leading digit, i.e. zero
                set whole_part "[string range "0" [string length $whole_part] end]$whole_part"

                # Chop off trailing digits beyond those called for by the given format
                set fractional_part "[string range $fractional_part 0 [lindex $format 3]-1]"
            }
            set new_value [lreplace $currency_list 1 1 $whole_part]
            return [lreplace $new_value 3 3 $fractional_part]
        }
        default {
            error "util::currency::property: unknown property: '$what'."
        }
    }
}

ad_proc -public template::util::currency::get_property {
    what
    currency_list
} {

    Return a property of a currency list which was created by a 
    currency widget.

    The most useful properties that can be returned are sql_number (compatible with
    SQL's NUMERIC type, historically called NUMBER by Oracle) and display_currency,
    which takes the value and formats properly.

    @param what The name of the property (see code for allowed values)
    @param currency_list a currency widget list, usually created with ad_form


} {
    # There's no internal error checking, just like the date version ... and
    # of course whole_part might be pounds and fractional_part pfennings ...

    set leading_symbol [lindex $currency_list 0]
    set whole_part [lindex $currency_list 1]
    set separator [lindex $currency_list 2]
    set fractional_part [lindex $currency_list 3]
    set trailing_money [lindex $currency_list 4]
    set format [lindex $currency_list 5]

    switch $what {
        leading_symbol {
            return $leading_symbol
        }
        whole_part {
            return $whole_part
        }
        separator {
            return $separator
        }
        fractional_part {
            return $fractional_part
        }
        trailing_money {
            return $trailing_money
        }
        format {
            return $format
        }
        sql_number {

            if { $whole_part eq "" && $fractional_part eq "" } {
                return ""
            }

            # Make sure we have at least one leading digit, i.e. zero
            set whole_part "[string range "0" [string length $whole_part] end]$whole_part"

            # Pad out the fractional part with enough leading zeros to satisfy the format
            set fractional_part "[string range [string repeat "0" [lindex $format 3]] [string length $fractional_part] end]$fractional_part"
            return ${whole_part}.${fractional_part}
        }
        display_currency {

            if { $whole_part eq "" && $fractional_part eq "" } {
                return ""
            }

            # Make sure we have at least one leading digit, i.e. zero
            set whole_part "[string range "0" [string length $whole_part] end]$whole_part"

            # Pad out the fractional part with enough leading zeros to satisfy the format
            set fractional_part "[string range [string repeat "0" [lindex $format 3]] [string length $fractional_part] end]$fractional_part"

            # Glom everything into one pretty picture
            return "$leading_symbol$whole_part$separator$fractional_part$trailing_money"
        }
        default {
            error "util::currency::property: unknown property: '$what'."
        }
    }
}

ad_proc -public template::widget::currency {
    element_reference
    tag_attributes
    {mode edit}
} {
    Render a currency widget.

    By default, the currency widget takes the form $ddddd.dd, i.e. US dollars
    and cents.  You can optionally pass along a format for different currency.

    @param element_reference Reference variable to the form element
    @param tag_attributes HTML attributes to add to the tag
    @param mode If edit, the rendered widget allows input, otherwise the values
           are passed along as hidden input HTML tags

    @return Form HTML for widget
} {
    upvar $element_reference element

    if { [info exists element(html)] } {
	array set attributes $element(html)
    }

    if { ! [info exists element(format)] } {
	set element(format) "$ 5 . 2"
    }
    set format [split $element(format) " "]
    for { set i [llength $format] } { $i < 5 } { incr i } {
        lappend format ""
    }

    if { [info exists element(value)] } {
	set values $element(value)
    } else {
        set values [list "" "" "" "" "" $element(format)]
    }

    set i 0
    foreach format_property $format {
        set value [lindex $values 0]
        set values [lrange $values 1 end]
        set trailing_zero ""
        if { $i == 3 } {
            set trailing_zero [string range [string repeat "0" $format_property] [string length $value] end]
        }
        if { $i == 0 || $i == 2 || $i == 4 } {
            append output "$format_property<input type=\"hidden\" name=\"$element(name).$i\" value=\"$format_property\" >"
        } elseif { $element(mode) eq "edit" && ($i == 1 || $i == 3) } {
            append output "<input type=\"text\" name=\"$element(name).$i\" maxlength=\"$format_property\" size=\"$format_property\" value=\"$value$trailing_zero\" >\n"
        } else {
            append output "$value$trailing_zero<input type=\"hidden\" name=\"$element(name).$i\" maxlength=\"$format_property\" size=\"$format_property\" value=\"$value\" >"
        }
        incr i
    }
    append output "<input type=\"hidden\" name=\"$element(name).format\" value=\"$element(format)\" >\n"

    return $output
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
