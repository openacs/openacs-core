# Currency widgets for the OpenACS Templating System

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# @author Don Baccus (dhogaza@pacifier.com)

# These are modelled somewhat after the date procs.

# DRB: This was totally non-functional in ACS 4.2 Classic.  It's now partly
# functional in that we accept and process currency values.  We really need
# to tie this in with the acs-lang money database as this code's far too
# simplistic.

ad_proc -public template::util::currency { command args } {
    Dispatch procedure for the currency object
} {
  eval template::util::currency::$command $args
}

ad_proc -public template::util::currency::create {
  {leading_symbol {}} {whole_part {}} {separator {}}
  {fractional_part {}} {trailing_money {}} {format "$ 5 . 2"}
} {
    return [list $leading_symbol $whole_part $separator $fractional_part $trailing_money $format]
}

ad_proc -public template::util::currency::acquire { type { value "" } } {
    Create a new currency value with some predefined value
    Basically, create and set the currency value
} {
  set currency_list [template::util::currency::create]
  return [template::util::currency::set_property $type $currency_list $value]
}

ad_proc -public template::data::validate::currency { value_ref message_ref } {

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
    if { ![empty_string_p $fractional_part] } {
        set fractional_part_valid_p [template::data::validate integer fractional_part message]
    } else {
        set fractional_part_valid_p 1
    }

    if { ! $whole_part_valid_p || ! $fractional_part_valid_p } {
	set message "Invalid currency [join [lrange $value 0 4] ""]"
	return 0
    } else {
	return 1
    }
}    

ad_proc -public template::data::transform::currency { element_ref } {

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
		if { [string equal $value ""] } {
		    set value 0
		} else {
                    set have_values 1
                }
	    }

	    # and let's fill in the zeros at the end up to the precision
	    if { $i == 3 } {
		if { ![string equal $value ""] } {
                    set have_values 1
                }
		set fractional_part_format [lindex $format 3]
		for { set j [string length $value] } { $j < $fractional_part_format } { set j [expr $j + 1] } {
		    append $value 0
		}
	    }

	    lappend the_amount $value

	} else {
            lappend the_amount ""
        }
    }

    lappend the_amount [ns_queryget $element_id.format]

    ns_log Notice "The amount: $the_amount length: [llength $the_amount]"

    if { $have_values } {
	return [list $the_amount]
    } else {
	return [list]
    }
}

ad_proc -public template::util::currency::set_property { what currency_list value } {

    # There's no internal error checking, just like the date version ...

    # Erase leading zeroes from the value, but make sure that 00
    # is not completely erased
    set value [template::util::leadingTrim $value]

    set format [lindex $currency_list 5]

    switch $what {
        sql_number {

            if { [empty_string_p $value]} {
                return ""
            }

            foreach {whole_part fractional_part} [split $value "."] {
                # Make sure we have at least one leading digit, i.e. zero
                set whole_part "[string range "0" [string length $whole_part] end]$whole_part"

                # Chop off trailing digits beyond those called for by the given format
                set fractional_part "[string range $fractional_part 0 [expr {[lindex $format 3] - 1}]]"
            }
            set new_value [lreplace $currency_list 1 1 $whole_part]
            return [lreplace $new_value 3 3 $fractional_part]
        }
    }
}

ad_proc -public template::util::currency::get_property { what currency_list } {

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

            if { [empty_string_p $whole_part] && [empty_string_p $fractional_part] } {
                return ""
            }

            # Make sure we have at least one leading digit, i.e. zero
            set whole_part "[string range "0" [string length $whole_part] end]$whole_part"

            # Pad out the fractional part with enough leading zeros to satisfy the format
            set fractional_part "[string range [string repeat "0" [lindex $format 3]] [string length $fractional_part] end]$fractional_part"
            return ${whole_part}.${fractional_part}
        }
        display_currency {

            if { [empty_string_p $whole_part] && [empty_string_p $fractional_part] } {
                return ""
            }

            # Make sure we have at least one leading digit, i.e. zero
            set whole_part "[string range "0" [string length $whole_part] end]$whole_part"

            # Pad out the fractional part with enough leading zeros to satisfy the format
            set fractional_part "[string range [string repeat "0" [lindex $format 3]] [string length $fractional_part] end]$fractional_part"

            # Glom everything into one pretty picture
            return "$leading_symbol$whole_part$separator$fractional_part$trailing_money"
        }
    }
}

ad_proc -public template::widget::currency { element_reference tag_attributes } {

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
	if { $i == 0 || $i == 2 || $i == 4 } {
	    append output "$format_property <input type=\"hidden\" name=\"$element(name).$i\" value=\"$format_property\" />\n"
	} elseif { $i == 1 || $i == 3 } {
	    append output "<input type=\"text\" name=\"$element(name).$i\" maxlength=\"$format_property\" size=\"$format_property\" value=\"$value\" />\n"
	}
	incr i
    }
    append output "<input type=\"hidden\" name=\"$element(name).format\" value=\"$element(format)\" />\n"

    return $output
}

