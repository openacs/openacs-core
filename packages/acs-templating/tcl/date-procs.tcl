# Date widgets for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Author: Stanislav Freidin (sfreidin@arsdigita.com)
#
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Prepare an array to map symbolic month names to their indices

namespace eval template {}
namespace eval template::data {}
namespace eval template::util {}
namespace eval template::util::date {}
namespace eval template::widget {}
namespace eval template::data::transform {}

ad_proc -public template::util::date { command args } {
    Dispatch procedure for the date object
} {
  eval template::util::date::$command $args
}

ad_proc -public template::util::date::init {} {
    Sets up some initial variables and other conditions
    to facilitate the data structure template::util::date
    working properly and completely.
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
  array set fragment_widgets [list \
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

ad_proc -public template::util::date::monthName { month length } {
    Return the specified month name (short or long)
} {
  if { [string equal $length long] } {
    return [lc_time_fmt "2002-[format "%02d" $month]-01" "%B"]
  } else {
    return [lc_time_fmt "2002-[format "%02d" $month]-01" "%b"]
  }
}


ad_proc -public template::util::date::daysInMonth { month {year 0} } {
    @return the number of days in a month, accounting for leap years
    LOOKATME: IS THE LEAP YEAR CODE CORRECT ?
} {
  set month [string trimleft $month 0]
  variable month_data
  set month_desc $month_data($month)
  set days [lindex $month_desc 2]
  
  if { $month == 2 && (
          ([expr $year % 4] == 0 && [expr $year % 100] != 0) ||
          [expr $year % 400] == 0
        ) } {
    return [expr $days + 1]
  } else {
    return $days
  } 
}  

ad_proc -public template::util::date::create {
  {year {}} {month {}} {day {}} {hours {}} 
  {minutes {}} {seconds {}} {format "DD MONTH YYYY"}
} {
    Create a new Date object
    I chose to implement the date objects as lists instead of 
    arrays, because arrays are not first-class in TCL
} {
  return [list $year $month $day $hours $minutes $seconds $format]
}

ad_proc -public template::util::date::acquire { type { value "" } } {
    Create a new date with some predefined value
    Basically, create and set the date
} {
  set the_date [template::util::date::create]
  return [template::util::date::set_property $type $the_date $value]
}

ad_proc -public template::util::date::today {} {
    Create a new Date object for the current date
} {

  set now [clock format [clock seconds] -format "%Y %m %d"]
  set today [list]

  foreach v $now {
    # trim leading zeros to avoid octal problem
    lappend today [template::util::leadingTrim $v]
  }

  return [eval create $today]
}

ad_proc -public template::util::date::now {} {
    Create a new Date object for the current date and time
} {
  set now [clock format [clock seconds] -format "%Y %m %d %H %M %S"]
  set today [list]

  foreach v $now {
    lappend today [template::util::leadingTrim $v]
  }

  return [eval create $today]
}

ad_proc -public template::util::date::from_ansi {
    ansi_date
    {format "YYYY MM DD"}
} {
    Create a new templating system date structure from a full ANSI
    date, i.e. in the format YYYY-MM-DD HH24:MI:SS.

    @param ansi_date Date in full ANSI format YYYY-MM-DD HH24:MI:SS (time portion is optional).
    @param format Format for the date object. Optional, defaults to YYYY MM DD.
    @return Date object for use with e.g. form builder.
    @author Lars Pind (lars@pinds.com)
    @creation-date November 18, 2002
} {
    set date [template::util::date::create]
    set date [template::util::date::set_property format $date $format]
    set date [template::util::date::set_property ansi $date $ansi_date]
    return $date
}

ad_proc -public template::util::date::get_property { what date } {

    Returns a property of a date list, usually created by ad_form.

    @param what the name of the property. one of:<ul>
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

  switch $what {
    year       { return [lindex $date 0] }
    month      { return [lindex $date 1] }
    day        { return [lindex $date 2] }
    hours      { return [lindex $date 3] }
    minutes    { return [lindex $date 4] }
    seconds    { return [lindex $date 5] }
    format     { return [lindex $date 6] }
    long_month_name {
      if { [string equal [lindex $date 1] {}] } {
        return {}
      } else {
        return [monthName [lindex $date 1] long]
      }
    }
    short_month_name {
      if { [string equal [lindex $date 1] {}] } {
        return {}
      } else {
        return [monthName [lindex $date 1] short]
      }
    }
    days_in_month {
      if { [string equal [lindex $date 1] {}] || \
           [string equal [lindex $date 0] {}]} {
        return 31
      } else {
        return [daysInMonth \
               [lindex $date 1] [lindex $date 0]]
      }
    }
    short_year {
      if { [string equal [lindex $date 0] {}] } {
        return {}
      } else {
	  return [expr [lindex $date 0] % 100]
      }
    }
    short_hours {
      if { [string equal [lindex $date 3] {}] } {
        return {}
      } else {    
        set value [expr [lindex $date 3] % 12]
	if { $value == 0 } {
          return 12
	} else {
          return $value
	}
      }
    }
    ampm {
      if { [string equal [lindex $date 3] {}] } {
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
        if { ![string equal [lindex $date $i] {}] } {
          return 1
        } 
      }
      return 0
    }
    sql_date {
      # LARS: Empty date results in NULL value
      if { [empty_string_p $date] } {
        return "NULL"
      }
      set value ""
      set format ""
      set space ""
      set pad "0000"
      foreach { index sql_form } { 0 YYYY 1 MM 2 DD 3 HH24 4 MI 5 SS } {
        set piece [lindex $date $index]
        if { ![string equal $piece {}] } {
          append value "$space[string range $pad [string length $piece] end]$piece"
          append format $space
          append format $sql_form
          set space " "
	}
        set pad "00"
      }

      # DRB: We need to differentiate between date and timestamp, for PG, at least,
      # and since Oracle supports to_timestamp() we'll just do it for both DBs.
      if { [llength $date] <= 3 } {
          return "to_date('$value', '$format')"
      } else {
          return "to_timestamp('$value', '$format')"
      }
    }
    ansi {
      # LARS: Empty date results in NULL value
      if { [empty_string_p $date] } {
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
      if { ![string equal $hours {}] && \
           ![string equal $minutes {}] } {
	  append value " [string range $pad [string length $hours] end]${hours}:[string range $pad [string length $minutes] end]$minutes"
	  if { ![string equal $seconds {}] } {
	      append value ":[string range $pad [string length $seconds] end]$seconds"
	  }
      }
      return $value
    }
    clock {
      set value ""
      # Unreliable !
      unpack $date
      if { ![string equal $year {}] && \
           ![string equal $month {}] && \
           ![string equal $day {}] } {
        append value "$month/$day/$year"
      }
      if { ![string equal $hours {}] && \
           ![string equal $minutes {}] } {
        append value " ${hours}:${minutes}"
        if { ![string equal $seconds {}] } {
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

ad_proc -public template::util::date::compare { date1 date2 } {
    Perform date comparison; same syntax as string compare
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

ad_proc -public template::util::date::set_property { what date value } {

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

    if {[empty_string_p $value]} {
        return $date
    }
    
  # Erase leading zeroes from the value, but make sure that 00
  # is not completely erased - but only for single-element properties

  switch $value {
    year - month - day - hour - minutes - seconds - short_year - short_hours - ampm {
      set value [template::util::leadingTrim $value]
    }
  }

  switch $what {
    year       { return [lreplace $date 0 0 $value] }
    month      { return [lreplace $date 1 1 $value] }
    day        { return [lreplace $date 2 2 $value] }
    hours      { return [lreplace $date 3 3 $value] }
    minutes    { return [lreplace $date 4 4 $value] }
    seconds    { return [lreplace $date 5 5 $value] }
    format     { return [lreplace $date 6 6 $value] }
    short_year {
      if { $value < 69 } {
        return [lreplace $date 0 0 [expr $value + 2000]]
      } else {
        return [lreplace $date 0 0 [expr $value + 1900]]  
      }
    }
    short_hours {
      return [lreplace $date 3 3 $value]
    }
    ampm {
      if { [string equal [lindex $date 3] {}] } {
        return $date
      } else { 
        set hours [lindex $date 3]

        # robustness check: make sure we handle form of 08:00am  --jfr
        regexp {0([0-9])} $hours match trimmed_hours
        if {[exists_and_not_null trimmed_hours]} {
            set hours $trimmed_hours
        }

        if { [string equal $value pm] && $hours < 12 } {
          return [lreplace $date 3 3 [expr $hours + 12]]
        } elseif { [string equal $value am] } {
          return [lreplace $date 3 3 [expr $hours % 12]]
	} else {
          return $date
        }
      }
    }
    clock {
      set old_date [clock format $value -format "%Y %m %d %H %M %S"]
      set new_date [list]
      foreach field $old_date {
        lappend new_date [template::util::leadingTrim $field]
      }
      lappend new_date [lindex $date 6]
      return $new_date
    }
    sql_date {
      set old_format [lindex $date 6]
      set new_date [list]
      foreach fragment $value {
        lappend new_date [template::util::leadingTrim $fragment]
      }
      lappend new_date $old_format
      return $new_date
    }
    ansi {
        # Some initialisation...
        # Rip $date into $ansi_* as numbers, no leading zeroes
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

ad_proc -public template::util::date::defaultInterval { what } {
    Get the default ranges for all the numeric fields of a Date object
} {
  switch $what {
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

ad_proc -public template::util::date::unpack { date } {
    Set the variables for each field of the date object in 
    the calling frame.

    sets: year month day hours minutes seconds format from a list formatted date string 

    @see template::util::date::from_ans
} {
    uplevel [list foreach {year month day hours minutes seconds format} $date { break }]
}

ad_proc -public template::util::date::now_min_interval {} {
    Create a new Date object for the current date and time 
    with the default interval for minutes

    @author Walter McGinnis (wtem@olywa.net)
    @creation-date 2002-01-06
} {
  set now [list]
  foreach v [clock format [clock seconds] -format "%Y %m %d %H %M %S"] {
      lappend now [template::util::leadingTrim $v]
  }
    
  # manipulate the minute value so it rounds up to nearest minute interval
  set minute [lindex $now 4]
  # there is a definition for minute interval: 0 59 5
  set interval_def [defaultInterval minutes]
  for { set i [lindex $interval_def 0] } \
      { $i <= [lindex $interval_def 1] } \
      { incr i [lindex $interval_def 2] } {
      if {$minute == $i} {
	  break
      } elseif {$minute < $i} {
	  set minute $i
          break
      }
  }

  # replace the minute value in the now list with new value
  set now [lreplace $now 4 4 $minute]

  return [eval create $now]
}

ad_proc -public template::util::date::now_min_interval_plus_hour {} {
    Create a new Date object for the current date and time 
    plus one hour
    with the default interval for minutes

    @author Walter McGinnis (wtem@olywa.net)
    @creation-date 2002-01-06
} {
  set now [list]
  foreach v [clock format [clock seconds] -format "%Y %m %d %H %M %S"] {
      lappend now [template::util::leadingTrim $v]
  }
    
  # manipulate the minute value so it rounds up to nearest minute interval
  set minute [lindex $now 4]
  # there is a definition for minute interval: 0 59 5
  set interval_def [defaultInterval minutes]
  for { set i [lindex $interval_def 0] } \
      { $i <= [lindex $interval_def 1] } \
      { incr i [lindex $interval_def 2] } {
      if {$minute == $i} {
	  break
      } elseif {$minute < $i} {
	  set minute $i
          break
      }
  }

  # get the hour value
  set hour [lindex $now 3]
  # replace the hour and minute values in the now list with new values
  set now [lreplace $now 3 4 [incr hour $minute]]

  return [eval create $now]
}

ad_proc -public template::util::date::add_time { {-time_array_name:required} {-date_array_name:required} } {
    set the time and date and new format properties 
    into one date object (list) which is returned
    not sure this proc should live here...
    
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
	if ![string equal $field "format"] {
	    # Coerce values to non-negative integers
	    if { ![string equal $field ampm] } {
		if { ![regexp {[0-9]+} $time_in($field) value] } {
		    set value {}
		}
	    }
	    # If the value is not null, set it
	    if { ![string equal $value {}] } {
		set the_date [template::util::date::set_property $field $the_date $value]
		if { ![string equal $field ampm] } {
		    set have_values 1
		}
	    }
	}
    }

    # add date properties
    foreach field [array names date_in] {
	# skip format
	if ![string equal $field "format"] {
	    # Coerce values to non-negative integers
	    if { ![regexp {[0-9]+} $date_in($field) value] } {
		set value {}
	    }
	    # If the value is not null, set it
	    if { ![string equal $value {}] } {
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

ad_proc -public template::util::negative { value } {
    Check if a value is less than zero, but return false
    if the value is an empty string
} {
  if { [string equal $value {}] } {
    return 0
  } else {
    return [expr $value < 0]
  }
}


ad_proc -public template::util::date::validate { date error_ref } {
    Validate a date object. Return 1 if the object is valid,
    0 otherwise. Set the error_ref variable to contain
    an error message, if any
} {
  # If the date is empty, it's valid
  if { ![get_property not_null $date] } {
    return 1
  }

  variable fragment_formats

  upvar $error_ref error_msg

  unpack $date

  set error_msg ""
  set return_code 1

  foreach {field exp} { year "YYYY|YY" month "MM|MON|MONTH" day "DD" 
                      hours "HH24|HH12" minutes "MI" seconds "SS" } {

    # If the field is required, but missing, report an error
    if {  [string equal [set $field] {}] } {
      if { [regexp $exp $format match] } {
        append error_msg "No value supplied for $field<br>"
        set return_code 0
      }
    } else {
      # fields should only be integers
      if { ![regexp {^[0-9]+$} [set $field] match] } {
        append error_msg "The $field must be a non-negative integer<br>"  
        set return_code 0
        set $field {}
      }
    }
  }

  if { [template::util::negative $year] } {
    append error_msg "Year must be positive<br>"
    set return_code 0
  }

  if { ![string equal $month {}] } {
    if { $month < 1 || $month > 12 } {
      append error_msg "Month must be between 1 and 12<br>"
      set return_code 0
    } else {
      if { $year > 0 } { 
        if { ![string equal $day {}] } {
          set maxdays [get_property days_in_month $date]
          if { $day < 1 || $day > $maxdays } {
            append error_msg "The day must be between 1 and $maxdays for "
            append error_msg "the month of 
                              [get_property long_month_name $date] <br>"
            set return_code 0
	  }
        }
      }
    }
  }

  if { [template::util::negative $hours] || $hours > 23 } {
    append error_msg "Hours must be between 0 and 23<br>"
    set return_code 0
  } 

  if { [template::util::negative $minutes] || $minutes > 59 } {
    append error_msg "Minutes must be between 0 and 59<br>"
    set return_code 0
  } 

  if { [template::util::negative $seconds] || $seconds > 59 } {
    append error_msg "Seconds must be between 0 and 59<br>"
    set return_code 0
  } 

  return $return_code
}



ad_proc -public template::util::leadingPad { string size } {
    Pad a string with leading zeroes
} {
  
  if { [string equal $string {}] } {
    return {}
  }

  set ret [string repeat "0" [expr $size - [string length $string]]]
  append ret $string
  return $ret

}  

ad_proc -public template::util::leadingTrim { value } {
    Trim the leading zeroes from the value, but preserve the value
    as "0" if it is "00"
} {
  set empty [string equal $value {}]
  set value [string trimleft $value 0]
  if { !$empty && [string equal $value {}] } {
    set value 0
  }
  return $value
}

# Create an html fragment to display a numeric range widget
# interval_def is in form { start stop interval }

ad_proc -public template::widget::numericrange {element_reference tag_attributes} {
    Widget proc usable with ad_form,  need to define interval_def as 
    {interval_def {start end step}}
} { 
  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  return [template::widget::numericRange $element(name) $element(interval_def) $element(size) $element(value) $tag_attributes]
}

ad_proc -public template::widget::numericRange { name interval_def size {value ""} {tag_attributes {}} } {
    Create an html fragment to display a numeric range widget
    interval_def is in form { start stop interval }
} {
  array set attributes $tag_attributes
  
  set interval_size [lindex $interval_def 2]
  set options [list [list "--" {}]]

  for { set i [lindex $interval_def 0] } \
      { $i <= [lindex $interval_def 1] } \
      { incr i $interval_size } {
    lappend options [list [template::util::leadingPad $i $size] $i]
  }

  if {$interval_size > 1} {
    # round minutes or seconds to nearest interval
    if { ![empty_string_p $value] } {
      set value [expr {$value-($value - [lindex $interval_def 0])%$interval_size}]
    }
  }

  return [template::widget::menu $name $options [list $value] attributes]
}

ad_proc -public template::widget::dateFragment {
    element_reference fragment size type value {mode edit} {tag_attributes {}} } {
      Create an input widget for the given date fragment
      If type is "t", uses a text widget for the fragment, with the given
      size.
      Otherwise, determines the proper widget based on the element flags,
      which may be text or a picklist
} {

  upvar $element_reference element
  
  set value [template::util::date::get_property $fragment $value]
  set value [template::util::leadingTrim $value]

  if { ![string equal $mode "edit"] } {
    set output {}
    append output "<input type=\"hidden\" name=\"$element(name).$fragment\" value=\"[template::util::leadingPad $value $size]\">"
    append output $value
    return $output
  } else {
    if { [info exists element(${fragment}_interval)] } {
      set interval $element(${fragment}_interval)
    } else {
       # Display text entry for some elements, or if the type is text
       if { [string equal $type t] ||
            [regexp "year|short_year" $fragment] } {
         set output "<input type=\"text\" name=\"$element(name).$fragment\" size=\"$size\""
         append output " maxlength=\"$size\" value=\"[template::util::leadingPad $value $size]\""
         array set attributes $tag_attributes
         foreach attribute_name [array names attributes] {
           if { [string equal $attributes($attribute_name) {}] } {
             append output " $attribute_name"
           } else {
             append output " $attribute_name=\"$attributes($attribute_name)\""
           }
         }
         append output "/>\n"
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
  element_reference fragment size type value {mode edit} {tag_attributes {}} } {
      Create a widget that shows the am/pm selection
} {

  upvar $element_reference element
  array set attributes $tag_attributes

  set value [template::util::date::get_property $fragment $value]

  if { ![string equal $mode "edit"] } {
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
  element_reference fragment size type value {mode edit} {tag_attributes {}} } {
      Create a month entry widget with short or long month names
} {

  variable ::template::util::date::month_data

  upvar $element_reference element
  array set attributes $tag_attributes

  set value [template::util::date::get_property $fragment $value]

  if { ![string equal $mode "edit"] } {
    set output {}
    if { [exists_and_not_null value] } {
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


ad_proc -public template::widget::date { element_reference tag_attributes } {
    Create a date entry widget according to a format string
    The format string should contain the following fields, separated
    by / \ - : . or whitespace:
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
    widget will be used to represent the field.
    the array in range_ref determines interval ranges; the keys
    are the date fields and the values are in form {start stop interval}
} {

  variable ::template::util::date::fragment_widgets

  upvar $element_reference element

  if { [info exists element(html)] } {
    array set attributes $element(html)
  }

  array set attributes $tag_attributes

  set output "<!-- date $element(name) begin -->\n"

  if { ! [info exists element(format)] } { 
    set element(format) "DD MONTH YYYY" 
  }

  # Choose a pre-selected format, if any
  switch $element(format) {
    long     { set element(format) "YYYY/MM/DD HH24:MI:SS" }
    short    { set element(format) "YYYY/MM/DD"}
    time     { set element(format) "HH24:MI:SS"}
    american { set element(format) "MM/DD/YY"}
    expiration {
      set element(format) "MM/YY"
      set current_year [clock format [clock seconds] -format "%Y"]
      set current_year [expr $current_year % 100]
      set element(short_year_interval) \
        [list $current_year [expr $current_year + 10] 1]
      set element(help) 1 
    }
  }

  # Just remember the format for now - in the future, allow
  # the user to enter a freeform format
  append output "<input type=\"hidden\" name=\"$element(name).format\" "
  append output "value=\"$element(format)\" />\n"
  append output "<table border=\"0\" cellpadding=\"0\" cellspacing=\"2\">\n<tr>"

  # Prepare the value to set defaults on the form
  if { [info exists element(value)] && 
       [template::util::date::get_property not_null $element(value)] } {
    set value $element(value)
    foreach v $value {
      lappend trim_value [template::util::leadingTrim $v]
    }
    set value $trim_value
  } else {
    set value {}
  }

  # Keep taking tokens off the top of the string until out
  # of tokens
  set format_string $element(format)

  set tokens [list]

  while { ![string equal $format_string {}] } {

    # Snip off the next token
    regexp {([^/\-.: ]*)([/\-.: ]*)(.*)} \
          $format_string match word sep format_string
    # Extract the trailing "t", if any
    regexp -nocase $template::util::date::token_exp $word \
          match token type

    append output "<td nowrap=\"nowrap\">"
    
    lappend tokens $token

    # Output the widget
    set fragment_def $template::util::date::fragment_widgets([string toupper $token])
    set fragment [lindex $fragment_def 1]

    append output [template::widget::[lindex $fragment_def 0] \
                     element \
                     $fragment \
                     [lindex $fragment_def 2] \
                     $type \
                     $value \
                     $element(mode) \
                     [array get attributes]]

    # Output the separator
    if { [string equal $sep " "] } {
      append output "&nbsp;"
    } else {
      append output "$sep"
    }

    append output "</td>\n"
  }

  append output "</tr>\n"

  # Append help text under each widget, if neccessary
  if { [info exists element(help)] } {
    append output "<tr>" 
    foreach token $tokens {
      set fragment_def $template::util::date::fragment_widgets($token)
      append output "<td nowrap=\"nowrap\" align=\"center\"><font size=\"-2\">[lindex $fragment_def 3]</font></td>"
    }
    append output "</tr>\n"
  } 

  append output "</table>\n"

  append output "<!-- date $element(name) end -->\n"
  
  return $output

}

ad_proc -public template::data::transform::date { element_ref } {
    Collect a Date object from the form
} {

  upvar $element_ref element
  set element_id $element(id)

  set the_date [template::util::date::create \
   {} {} {} {} {} {} [ns_queryget "$element_id.format"]]
  set have_values 0

  foreach field { 
    year short_year month day 
    short_hours hours minutes seconds ampm
  } {
     set key "$element_id.$field"    
     if { [ns_queryexists $key] } {
       set value [ns_queryget $key]
       # Coerce values to non-negative integers
       if { ![string equal $field ampm] } {
	 if { ![regexp {[0-9]+} $value value] } {
           set value {}
         }
       }
       # If the value is not null, set it
       if { ![string equal $value {}] } {
         set the_date [template::util::date::set_property $field $the_date $value]
         if { ![string equal $field ampm] } {
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

