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

ad_proc -public template::data::transform { type value_ref } {

  set proc_name [info procs ::template::data::transform::$type]

  if { ! [string equal $proc_name {}] } {

    transform::$type $value_ref
  }
}

ad_proc -public template::data::validate::user { value_ref message_ref } {
    A data type that works with the 'user' widget. It allows you to
    search for a particular user when a dropdown would get too big.
} {

    upvar 2 $message_ref message $value_ref value

    if { [info exists value] && [string equal $value ":other:"] } { 
        set result 0
        set message "Please search for user by name, email, or screen name."
    } elseif { [info exists value] && ![regexp {^[0-9]*$} $value] } {
        set result 0
        set message "Please pick a user from the result of your search."
    } else {
        set result 1
    }

    return $result 
}
