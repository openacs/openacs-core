# Datatype validation for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public template::data::validate { type value_ref message_ref } {

  return [validate::$type $value_ref $message_ref]
}

ad_proc -public template::data::validate::integer { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set result [regexp {^(-)?[0-9]+$} $value]

  if { ! $result } {
    set message "Invalid number \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::text { value_ref message_ref } {

  # anything is valid for text
  return 1
}

ad_proc -public template::data::validate::keyword { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set result [regexp {^[a-zA-Z0-9_]+$} $value]

  if { ! $result } {
    set message "Invalid keyword \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::filename { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set result [regexp {^[a-zA-Z0-9_-]+$} $value]

  if { ! $result } {
    set message "Invalid filename \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::url { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set expr {^(http://)?([a-zA-Z0-9_\-\.]+(:[0-9]+)?)?[a-zA-Z0-9_.%/?=&-]+$}
  set result [regexp $expr $value]

  if { ! $result } {
    set message "Invalid url \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::date { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  return [template::util::date::validate $value message]
}

# It was necessary to declare a datatype of "search" in order for the
# transformation to be applied correctly.  In reality, the transformation
# should be on the element, not on the datatype.

ad_proc -public template::data::validate::search { value_ref message_ref } {

  return 1
}

ad_proc -public template::data::validate::currency { value_ref message_ref } {

    upvar 2 $message_ref message $value_ref value

    ns_log Notice "In template::data::validate::currency"

    # a currency is a 6 element list supporting, for example, the following forms: "$2.03" "Rs 50.42" "12.52L" "Y5,13c"
    # equivalent of date::unpack
    set leading_symbol  [lindex 0 $value]
    set whole_part      [lindex 1 $value]
    set seperator       [lindex 2 $value]
    set fractional_part [lindex 3 $value]
    set trailing_money  [lindex 4 $value]
    set format          [lindex 5 $value]

    set format_whole_part      [lindex 1 $format]
    set format_fractional_part [lindx 3 $format]

    set whole_part_valid_p [expr [data::validate integer whole_part message] && { [string length $whole_part] < $format_whole_part } ]
    set fractional_part_valid_p [expr [data::validate integer fractional_part message] && { [string length $fractional_part] < $format_fractional_part }]

    if { ! $whole_part_valid_p || ! $fractional_part_valid_p } {
	set message "Invalid currency {[join $value ""]}"
	return 0
    } else {
	return 1
    }
}    

ad_proc -public template::data::transform { type value_ref } {

  set proc_name [info procs ::template::data::transform::$type]

  if { ! [string equal $proc_name {}] } {

    transform::$type $value_ref
  }
}
