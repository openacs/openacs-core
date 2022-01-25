ad_library {
    Datatype validation for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)

    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


namespace eval template {}
namespace eval template::data {}
namespace eval template::data::validate {}
namespace eval template::data::transform {}

ad_proc -public template::data::validate { type value_ref message_ref } {
    This proc invokes the validation code for a given type.

    @see template::data::validate::boolean
    @see template::data::validate::date
    @see template::data::validate::email
    @see template::data::validate::enumeration
    @see template::data::validate::filename
    @see template::data::validate::float
    @see template::data::validate::integer
    @see template::data::validate::keyword
    @see template::data::validate::naturalnum
    @see template::data::validate::number
    @see template::data::validate::search
    @see template::data::validate::string
    @see template::data::validate::text
    @see template::data::validate::textdate
    @see template::data::validate::timestamp
    @see template::data::validate::time_of_day
    @see template::data::validate::url
    @see template::data::validate::oneof
} {
    if {![validate::widget $value_ref $message_ref]} {
        return 0
    } else {
        return [validate::$type $value_ref $message_ref]
    }
}

ad_proc -private template::data::validate::widget { value_ref message_ref } {
    Here we perform the widget-specific validation, which does not
    depend on the datatype itself, but rather on the widget logics.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {
    upvar 2 \
        $message_ref message \
        $value_ref value \
        element element

    if {[info exists element(options)]} {
        # Make sure widgets that are meant to pick an option from a
        # restricted list of values, actually allow only those values.
        set valid_p false
        foreach o $element(options) {
            lassign $o option_label option_value
            if {$value eq $option_value} {
                set valid_p true
            }
        }
        if {!$valid_p} {
            set message [_ acs-templating.Invalid_choice]
            return 0
        }
    }

    return 1
}

ad_proc -public template::data::validate::integer {
    value_ref
    message_ref
} {
    Validate that a submitted integer contains only an optional sign and
    the digits 0-9.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    set result [regexp {^[+-]?\d+$} $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_integer] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::naturalnum {
    value_ref
    message_ref
} {
    Validates natural numbers data types.

    Will trim leading 0 in order to avoid Tcl interpreting it as octal (code borrowed
    from ad_page_contract_filter_proc_naturalnum)

    @author Rocael Hernandez <roc@viaro.net>

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {
    upvar 2 $message_ref message $value_ref value

    set result [regexp {^(0*)(([1-9][0-9]*|0))$} $value match zeros value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_natural_number] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::float {
    value_ref
    message_ref
} {
    Validate that a submitted fla contains only an optional sign, and a whole part
    and fractional part.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    # Not allowing for scientific notation. Would the databases swallow it?
    set result [regexp {^([+-]?)(?=\d|\.\d)\d*(\.\d*)?$} $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_decimal_number] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::boolean {
    value_ref
    message_ref
} {
    Validates boolean data types.

    @author Roberto Mello <rmello at fslc.usu.edu>

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    set result ""
    set value [::string tolower $value]

    switch -- $value {
        0 -
        1 -
        f -
        t -
        n -
        y -
        no -
        yes -
        false -
        true {
            set result 1
        }
        default {
            set result 0
            set message "[_ acs-templating.Invalid_choice] \"[ns_quotehtml $value]\""
        }
    }

    return $result
}

ad_proc -public template::data::validate::text {
    value_ref
    message_ref
} {
    Validate that submitted text is valid.  Hmmm ... all submitted text is valid,
    that's easy!

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1)
} {
    return 1
}

ad_proc -public template::data::validate::string {
    value_ref
    message_ref
} {
    Validate that a submitted string is valid.  Hmmm ... all submitted strings are valid,
    that's easy!

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1)
} {
    return 1
}

ad_proc -public template::data::validate::keyword {
    value_ref
    message_ref
} {
    Validate that a submitted keyword consists of alphnumeric or "_" characters.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    set result [regexp {^[a-zA-Z0-9_]+$} $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_keyword] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::filename {
    value_ref
    message_ref
} {
    Validate that a submitted filename consists of alphanumeric, "_", or
    "-" characters.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    set result [regexp {^[a-zA-Z0-9_-]+$} $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_filename] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::email {
    value_ref
    message_ref
} {
    Validate that a submitted email address is syntactically correct.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    set result [util_email_valid_p $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_email_format] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::url {
    value_ref
    message_ref
} {
    Validate that a submitted url is correct.  Accepts an optional http:// or
    https:// prefix, path, and query string.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    set result [util_url_valid_p -relative $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_url] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::url_element {
    value_ref
    message_ref
} {

    Beautiful URL elements that may only contain lowercase
    characters, numbers and hyphens.

    <p>


    @see util_text_to_url if you want to offer auto-generation of URLs based on a pretty name

    @author Tilmann Singer

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {
    upvar 2 $message_ref message $value_ref value

    set expr {^[a-z0-9-]+$}
    set result [regexp $expr $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_url_element [list value [ns_quotehtml $value]]]"
    }

    return $result
}

ad_proc -public template::data::validate::date {
    value_ref
    message_ref
} {
    Validate that a submitted date conforms to the template system's notion
    of what a date should be.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    return [template::util::date::validate $value message]
}

ad_proc -public template::data::validate::timestamp {
    value_ref
    message_ref
} {
    Validate that a submitted date conforms to the template system's notion
    of what a date should be.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    return [template::util::date::validate $value message]
}

ad_proc -public template::data::validate::textdate {
    value_ref
    message_ref
} {
    Validate that a submitted textdate if properly formatted.

    @param value_ref Reference variable to the submitted value.
    @param message_ref Reference variable for returning an error message.

    @return True (1) if valid, false (0) if not.
} {

    upvar 2 $message_ref message $value_ref textdate

    set error_msg [list]
    if { [info exists textdate] && $textdate ne "" } {
        if { [regexp {^[0-9]{4}-[0-9]{2}-[0-9]{2}$} $textdate match] } {
            if { [catch { clock scan -format {%Y-%m-%d} "${textdate}" }] } {
                # the textdate is formatted properly the template::data::transform::textdate proc
                # will only return correctly formatted dates in iso format, but the date is not
                # valid so they have entered some info incorrectly
                set datelist [split $textdate "-"]
                set year  [lindex $datelist 0]
                set month [::string trimleft [lindex $datelist 1] 0]
                set day   [::string trimleft [lindex $datelist 2] 0]
                if { $month < 1 || $month > 12 } {
                    lappend error_msg [_ acs-templating.Month_must_be_between_1_and_12]
                } else {
                    set maxdays [template::util::date::get_property days_in_month $datelist]
                    if { $day < 1 || $day > $maxdays } {
                        set month_pretty [template::util::date::get_property long_month_name $datelist]
                        if { $month == 2 } {
                            # February has a different number of days depending on the year
                            append month_pretty " ${year}"
                        }
                        lappend error_msg [_ acs-templating.lt_day_between_for_month_pretty]
                    }
                }
            }
        } else {
            # the textdate is not formatted properly
            set format [::string toupper [template::util::textdate_localized_format]]
            lappend error_msg [_ acs-templating.lt_Dates_must_be_formatted_]
        }
    }
    if { [llength $error_msg] > 0 } {
        set message [join $error_msg {<br>}]
        return 0
    } else {
        return 1
    }
}


ad_proc -public template::data::validate::search {
    value_ref
    message_ref
} {
    It was necessary to declare a datatype of "search" in order for the
    transformation to be applied correctly.  In reality, the transformation
    should be on the element, not on the datatype.

    DRB: in practice a template form datatype is defined by the presence of a
    validate procedure for that type.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1)
} {
    return 1
}

ad_proc -public template::data::transform {
    type
    value_ref
} {
    Dispatch procedure for the transform method.  "transformation" in template
    systemspeak means to convert the submitted data to the custom datatype structure,
    usually a list for complex datatypes, just the value for simple datatypes.  The
    transform method is called after the datatype is validated.

    @param type The data type to be transformed.
} {

    set proc_name [namespace which ::template::data::transform::$type]
    if { $proc_name ne {} } {
        transform::$type $value_ref
    }
}

ad_proc -public template::data::validate::number {
    value_ref
    message_ref
} {
    Validate number - any float - should be any rational number?

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    # Not allowing for scientific notation. Would the databases swallow it?
    set result [regexp {^([+-]?)(?=\d|\.\d)\d*(\.\d*)?$} $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_number] \"[ns_quotehtml $value]\""
    }

    return $result
}

ad_proc -public template::data::validate::enumeration {
    value_ref
    message_ref
} {
    Validate enumeration as a unique csv alphanum list.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    # alphanumeric csv
    set result [regexp {^([A-z0-9]+,?)+$} $value]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_enumeration] \"[ns_quotehtml $value]\""
        return $result
    }

    # unique list
    set list [split $value ,]
    set result [expr {[llength $list] == [llength [lsort -unique $list]]}]

    if { ! $result } {
        set message "[_ acs-templating.Invalid_enumeration_duplicate_elements [list value [ns_quotehtml $value]]]"
    }

    return $result
}

ad_proc -public template::data::validate::time_of_day {
    value_ref
    message_ref
} {
    Validate time of day.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value

    return [template::util::date::validate $value message]
}

ad_proc -public template::data::validate::oneof {
    value_ref
    message_ref
} {
    Checks whether the submitted value is contained in the list of values provided via
    the "-options" parameter of "::template::element::create". If it is set an
    error is thrown.

    @param value_ref Reference variable to the submitted value
    @param message_ref Reference variable for returning an error message

    @see template::element::create

    @return True (1) if valid, false (0) if not
} {

    upvar 2 $message_ref message $value_ref value element element values values

    # Note: Parameter "-options" is a list containing two-element lists
    # in the form { {label value} {label value} {label value} ...}
    if {[info exists element(options)] } {
        if {[lsearch -index 1 $element(options) $value] == -1} {

            set message "[_ acs-templating.Invalid_choice] \"[ns_quotehtml $value]\""
            return 0
        }
    } else {
        error "template::element::validate::oneof: No options specified for \
           element $element_id in form $form_id"
    }

    return 1
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
