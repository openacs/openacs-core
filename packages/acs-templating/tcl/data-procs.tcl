# Datatype validation for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
#          
# $Id$

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
    @see template::data::validate::filename 
    @see template::data::validate::integer 
    @see template::data::validate::keyword 
    @see template::data::validate::search 
    @see template::data::validate::string 
    @see template::data::validate::text 
    @see template::data::validate::url  
} { 

  return [validate::$type $value_ref $message_ref]
}

ad_proc -public template::data::validate::integer { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set result [regexp {^[+-]?\d+$} $value]

  if { ! $result } {
    set message "Invalid integer \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::naturalnum { value_ref message_ref } {
  Validates natural numbers data types
  Will trim leading 0 in order to avoid TCL interpreting it as octal in the future
  (code borrowed from ad_page_contract_filter_proc_naturalnum)
  @author Rocael Hernandez <roc@viaro.net>
} {
  upvar 2 $message_ref message $value_ref value

    set result [regexp {^(0*)(([1-9][0-9]*|0))$} $value match zeros value]

    if { ! $result } {
    set message "Invalid natural number \"$value\""
    }

  return $result
}

ad_proc -public template::data::validate::float { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  # Not allowing for scientific notation. Would the databases swallow it?
  set result [regexp {^([+-]?)(?=\d|\.\d)\d*(\.\d*)?$} $value]

  if { ! $result } {
    set message "Invalid decimal number \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::boolean { value_ref message_ref } {
  Validates boolean data types
  @author Roberto Mello <rmello at fslc.usu.edu>
} {

  upvar 2 $message_ref message $value_ref value

  set result ""
  set value [string tolower $value]

  switch $value {
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
         set message "Invalid choice \"$value\""
      }
  }

  return $result 
}

ad_proc -public template::data::validate::text { value_ref message_ref } {

  # anything is valid for text
  return 1
}

ad_proc -public template::data::validate::string { value_ref message_ref } {

  # anything is valid for string
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

ad_proc -public template::data::validate::email { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set result [util_email_valid_p $value]

  if { ! $result } {
    set message "Invalid email format \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::url { value_ref message_ref } {

  upvar 2 $message_ref message $value_ref value

  set expr {^(https?://)?([a-zA-Z0-9_\-\.]+(:[0-9]+)?)?[a-zA-Z0-9_.%/?=&-]+$}
  set result [regexp $expr $value]

  if { ! $result } {
    set message "Invalid url \"$value\""
  }
   
  return $result 
}

ad_proc -public template::data::validate::url_element { value_ref message_ref } {

    Beautiful URL elements that may only contain lower case 
    characters, numbers and hyphens.

    <p>


    @see util_text_to_url if you want to offer auto-generation of URLs based on a pretty name

    @author Tilmann Singer

} {
    upvar 2 $message_ref message $value_ref value

    set expr {^[a-z0-9-]+$}
    set result [regexp $expr $value]

    if { ! $result } {
	set message "Invalid url \"$value\". Please use only lowercase characters, numbers and hyphens, e.g. \"foo-bar\"."
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

