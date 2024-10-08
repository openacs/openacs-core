ad_library {
    Date widgets for the ArsDigita Templating System

    @author Stanislav Freidin (sfreidin@arsdigita.com)
    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html


# Prepare an array to map symbolic month names to their indices

namespace eval template {}
namespace eval template::data {}
namespace eval template::data::validate {}
namespace eval template::util {}
namespace eval template::util::time_of_day {}
namespace eval template::util::timestamp {}
namespace eval template::util::date {}
namespace eval template::util::textdate {}
namespace eval template::widget {}
namespace eval template::data::transform {}
namespace eval template::data::to_sql {}
namespace eval template::data::from_sql {}

ad_proc -public template::util::date {
    command
    args
} {
    Dispatch procedure for the date object
} {
    template::util::date::$command {*}$args
}

ad_proc -public template::util::date::init {} {
    Sets up some initial variables and other conditions to facilitate
    the data structure template::util::date working properly and
    completely.
} {
    variable month_data
    variable fragment_widgets
    variable fragment_formats
    variable token_exp

    array set month_data {
        1 {January Jan 31}
        2 {February Feb 28}
        3 {March Mar 31}
        4 {April Apr 30}
        5 {May May 31}
        6 {June Jun 30}
        7 {July Jul 31}
        8 {August Aug 31}
        9 {September Sep 30}
        10 {October Oct 31}
        11 {November Nov 30}
        12 {December Dec 31}
    }

    # Forward lookup

    # Bug# 1176
    array set fragment_widgets \
        [list \
             YYYY [list dateFragment year 4 [_ acs-templating.Year]] \
             YY [list dateFragment short_year 2 [_ acs-templating.Year]] \
             MM [list dateFragment month 2 [_ acs-templating.Month]] \
             MON [list monthFragment month short [_ acs-templating.Month]] \
             MONTH [list monthFragment month long [_ acs-templating.Month]] \
             DD [list dateFragment day 2 [_ acs-templating.Day]] \
             HH12 [list dateFragment short_hours 2 [_ acs-templating.12-Hour]] \
             HH24 [list dateFragment hours 2 [_ acs-templating.24-Hour]] \
             MI [list dateFragment minutes 2 [_ acs-templating.Minutes]] \
             SS [list dateFragment seconds 2 [_ acs-templating.Seconds]] \
             AM [list ampmFragment ampm 2 [_ acs-templating.Meridian]] \
            ]

    # Reverse lookup
    foreach key [array names fragment_widgets] {
        set fragment_formats([lindex $fragment_widgets($key) 1]) $key
    }

    # Expression to match any valid format token
    set token_exp "([join [array names fragment_widgets] |])(t*)"
}

ad_proc -public template::util::date::monthName {
    month
    length
} {
    Return the specified month name (short or long)
} {
    # trim leading zeros to avoid octal problem
    set month [util::trim_leading_zeros $month]
    if {$length eq "long"} {
        return [lc_time_fmt "2002-[format "%02d" $month]-01" "%B"]
    } else {
        return [lc_time_fmt "2002-[format "%02d" $month]-01" "%b"]
    }
}

ad_proc -public template::util::date::daysInMonth {
    month
    {year 0}
} {
    @param year an integer representing the number of the year in the
                Gregorian calendar.

    @return the number of days in a month, accounting for leap years.

    @see https://en.wikipedia.org/wiki/Leap_year#Algorithm
} {
    # Something like this oneliner might work and delegate the leap
    # year calculation to the clock command. However, it would be
    # significantly slower...
    # clock format [clock add [clock scan [format "%04d" $year]-[format "%02d" $month]-01 -format %Y-%m-%d] 1 month -1 day] -format %d

    set month [string trimleft $month 0]
    set year [string trimleft $year 0]
    if {$year eq ""} {set year 0}

    variable month_data
    set month_desc $month_data($month)
    set days [lindex $month_desc 2]

    if { $month == 2
         && ( (($year % 4) == 0 && ($year % 100) != 0) ||
              (($year % 400) == 0) )
     } {
        return [expr {$days + 1}]
    } else {
        return $days
    }
}

ad_proc -public template::util::date::create {
    {year {}}
    {month {}}
    {day {}}
    {hours {}}
    {minutes {}}
    {seconds {}}
    {format "DD MONTH YYYY"}
} {
    Create a new Date object. This is defined as a list of 7 elements,
    respectively representing year, month, day, hours, minutes,
    seconds and format.
} {
    return [list $year $month $day $hours $minutes $seconds $format]
}

ad_proc -public template::util::date::acquire {
    type
    {value ""}
} {
    Create a new date with some predefined value.  Basically, create
    and set the date.
} {
    set the_date [template::util::date::create]
    return [template::util::date::set_property $type $the_date $value]
}

ad_proc -public template::util::date::today {} {
    Create a new Date object for the current date.
} {
    set now [clock format [clock seconds] -format "%Y %m %d"]
    set today [list]

    foreach v $now {
        # trim leading zeros to avoid octal problem
        lappend today [util::trim_leading_zeros $v]
    }

    return [create {*}$today]
}

ad_proc -public template::util::date::now {} {
    Create a new Date object for the current date and time.
} {
    set now [clock format [clock seconds] -format "%Y %m %d %H %M %S"]
    set today [list]

    foreach v $now {
        lappend today [util::trim_leading_zeros $v]
    }

    return [create {*}$today]
}

ad_proc -public template::util::date::from_ansi {
    ansi_date
    {format "YYYY MM DD"}
} {
    Create a new templating system date structure from a full ANSI
    date, i.e. in the format YYYY-MM-DD HH24:MI:SS.

    @param ansi_date Date in full ANSI format YYYY-MM-DD HH24:MI:SS
                     (time portion is optional).
    @param format Format for the date object. Optional, defaults to
                  YYYY MM DD.

    @return Date object for use with e.g. form builder.
    @author Lars Pind (lars@pinds.com)
    @creation-date November 18, 2002
} {
    set date [template::util::date::create]
    set date [template::util::date::set_property format $date $format]
    set date [template::util::date::set_property ansi $date $ansi_date]
    return $date
}

ad_proc -public template::util::date::get_property {
    what
    date
} {

    Returns a property of a date list, usually created by ad_form.

    @param what the name of the property. One of:<ul>
    <li>year</li>
    <li>month</li>
    <li>day</li>
    <li>hours</li>
    <li>minutes</li>
    <li>seconds</li>
    <li>format</li>
    <li>long_month_name</li>
    <li>short_month_name</li>
    <li>days_in_month</li>
    <li>short_year</li>
    <li>short_hours</li>
    <li>ampm</li>
    <li>not_null</li>
    <li>sql_date</li>
    <li>linear_date</li>
    <li>linear_date_no_time</li>
    <li>display_date</li>
    <li>clock</li>
    </ul>
    @param date the date widget list
} {
    variable month_data

    switch -- $what {
        year       { return [lindex $date 0] }
        month      { return [lindex $date 1] }
        day        { return [lindex $date 2] }
        hours      { return [lindex $date 3] }
        minutes    { return [lindex $date 4] }
        seconds    { return [lindex $date 5] }
        format     { return [lindex $date 6] }
        long_month_name {
            if {[lindex $date 1] eq ""} {
                return {}
            } else {
                return [monthName [lindex $date 1] long]
            }
        }
        short_month_name {
            if {[lindex $date 1] eq ""} {
                return {}
            } else {
                return [monthName [lindex $date 1] short]
            }
        }
        days_in_month {
            if { [lindex $date 1] eq "" || [lindex $date 0] eq "" } {
                return 31
            } else {
                return [daysInMonth [lindex $date 1] [lindex $date 0]]
            }
        }
        short_year {
            if {[lindex $date 0] eq ""} {
                return {}
            } else {
                return [expr {[lindex $date 0] % 100}]
            }
        }
        short_hours {
            if {[lindex $date 3] eq ""} {
                return {}
            } else {
                set value [expr {[lindex $date 3] % 12}]
                if { $value == 0 } {
                    return 12
                } else {
                    return $value
                }
            }
        }
        ampm {
            if {[lindex $date 3] eq ""} {
                return {}
            } else {
                if { [lindex $date 3] > 11 } {
                    return "pm"
                } else {
                    return "am"
                }
            }
        }
        not_null {
            for { set i 0 } { $i < 6 } { incr i } {
                if { [lindex $date $i] ne {} } {
                    return 1
                }
            }
            return 0
        }
        sql_date -
        sql_timestamp {
            # LARS: Empty date results in NULL value
            if { $date eq "" } {
                return "NULL"
            }
            set value ""
            set format ""
            set space ""
            set pad "0000"
            foreach { index sql_form } { 0 YYYY 1 MM 2 DD 3 HH24 4 MI 5 SS } {
                set piece [lindex $date $index]
                if { $piece ne {} } {
                    append value "$space[string range $pad [string length $piece] end]$piece"
                    append format $space
                    append format $sql_form
                    set space " "
                }
                set pad "00"
            }
            # DRB: We need to differentiate between date and timestamp, for PG, at least,
            # and since Oracle supports to_timestamp() we'll just do it for both DBs.
            # DEDS: revert this first as to_timestamp is only for
            # oracle9i. no clear announcement that OpenACS has dropped
            # support for 8i
            if { [llength $date] <= 3 || ([db_type] eq "oracle" && [string match "8.*" [db_version]]) } {
                return "to_date('$value', '$format')"
            } else {
                return "to_timestamp('$value', '$format')"
            }
        }
        ansi {
            # LARS: Empty date results in NULL value
            if { $date eq "" } {
                return {}
            }
            set value ""
            set pad "0000"
            set prepend ""
            set clipped_date [lrange $date 0 2]
            foreach fragment $clipped_date {
                append value "$prepend[string range $pad [string length $fragment] end]$fragment"
                set pad "00"
                set prepend "-"
            }
            append value " "
            set prepend ""
            set clipped_time [lrange $date 3 5]
            foreach fragment $clipped_time {
                append value "$prepend[string range $pad [string length $fragment] end]$fragment"
                set prepend ":"
            }
            return $value
        }
        linear_date {
            # Return a date in format "YYYY MM DD HH24 MI SS"
            # For use with karl's non-working form builder API
            set clipped_date [lrange $date 0 5]
            set ret [list]
            set pad "0000"
            foreach fragment $clipped_date {
                lappend ret "[string range $pad [string length $fragment] end]$fragment"
                set pad "00"
            }
            return $ret
        }
        linear_date_no_time {
            # Return a date in format "YYYY MM DD"
            set clipped_date [lrange $date 0 2]
            set ret [list]
            set pad "0000"
            foreach fragment $clipped_date {
                lappend ret "[string range $pad [string length $fragment] end]$fragment"
                set pad "00"
            }
            return $ret
        }
        display_date {

            # Return a beautified date.  It should use the widget format string but DRB
            # doesn't have the time to dive into that today.  The simple hack would be
            # to use the database's to_char() function to do the conversion but that's
            # not a terribly efficient thing to do.

            set clipped_date [lrange $date 0 2]
            set date_list [list]
            set pad "0000"
            foreach fragment $clipped_date {
                lappend date_list "[string range $pad [string length $fragment] end]$fragment"
                set pad "00"
            }
            set value [lc_time_fmt [join $date_list "-"] "%q"]
            unpack $date
            if { $hours ne "" && $minutes ne "" } {
                append value " [string range $pad [string length $hours] end]${hours}:[string range $pad [string length $minutes] end]$minutes"
                if { $seconds ne {} } {
                    append value ":[string range $pad [string length $seconds] end]$seconds"
                }
            }
            return $value
        }
        clock {
            set value ""
            # Unreliable !
            unpack $date
            if { $year ne "" && $month ne "" && $day ne "" } {
                append value "$month/$day/$year"
            }
            if { $hours ne "" && $minutes ne "" } {
                append value " ${hours}:${minutes}"
                if { $seconds ne "" } {
                    append value ":$seconds"
                }
            }
            return [clock scan $value]
        }
        default {
            error "util::date::get_property: unknown property: '$what'."
        }
    }
}

ad_proc -public template::util::date::compare {
    date1
    date2
} {
    Perform date comparison; same syntax as string compare.
} {
    for { set i 0 } { $i < 5 } { incr i } {
        if { [lindex $date1 $i] < [lindex $date2 $i] } {
            return -1
        } elseif { [lindex $date1 $i] > [lindex $date2 $i] } {
            return 1
        }
    }
    return 0
}

ad_proc -public template::util::date::set_property {
    what
    date
    value
} {

    Replace a property in a list created by a date widget.

    @param what name of the property (see source for allowed values)
    @param date the date list
    @param value the new value

    @return the modified list

} {

    # if value is an empty string, just return the date that was
    # passed in, otherwise this procedure will fail.
    # This is needed for the automated sql/linear conversion used by
    # ad_form.

    if {$value eq ""} {
        return $date
    }

    # This trimming is actually more of a noop, as one should actually
    # switch on the 'what' variable, expected to match one of the
    # keys, while 'value' will just be a date. The probable typo is 18
    # years old, so I am commenting out the code, rather than "fixing
    # it", with possible unexpected consequences. Might go away for
    # good at some point.
    # # Erase leading zeros from the value, but make sure that 00
    # # is not completely erased - but only for single-element properties
    #
    # switch -- $value {
    #     year - month - day - hour - minutes - seconds - short_year - short_hours - ampm {
    #         set value [util::trim_leading_zeros $value]
    #     }
    # }

    switch -- $what {
        year       { return [lreplace $date 0 0 $value] }
        month      { return [lreplace $date 1 1 $value] }
        day        { return [lreplace $date 2 2 $value] }
        hours      { return [lreplace $date 3 3 $value] }
        minutes    { return [lreplace $date 4 4 $value] }
        seconds    { return [lreplace $date 5 5 $value] }
        format     { return [lreplace $date 6 6 $value] }
        short_year {
            if { $value < 69 } {
                return [lreplace $date 0 0 [expr {$value + 2000}]]
            } else {
                return [lreplace $date 0 0 [expr {$value + 1900}]]
            }
        }
        short_hours {
            return [lreplace $date 3 3 $value]
        }
        ampm {
            if {[lindex $date 3] eq ""} {
                return $date
            } else {
                set hours [lindex $date 3]

                # robustness check: make sure we handle form of 08:00am  --jfr
                if {[regexp {0([0-9])} $hours match trimmed_hours]} {
                    if {$trimmed_hours ne ""} {
                        set hours $trimmed_hours
                    }
                }

                if { $value eq "pm" && $hours < 12 } {
                    return [lreplace $date 3 3 [expr {$hours + 12}]]
                } elseif {$value eq "am"} {
                    return [lreplace $date 3 3 [expr {$hours % 12}]]
                } else {
                    return $date
                }
            }
        }
        clock {
            set old_date [clock format $value -format "%Y %m %d %H %M %S"]
            set new_date [list]
            foreach field $old_date {
                lappend new_date [util::trim_leading_zeros $field]
            }
            lappend new_date [lindex $date 6]
            return $new_date
        }
        sql_date {
            set old_format [lindex $date 6]
            set new_date [list]
            foreach fragment $value {
                lappend new_date [util::trim_leading_zeros $fragment]
            }
            lappend new_date $old_format
            return $new_date
        }
        ansi {
            # Some initialization...
            # Rip $date into $ansi_* as numbers, no leading zeros
            set matchdate {([0-9]{4})\-0?(1?[0-9])\-0?([1-3]?[0-9])}
            set matchtime {0?([1-2]?[0-9]):0?([1-5]?[0-9]):0?([1-6]?[0-9])}
            set matchfull "$matchdate $matchtime"

            set time_p 1
            if {![regexp -- $matchfull $value match ansi_year ansi_month ansi_days ansi_hours ansi_minutes ansi_seconds]} {
                if {[regexp -- $matchdate $value match ansi_year ansi_month ansi_days]} {
                    set ansi_hours 0
                    set ansi_minutes 0
                    set ansi_seconds 0
                } else {
                    error "Invalid date: $value"
                }
            }
            # Return new date, but use old format
            return [list $ansi_year $ansi_month $ansi_days $ansi_hours $ansi_minutes $ansi_seconds [lindex $date 6]]
        }
        now {
            return [template::util::date set_property clock $date [clock seconds]]
        }
        default {
            error "util::date::set_property: unknown property: '$what'."
        }
    }

}

ad_proc -public template::util::date::defaultInterval {
    what
} {
    Get the default ranges for all the numeric fields of a Date object
} {
    switch -- $what {
        year        { return [list 2002 2012 1 ] }
        month       { return [list 1 12 1] }
        day         { return [list 1 31 1] }
        hours       { return [list 0 23 1] }
        minutes     { return [list 0 59 5] }
        seconds     { return [list 0 59 5] }
        short_year  { return [list 0 10 1] }
        short_hours { return [list 1 12 1] }
    }
}

ad_proc -public template::util::date::unpack {
    date
} {
    Set the variables for each field of the date object in
    the calling frame.

    sets: year month day hours minutes seconds format from a list formatted date string

    @see template::util::date::from_ans
} {
    uplevel [list lassign $date year month day hours minutes seconds format]
}

ad_proc -public template::util::date::now_min_interval {
    {-clock ""}
} {
    Create a new Date object for the current date and time
    with the default interval for minutes

    @param clock time in seconds, if not specified, it uses current time

    @author Walter McGinnis (wtem@olywa.net)
    @creation-date 2002-01-06
} {
    if {$clock eq ""} {
        set clock  [clock seconds]
    }

    set now [list]
    foreach v [clock format $clock -format "%Y %m %d %H %M %S"] {
        lappend now [util::trim_leading_zeros $v]
    }
    #
    # Get original minute value
    #
    set minute [lindex $now 4]

    #
    # Get interval definition for "minute" (e.g. 0 59 5)
    #
    lassign [defaultInterval minutes] min max interval

    for { set i $min } { $i <= $max } { incr i $interval } {
        if {$minute == $i} {
            break
        } elseif {$minute < $i} {
            set minute $i
            break
        }
    }
    #
    # Replace the minute value in the now list with new value
    #
    lset now 4 $minute

    return [create {*}$now]
}

ad_proc -deprecated -public template::util::date::now_min_interval_plus_hour {
    {-clock ""}
} {
    Create a new Date object for the current date and time plus one
    hour with the default interval for minutes.

    @param clock time in seconds, if not specified, it uses current time

    Deprecated: as of 2019-04-25, no upstream code is making use of
    this proc and more generic alternatives exist.

    @see template::data::from_sql::date
    @see clock

    @author Walter McGinnis (wtem@olywa.net)
    @creation-date 2002-01-06
} {
    if {$clock eq ""} {
        set clock [clock seconds]
    }
    #
    # Add one hour to the clock
    #
    incr clock [expr {60*60}]

    set now [list]
    foreach v [clock format $clock -format "%Y %m %d %H %M %S"] {
        lappend now [util::trim_leading_zeros $v]
    }

    # manipulate the minute value so it rounds up to nearest minute interval
    set minute [lindex $now 4]
    # there is a definition for minute interval: 0 59 5
    lassign [defaultInterval minutes] min max inc
    for {set i $min} {$i <= $max} {incr i $inc} {
        if {$minute == $i} {
            break
        } elseif {$minute < $i} {
            set minute $i
            break
        }
    }

    return [create {*}$now]
}

ad_proc -public template::util::date::add_time {
    -time_array_name:required
    -date_array_name:required
} {
    Set the time and date and new format properties into one date
    object (list) which is returned.

    Not sure this proc should live here...

    @author Walter McGinnis (wtem@olywa.net)
    @creation-date 2002-01-04
} {
    # grab the form arrays
    upvar 1 $time_array_name time_in $date_array_name date_in

    # combine the two formats...
    # date first
    set new_format "$date_in(format) $time_in(format)"

    # create an empty date object with the new format
    set the_date [template::util::date::create \
                      "" "" "" "" "" "" ""]

    set the_date [template::util::date::set_property format $the_date $new_format]

    set have_values 0

    # the following two foreachs might be cleaner if combined into one
    # but two is pretty simple and there are larger battles out there to fight

    # add time properties
    foreach field [array names time_in] {
        # skip format
        if {$field ne "format" } {
            # Coerce values to nonnegative integers
            if { $field ne "ampm" } {
                if { ![regexp {[0-9]+} $time_in($field) value] } {
                    set value {}
                }
            }
            # If the value is not null, set it
            if { $value ne {} } {
                set the_date [template::util::date::set_property $field $the_date $value]
                if { $field ne "ampm" } {
                    set have_values 1
                }
            }
        }
    }

    # add date properties
    foreach field [array names date_in] {
        # skip format
        if {$field ne "format" } {
            # Coerce values to nonnegative integers
            if { ![regexp {[0-9]+} $date_in($field) value] } {
                set value {}
            }
            # If the value is not null, set it
            if { $value ne {} } {
                set the_date [template::util::date::set_property $field $the_date $value]
                set have_values 1
            }
        }
    }

    if { $have_values } {
        return [list $the_date]
    } else {
        return {}
    }
}

ad_proc -public template::util::negative {
    value
} {
    Check if a value is less than zero, but return false if the value
    is an empty string.
} {
    if {$value eq ""} {
        return 0
    } else {
        return [expr {[util::trim_leading_zeros $value] < 0}]
    }
}

ad_proc -public template::util::date::validate {
    date
    error_ref
} {
    Validate a date object.

    @return 1 if the object is valid, 0 otherwise. Set the error_ref
            variable to contain an error message, if any.
} {
    # If the date is empty, it's valid
    if { ![get_property not_null $date] } {
        return 1
    }

    variable fragment_formats
    upvar $error_ref error_msg

    unpack $date

    set error_msg [list]

    foreach {field exp} {
        year "YYYY|YY"
        month "MM|MON|MONTH"
        day "DD"
        hours "HH24|HH12"
        minutes "MI"
        seconds "SS"
    } {
        # Trim leading zeros to avoid numbers being interpreted as
        # octals when comparing them.
        set $field [util::trim_leading_zeros [set $field]]

        # If the field is required, but missing, report an error
        if {[set $field] eq ""} {
            if { [regexp $exp $format match] } {
                set field_pretty [_ acs-templating.${field}]
                lappend error_msg [_ acs-templating.lt_No_value_supplied_for_-field_pretty-]
            }
        } else {
            # fields should only be integers
            if { ![regexp {^[0-9]+$} [set $field] match] } {
                set field_pretty [_ acs-templating.${field}]
                lappend error_msg [_ acs-templating.lt_The_-field_pretty-_must_be_non_negative]
                set $field {}
            }
        }
    }

    if { $year ne {} && ($year < 1 || $year > 9999)} {
        lappend error_msg [_ acs-templating.Year_must_be_between_1_and_9999]
    }

    if { $month ne {} } {
        if { $month < 1 || $month > 12 } {
            lappend error_msg [_ acs-templating.Month_must_be_between_1_and_12]
        } elseif { $year > 0 && $day ne {} } {
            set maxdays [get_property days_in_month $date]
            if { $day < 1 || $day > $maxdays } {
                set month_pretty [template::util::date::get_property long_month_name $date]
                if { $month == 2 } {
                    # February has a different number of days depending on the year
                    append month_pretty " ${year}"
                }
                lappend error_msg [_ acs-templating.lt_day_between_for_month_pretty]
            }
        }
    }

    if { $hours ne {} && ($hours < 0 || $hours > 23) } {
        lappend error_msg [_ acs-templating.Hours_must_be_between_0_and_23]
    }

    if { $minutes ne {} && ($minutes < 0 || $minutes > 59) } {
        lappend error_msg [_ acs-templating.Minutes_must_be_between_0_and_59]
    }

    if { $seconds ne {} && ($seconds < 0 || $seconds > 59) } {
        lappend error_msg [_ acs-templating.Seconds_must_be_between_0_and_59]
    }

    if { [llength $error_msg] > 0 } {
        set error_msg "[join $error_msg {<br>}]"
        return 0
    } else {
        return 1
    }
}

ad_proc -public -deprecated template::util::leadingPad {
    string
    size
} {
    Pad a string with leading zeros

    Deprecated: please use the new and more general 'ad_pad'.

    @see ad_pad
} {
    if {$string eq ""} {
        return ""
    }

    set ret [string repeat "0" [expr {$size - [string length $string]}]]
    append ret $string
    return $ret
}

ad_proc -public -deprecated template::util::leadingTrim {
    value
} {
    Trim the leading zeros from the value, but preserve the value
    as "0" if it is "00"

    @see util::trim_leading_zeros
} {
    return [util::trim_leading_zeros $value]
}

ad_proc -public template::widget::numericrange {
    element_reference
    tag_attributes
} {
    Widget proc usable with ad_form to display a numeric range widget.

    Need to define interval_def as {interval_def {start end step}}
} {
    upvar $element_reference element

    if { [info exists element(html)] } {
        array set attributes $element(html)
    }

    return [template::widget::numericRange $element(name) $element(interval_def) $element(size) $element(value) $tag_attributes]
}

ad_proc -public template::widget::numericRange {
    name
    interval_def
    size
    {value ""}
    {tag_attributes {}
    }
} {
    Create an HTML fragment to display a numeric range widget
    interval_def is in form { start stop interval }
} {
    array set attributes $tag_attributes

    set interval_size [lindex $interval_def 2]
    set options [list [list "--" {}]]

    for { set i [lindex $interval_def 0] } \
        { $i <= [lindex $interval_def 1] } \
        { incr i $interval_size } {
            lappend options [list [ad_pad -left $i $size "0"] $i]
        }

    if {$interval_size > 1} {
        # round minutes or seconds to nearest interval
        if { $value ne "" } {
            set value [expr {$value-($value - [lindex $interval_def 0])%$interval_size}]
        }
    }

    return [template::widget::menu $name $options [list $value] attributes]
}

ad_proc -public template::widget::dateFragment {
    element_reference
    fragment
    size
    type
    value
    {mode edit}
    {tag_attributes {}}
} {
    Create an input widget for the given date fragment If type is "t",
    uses a text widget for the fragment, with the given size.

    Otherwise, determines the proper widget based on the element
    flags, which may be text or a picklist.
} {
    upvar $element_reference element

    set value [template::util::date::get_property $fragment $value]
    set value [util::trim_leading_zeros $value]

    if {$value eq ""} {
        set att_value ""
    } else {
        set att_value [ad_pad -left $value $size 0]
    }

    if { $mode ne "edit" } {
        return [subst {<input type="hidden" name="$element(name).$fragment" value="${att_value}">$value}]
    } else {
        if { [info exists element(${fragment}_interval)] } {
            set interval $element(${fragment}_interval)
        } else {
            # Display text entry for some elements, or if the type is text
            if { $type == "t"
                 || [regexp "year|short_year" $fragment]
             } {
                set output "<input type=\"text\" name=\"$element(name).$fragment\" id=\"$element(name).$fragment\" size=\"$size\""
                append output " maxlength=\"$size\" value=\"${att_value}\""
                array set attributes $tag_attributes
                foreach attribute_name [array names attributes] {
                    if {$attributes($attribute_name) eq ""} {
                        append output " $attribute_name"
                    } else {
                        append output " $attribute_name=\"$attributes($attribute_name)\""
                    }
                }
                append output ">\n"
                return $output
            } else {
                # Use a default range for others
                set interval [template::util::date::defaultInterval $fragment]
            }
        }
        return [template::widget::numericRange "$element(name).$fragment" \
                    $interval $size $value $tag_attributes]
    }
}

ad_proc -public template::widget::ampmFragment {
    element_reference
    fragment
    size
    type
    value
    {mode edit}
    {tag_attributes {}}
} {
    Create a widget that shows the am/pm selection
} {
    upvar $element_reference element
    array set attributes $tag_attributes

    set value [template::util::date::get_property $fragment $value]

    if { $mode ne "edit" } {
        set output {}
        append output "<input type=\"hidden\" name=\"$element(name).$fragment\" value=\"$value\">"
        append output $value
        return $output
    } else {
        return [template::widget::menu \
                    "$element(name).$fragment" { {A.M. am} {P.M. pm}} $value attributes]
    }
}

ad_proc -public template::widget::monthFragment {
    element_reference
    fragment
    size
    type
    value
    {mode edit}
    {tag_attributes {}}
} {
    Create a month entry widget with short or long month names.
} {
    variable ::template::util::date::month_data

    upvar $element_reference element
    array set attributes $tag_attributes

    set value [template::util::date::get_property $fragment $value]

    if { $mode ne "edit" } {
        set output {}
        if { $value ne "" } {
            append output "<input type=\"hidden\" name=\"$element(name).$fragment\" value=\"$value\">"
            append output [template::util::date::monthName $value $size]
        }
        return $output
    } else {
        set options [list [list "--" {}]]
        for { set i 1 } { $i <= 12 } { incr i } {
            lappend options [list [template::util::date::monthName $i $size] $i]
        }

        return [template::widget::menu \
                    "$element(name).$fragment" $options $value attributes]
    }
}

ad_proc -public template::widget::date {
    element_reference
    tag_attributes
} {
    Create a date entry widget according to a format string The format
    string should contain the following fields, separated by / \ - :
    . or whitespace:
    <table border="1">
      <tr><th>string</th><th>meaning</th></tr>
      <tr><td>YYYY</td><td>4-digit year</td></tr>
      <tr><td>YY</td><td>2-digit year</td></tr>
      <tr><td>MM</td><td>2-digit month</td></tr>
      <tr><td>MON</td><td>month name, short (i.e. "Jan")</td></tr>
      <tr><td>MONTH</td><td>month name, long (i.e. "January")</td></tr>
      <tr><td>DD</td><td>day of month</td></tr>
      <tr><td>HH12</td><td>12-hour hour</td></tr>
      <tr><td>HH24</td><td>24-hour hour</td></tr>
      <tr><td>MI</td><td>minutes</td></tr>
      <tr><td>SS</td><td>seconds</td></tr>
      <tr><td>AM</td><td>am/pm flag</td></tr>
    </table>
    Any format field may be followed by "t", in which case a text
    widget will be used to represent the field.  the array in
    range_ref determines interval ranges; the keys are the date fields
    and the values are in form {start stop interval}
} {
    variable ::template::util::date::fragment_widgets

    upvar $element_reference element

    array set attributes \
        [::template::widget::merge_tag_attributes element $tag_attributes]

    set output "<!-- date $element(name) begin -->\n"

    if { ! [info exists element(format)] } {
        set element(format) [_ acs-lang.localization-formbuilder_date_format]
    }

    # Choose a pre-selected format, if any
    switch -- $element(format) {
        long     { set element(format) "YYYY/MM/DD HH24:MI:SS" }
        short    { set element(format) "YYYY/MM/DD"}
        time     { set element(format) "HH24:MI:SS"}
        american { set element(format) "MM/DD/YY"}
        expiration {
            set element(format) "MM/YY"
            set current_year [clock format [clock seconds] -format "%Y"]
            set current_year [expr {$current_year % 100}]
            set element(short_year_interval) \
                [list $current_year [expr {$current_year + 10}] 1]
            set element(help) 1
        }
    }

    # Just remember the format for now - in the future, allow
    # the user to enter a freeform format
    append output "<input type=\"hidden\" name=\"$element(name).format\" "
    append output "value=\"$element(format)\" >\n"

    # Prepare the value to set defaults on the form
    if { [info exists element(value)]
         && [template::util::date::get_property not_null $element(value)]
     } {
        set value $element(value)
        foreach v $value {
            lappend trim_value [util::trim_leading_zeros $v]
        }
        set value $trim_value
    } else {
        set value {}
    }

    # Keep taking tokens off the top of the string until out
    # of tokens
    set format_string $element(format)

    set tokens [list]

    if {[info exists attributes(id)]} {
        set id_attr_name $attributes(id)
    }

    while { $format_string ne {} } {

        # Snip off the next token
        regexp {([^/\-.: ]*)([/\-.: ]*)(.*)} \
            $format_string match word sep format_string
        # Extract the trailing "t", if any
        regexp -nocase $template::util::date::token_exp $word \
            match token type

        lappend tokens $token

        # Output the widget
        set fragment_def $template::util::date::fragment_widgets([string toupper $token])
        set fragment [lindex $fragment_def 1]

        if {[info exists id_attr_name] && $id_attr_name ne ""} {
            set attributes(id) "${id_attr_name}.${fragment}"
        }

        set widget [template::widget::[lindex $fragment_def 0] \
                        element \
                        $fragment \
                        [lindex $fragment_def 2] \
                        $type \
                        $value \
                        $element(mode) \
                        [array get attributes]]

        if { [info exists element(help)] } {
            append output "<label for=\"$element(id).${fragment}\">[lindex $fragment_def 3] $widget</label>"
        } else {
            append output $widget
        }

        # Output the separator
        if {$sep eq " "} {
            append output "&nbsp;"
        } else {
            append output "$sep"
        }

    }

    append output "<!-- date $element(name) end -->\n"

    return $output
}

ad_proc -public template::data::transform::date {
    element_ref
} {
    Collect a Date object from the form.
} {
    upvar $element_ref element
    set element_id $element(id)

    set the_date [template::util::date::create \
                      {} {} {} {} {} {} [ns_queryget "$element_id.format"]]
    set have_values 0

    foreach field {
        year
        short_year
        month day
        short_hours
        hours
        minutes
        seconds
        ampm
    } {
        set key "$element_id.$field"
        if { [ns_queryexists $key] } {
            set value [ns_queryget $key]
            # Coerce values to nonnegative integers
            if { $field ne "ampm" } {
                if { ![regexp {[0-9]+} $value value] } {
                    set value {}
                }
            }
            # If the value is not null, set it
            if { $value ne {} } {
                set the_date [template::util::date::set_property $field $the_date $value]
                if { $field ne "ampm" } {
                    set have_values 1
                }
            }
        }
    }

    if { $have_values } {
        return [list $the_date]
    } else {
        return {}
    }
}

ad_proc -public template::util::textdate {
    command
    args
} {
    Dispatch procedure for the textdate object
} {
    template::util::textdate::$command {*}$args
}

ad_proc -public template::util::textdate_localized_format {} {
    Gets the localized format for the textdate widget
} {
    # we get the date format for the connected locale from acs-lang.localization-d_fmt
    # as of the time of writing this proc the following were by default available that
    # would work with this proc, and this should cover most installations, if this
    # format isn't matched we will use the iso standard YYYY-MM-DD.
    #
    # %d-%m-%y  %d.%m.%y  %d/%m-%y  %d/%m/%y  %m/%d/%y  %y-%m-%d  %y.%m.%d  &quot;%d-%m-%y&quot;

    set format [lc_get "d_fmt"]
    regsub -all -nocase -- {\&quot;} $format {} format
    regsub -all -nocase -- {\%} $format {} format
    set format [string tolower $format]
    # this format key must now be at max five characters, and contain one y, one m and one d
    # as well as two punction marks ( - . / )
    if { [regexp {^([y|m|d])([\-|\.|/])([y|m|d])([\-|\.|/])([y|m|d])} $format match first first_punct second second_punct third]
         && [string length $format] == 5
     } {
        if { [lsort [list $first $second $third]] eq "d m y" } {
            # we have a valid format from acs-lang.localization-d_fmt with all 3 necessary elements
            # and only two valid punctuation marks
            regsub {d} $format {dd} format
            regsub {m} $format {mm} format
            regsub {y} $format {yyyy} format
            return $format
        }
    }

    # we use the iso standard
    return "yyyy-mm-dd"
}

ad_proc -public template::util::textdate::create {
    {textdate {}}
} {
    Build a textdate datatype structure, which is just the string
    itself for this simple type.
} {
    return $textdate
}

ad_proc -public template::data::transform::textdate {
    element_ref
} {
    Collect a textdate from the form, it automatically reformats it
    from the users locale to the ISO standard YYYY-MM-DD this is
    useful because it doesn't need reformatting in Tcl code.
} {
    upvar $element_ref element
    set element_id $element(id)
    set value [ns_queryget "$element_id"]

    if { $value eq "" } {
        # they didn't enter anything
        return ""
    }

    # we get the format they need to use
    set format [template::util::textdate_localized_format]
    set exp $format
    regsub -all -- {(\-|\.|/)} $exp {(\1)} exp
    regsub -all -- {dd|mm} $exp {([0-9]{1,2})} exp
    regsub -all -- {yyyy} $exp {([0-9]{2,4})} exp

    # results is what comes out in a regexp
    set results $format
    regsub {\-|\.|/} $results { format_one} results
    regsub {\-|\.|/} $results { format_two} results
    regsub {mm} $results { month} results
    regsub {dd} $results { day} results
    regsub {yyyy} $results { year} results
    set results [string trim $results]

    if { [regexp {([\-|\.|/])yyyy$} $format match year_punctuation] } {
        # we might be willing to accept this date if it doesn't have a year
        # at the end, since we can assume that the year is the current one
        # this is useful for fast keyboard based date entry for formats that
        # have years at the end (such as in en_US which is mm/dd/yyyy or
        # de_DE which is dd.mm.yyyy)

        # we check if adding the year and punctuation makes it a valid date
        if { [regexp $exp "${value}${year_punctuation}[dt_sysdate -format %Y]" match {*}$results] } {
            if { ![catch { clock scan "${year}-${month}-${day}" }] } {
                # we add the missing year and punctuation to the value
                # we don't return it here because formatting is done
                # later on (i.e. adding leading zeros if needed)
                append value "${year_punctuation}[dt_sysdate -format %Y]"
            }
        }
    }

    # now we verify that we have a valid date
    # and adding leading/trailing zeros if needed
    if { [regexp $exp $value match {*}$results] } {
        # the regexp will have given us: year month day format_one format_two
        if { [string length $month] eq "1" } {
            set month "0$month"
        }
        if { [string length $day] eq "1" } {
            set day "0$day"
        }
        if { [string length $year] eq "2" } {
            # we'll copy microsoft excel's default assumptions
            # about the year it is so if the year is 29 or
            # lower its in this century otherwise its last century
            if { $year < 30 } {
                set year "20$year"
            } else {
                set year "19$year"
            }
        }
        return "${year}-${month}-${day}"
    } else {
        # they did not provide a correctly formatted date so we send it back to them
        return $value
    }
}

ad_proc -public template::widget::textdate {
    element_reference
    tag_attributes
} {
    Implements the textdate widget.
} {
    upvar $element_reference element

    set date_valid_p 0
    if { [info exists element(value)] } {
        set textdate $element(value)
        if { [regexp {^([0-9]{4})-([0-9]{2})-([0-9]{2})$} $textdate match year month day] } {
            set date_valid_p [string is false [catch { clock scan "${textdate}" }]]
            # we have a correctly formatted iso date that we
            # can reformat for display, we don't use lc_time_fmt
            # because it could fail and cause a server error.
            # The date may be formatted correctly but it may be
            # an invalid date (which is caught by
            # template::data::validate::textdate) so we need to
            # re-format the input into the format the user specified
            # by this means
            set textdate [template::util::textdate_localized_format]
            regsub {yyyy} $textdate $year textdate
            regsub {mm} $textdate $month textdate
            regsub {dd} $textdate $day textdate
        }
    } else {
        set textdate ""
    }

    if { $date_valid_p } {
        set javascriptdate $textdate
    } else {
        set javascriptdate ""
    }

    if {$element(mode) eq "edit"} {
        set id $element(id)_input_field
        append output [subst {
            <input type="text" name="$element(id)" size="10" maxlength="10" id="$id" value="[ns_quotehtml $textdate]">
            <input type="button" style="border-width: 0px; height: 17px; width: 19px; background-image: url('/resources/acs-templating/calendar.gif'); background-repeat: no-repeat; cursor: pointer;" id="$id-control">
        }]

        ::template::head::add_javascript \
            -src /resources/acs-templating/calendar.js

        template::add_event_listener \
            -id $id-control \
            -script [subst {
                showCalendarWithDefault('$element(id)_input_field', '$javascriptdate', '[template::util::textdate_localized_format]');
            }]
    } else {
        append output $textdate [subst {<input type="hidden" name="$element(id)" value="[ns_quotehtml $textdate]">}]
    }

    return $output
}

# handle date transformations using a standardized naming convention.

ad_proc template::data::to_sql::date {
    value
} {
    Converts a templating date object into a SQL date.

    @see template::util::date::create
    @see template::util::date::get_property
} {
    return [template::util::date::get_property sql_date $value]
}

ad_proc template::data::from_sql::date {
    value
} {
    Reads an ANSI date as a templating date object.

    @see template::util::date::create
    @see template::util::date::acquire
} {
    return [template::util::date::acquire ansi $value]
}

# The abstract type system includes a timestamp type, so we need to implement one
# in the template "data type" system (even though in reality it should really just
# be a widget working on the abstract type "date", or "timestamp" should replace "date")

ad_proc template::data::to_sql::timestamp {
    value
} {
    Converts a templating date object into a SQL timestamp.

    @see template::util::date::create
    @see template::data::to_sql::date
} {
    return [template::data::to_sql::date $value]
}

ad_proc template::data::from_sql::timestamp {
    value
} {
    Reads an ANSI timestamp as a templating date object.

    @see template::util::date::create
} {
    return [template::data::from_sql::date $value]
}

ad_proc -public template::data::transform::timestamp {
    element_ref
} {
    Collect a timestamp object from the form.
} {
    upvar $element_ref element
    return [template::data::transform::date element]
}

ad_proc -public template::util::timestamp::set_property {
    what
    date
    value
} {
    Get a property in a list created by a timestamp widget. It's the
    same as the date one.

    This is needed by the form builder to support explicit from_sql
    element modifiers.
} {
    return [template::util::date::set_property $what $date $value]
}

ad_proc -public template::util::timestamp::get_property {
    what
    date
} {
    Replace a property in a list created by a timestamp widget. It's
    the same as the date one.

    This is needed by the form builder to support explicit to_sql
    element modifiers.
} {
    return [template::util::date::get_property $what $date]
}

ad_proc -public template::widget::timestamp {
    element_reference
    tag_attributes
} {
    Render a timestamp widget. Default is the localized version.
} {
    upvar $element_reference element

    if { ! [info exists element(format)] } {
        set element(format) "[_ acs-lang.localization-formbuilder_date_format] [_ acs-lang.localization-formbuilder_time_format]"
    }
    return [template::widget::date element $tag_attributes]
}

# The abstract type system includes a time-of-day type, so we need to implement one
# in the template "data type" system.

ad_proc template::data::to_sql::time_of_day {
    value
} {
    Converts a templating date object into a SQL time.

    @see template::util::date::create
    @see template::data::to_sql::date
} {
    return [template::data::to_sql::date $value]
}

ad_proc template::data::from_sql::time_of_day {
    value
} {
    Reads an ANSI time of day as a templating date object.

    @see template::util::date::create
    @see template::data::from_sql::date
} {
    return [template::data::from_sql::date $value]
}

ad_proc -public template::data::transform::time_of_day {
    element_ref
} {
    Collect a time_of_day object from the form.
} {
    upvar $element_ref element
    return [template::data::transform::date element]
}

ad_proc -public template::util::time_of_day::set_property {
    what
    date
    value
} {
    Get a property in a list created by a time_of_day widget.  It's
    the same as the date one.

    This is needed by the form builder to support explicit from_sql
    element modifiers.
} {
    return [template::util::date::set_property $what $date $value]
}

ad_proc -public template::util::time_of_day::get_property {
    what
    date
} {
    Replace a property in a list created by a time_of_day widget.
    It's the same as the date one.

    This is needed by the form builder to support explicit to_sql
    element modifiers.
} {
    return [template::util::date::get_property $what $date]
}

ad_proc -public template::widget::time_of_day {
    element_reference
    tag_attributes
} {
    Render a time_of_day widget. Default is the localized version.
} {
    upvar $element_reference element

    if { ! [info exists element(format)] } {
        set element(format) "[_ acs-lang.localization-formbuilder_date_format] [_ acs-lang.localization-formbuilder_time_format]"
    }
    return [template::widget::date element $tag_attributes]
}

#
## HTML5 Date and time input widgets
##
## These widgets use native browser capabilities introduced by HTML5
## to generate date and time widgets. When available, they also
## provide some client-side normalization with respect to the
## browser's locale and an overall better and more consistent user
## experience across web platforms. They should in time become the
## preferred alternative when implementing date and time fields in
## template forms.
#

ad_proc -public template::widget::h5date {
    element_reference
    tag_attributes
} {

    Implements the HTML 5 input type "date".

    Supported element parameters:

    "-min" and "-max": for setting minimum and maximum dates that can
                       be chosen by the user. If used, the condition
                       min <= value <= max must be met. (Format =
                       YYYY-MM-DD)

    "-step": number of days jumped each time the date is
             incremented. Value must be an integer

    Parameters supplied this way will supersede same-named parameters
    supplied through the "-html" switch.

    This widget also adds the attribute "pattern" as fallback for
    browsers which do not support input type="date".

} {
    upvar $element_reference element

    set attributes \
        [::template::widget::merge_tag_attributes element $tag_attributes]

    # Add fallback pattern attribute. Note that this pattern won't
    # account for leap years or invalid days of the month. We leave
    # this fine-graned validation to the server-side for now.
    dict set attributes pattern {[0-9]+-(1[0-2]|0[0-9])-(3[0-1]|[0-2][0-9])}

    # check min/max constraint
    set last_date ""
    foreach d {max value min} {

        if {[info exists element($d)] && $element($d) ne ""} {
            set attr_value $element($d)
        } elseif {[dict exists attributes $d] && [dict get $attributes $d] ne ""} {
            set attr_value [dict get $attributes $d]
        } else {
            continue
        }

        set invalid_date_p [catch {
            set current_date [clock scan $attr_value -format "%Y-%m-%d"]
        }]

        if {!$invalid_date_p} {
            if {$last_date ne "" &&
                $current_date > $last_date} {
                ns_log Warning "template::widget::h5date value of attribute \"$d\" $attr_value too big"
            } else {
                dict set attributes $d $attr_value
            }

            set last_date $current_date

        } else {
            ns_log Warning "template::widget::h5date value of attribute \"$d\" $attr_value is not a correct date"
        }
    }

    if {[info exists element(step)]} {
        if {[string is integer -strict $element(step)]} {
            dict set attributes step $element(step)
        } else {
            ns_log Warning {template::widget::h5date value of attribute "step" is not an integer!}
        }
    }

    return [template::widget::input date element $attributes]
}

ad_proc -public template::data::validate::h5date {
    value_ref
    message_ref
} {
    Validate a date submitted via HTML 5 input type "date". The
    submitted value is also checked against any "min" and "max"
    constraint set on the input element itself.

    @param value_ref Reference variable to the submitted value.
    @param message_ref Reference variable for returning an error
                       message.

    @return True (1) if valid, false (0) if not.
} {
    upvar 2 $message_ref message $value_ref value

    # get the elements definition
    upvar 2 element element

    if {$value ne ""} {
        set invalid_date_p [catch {
            set supplied_date [clock scan $value -format "%Y-%m-%d"]
        }]

        if {$invalid_date_p} {
            lappend message [_ acs-templating.Invalid_date]
            return 0
        }

        if {[info exists element(min)]} {
            set invalid_date_p [catch {
                set min [clock scan $element(min) -format "%Y-%m-%d"]
            }]
            if {$invalid_date_p || $min > $supplied_date} {
                lappend message [_ acs-templating.Date_must_be_after_min_date \
                                     [list min_date $element(min)]]
                return 0
            }
        }

        if {[info exists element(max)]} {
            set invalid_date_p [catch {
                set max [clock scan $element(max) -format "%Y-%m-%d"]
            }]
            if {$invalid_date_p || $supplied_date > $max} {
                lappend message [_ acs-templating.Date_must_be_before_max_date \
                                     [list max_date $element(max)]]
                return 0
            }
        }
    }

    return 1
}

ad_proc -public template::widget::h5time {
    element_reference
    tag_attributes
} {

   Implements the HTML 5 input type "time".

   Supported element parameters:

   "-min" and "-max": for setting minimum and maximum times that can
                      be chosen by the user. If used, the condition
                      min <= value <= max must be met.  (Format =
                      "hh:mm" or "hh:mm:ss" if parameter "-step" is
                      present)

   "-step": integer value that equates to the number of seconds you
            want to increment by

   Parameters supplied this way will supersede same-named parameters
   supplied through the "-html" switch.

   This widget also adds the attribute "pattern" as fallback for
   browsers which do not support input type="time".

} {
    upvar $element_reference element

    set attributes \
        [::template::widget::merge_tag_attributes element $tag_attributes]

    # Add fallback pattern attribute (HH:MM:SS)
    dict set attributes pattern {(2[0-4]|[0-1][0-9]):[0-5][0-9]:[0-5][0-9]}

    # A HTML time field will always return a value in 24-hour format
    # including leading zeros (hh:mm), regardless of the input
    # format. If the step attribute is used time always includes
    # seconds (hh:mm:ss). However, on the server side we must be able
    # to accept and process both formats, so we must check for both.
    set clock_formats {
        "%H:%M"
        "%H:%M:%S"
    }

    # check min/max constraint
    set last_time ""
    foreach d {max value min} {

        if {[info exists element($d)] && $element($d) ne ""} {
            set attr_value $element($d)
        } elseif {[dict exists attributes $d] && [dict get $attributes $d] ne ""} {
            set attr_value [dict get $attributes $d]
        } else {
            continue
        }

        foreach clock_format $clock_formats {
            set invalid_time_p [catch {
                set current_time [clock scan $attr_value -format $clock_format]
            }]
            if {!$invalid_time_p} {
                break
            }
        }

        if {!$invalid_time_p} {
            if {$last_time ne "" &&
                $current_time > $last_time} {
                ns_log Warning "template::widget::h5time value of attribute \"$d\" $attr_value too big"
            } else {
                dict set attributes $d $attr_value
            }

            set last_time $current_time

        } else {
            ns_log Warning "template::widget::h5time value of attribute \"$d\" $attr_value is not a correct time"
        }
    }

    if {[info exists element(step)]} {
        if {[string is integer -strict $element(step)]} {
            dict set attributes step $element(step)
        } else {
            ns_log Warning {template::widget::h5time value of attribute "step" is not an integer!}
        }
    }

    return [template::widget::input time element $attributes]
}


ad_proc -public template::data::validate::h5time {
    value_ref
    message_ref
} {
    Validate that a date submitted via HTML 5 input type "time". The
    sbumitted value is also checked against any set "min" and "max"
    constraint set on the input element itself.

    @param value_ref Reference variable to the submitted value.
    @param message_ref Reference variable for returning an error message.

    @return True (1) if valid, false (0) if not.
} {
    upvar 2 $message_ref message $value_ref value

    # get the elements definition
    upvar 2 element element

    # A HTML time field will always return a value in 24-hour format
    # including leading zeros (hh:mm), regardless of the input
    # format. If the step attribute is used time always includes
    # seconds (hh:mm:ss). However, on the server side, we must be able
    # to accept and process both formats, so we must check for both.
    set clock_formats {
        "%H:%M"
        "%H:%M:%S"
    }

    if {$value ne ""} {
        foreach clock_format $clock_formats {
            set invalid_time_p [catch {
                set supplied_time [clock scan $value -format $clock_format]
            }]
            if {!$invalid_time_p} {
                break
            }
        }

        if {$invalid_time_p} {
            lappend message [_ acs-templating.Invalid_time]
            return 0
        }

        if {[info exists element(min)]} {
            foreach clock_format $clock_formats {
                set invalid_time_p [catch {
                    set min [clock scan $element(min) -format $clock_format]
                }]
                if {!$invalid_time_p} {
                    break
                }
            }
            if {$invalid_time_p || $min > $supplied_time} {
                lappend message [_ acs-templating.Time_must_be_after_min_time \
                                     [list min_time $element(min)]]
                return 0
            }
        }

        if {[info exists element(max)]} {
            foreach clock_format $clock_formats {
                set invalid_time_p [catch {
                    set max [clock scan $element(max) -format $clock_format]
                }]
                if {!$invalid_time_p} {
                    break
                }
            }
            if {$invalid_time_p || $supplied_time > $max} {
                lappend message [_ acs-templating.Time_must_be_before_max_time \
                                     [list max_time $element(max)]]
                return 0
            }
        }
    }

    return 1
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
