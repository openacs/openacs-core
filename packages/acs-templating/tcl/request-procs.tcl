ad_library {
    Request handling procs for the ArsDigita Templating System

    @author Karl Goldstein    (karlg@arsdigita.com)
             
    @cvs-id $Id$
}

# Copyright (C) 1999-2000 ArsDigita Corporation
    
# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# @namespace request

# The request commands provide a mechanism for managing the query
# parameters to a page.  The request is simply a special instance of a
# form object, and is useful for the frequent cases when data must be
# passed from page to page to determine display or page flow, rather
# than perform a transaction based on user input via a form.

# @see form element


namespace eval template {}
namespace eval template::request {}

ad_proc -public template::request {
  command
  args
} {
  Dispatch procedure for requests.
} {
  request::$command {*}$args
}

ad_proc -public template::request::create { args } {
    Create the request data structure.  Typically called at the beginning
    of the code for any page that accepts query parameters.

    @option params A block of parameter declarations, separated by newlines.
                   Equivalent to calling set_param for each parameter, but
                   requiring slightly less typing.
} {
  template::form::create request {*}$args

  set level [template::adp_level]

  # check for params so they can be created
  upvar #$level request:properties opts

  if { [info exists opts(params)] } {

    # strip carriage returns
    regsub -all {\r} $opts(params) {} param_data

    foreach param [split $param_data "\n"] {

      set param [string trim $param]
      if {$param eq {}} { continue }

      set_param {*}$param
    }
  }
}

ad_proc -public template::request::set_param { name args } {
    Declares a query parameter as part of the page request.  Validates
    the values associated with the parameter, in the same fashion as for
    form elements.

    @param  name      The name of the parameter to declare.

    @option name      The name of parameter in the query (may be different
                      from the reference name).
    @option multiple  A flag indicating that multiple values may be specified
                      for this parameter.
    @option datatype  The name of a datatype for the element values.  Valid
                      datatypes must have a validation procedure defined in
                      the <tt>template::data::validate</tt> namespace.
    @option optional  A flag indicating that no value is required for this
                      element.  If a default value is specified, the default
                      is used instead.
    @option validate  A list of custom validation blocks in the form
                      { name { expression } { message } \
                        name { expression } { message } ...}
                      where name is a unique identifier for the validation
                      step, expression is a block to Tcl code that evaluates
                      to 1 or 0, and message is to be displayed to the user 
                      when the validation step fails.

    @see template::element::create
} {
  set level [template::adp_level]
  template::element::create request $name {*}$args

  # Set a local variable with the parameter value but no
  # clobber the variable if it already exists.

  uplevel #$level "
    if { ! \[info exists $name\] } {
      set $name \[template::request::get_param $name\]
    }
  "
}
# "


ad_proc -public template::request::get_param { name } {
    Retrieves the value(s) of the specified parameter.

    @param name The name of the parameter.

    @return The value of the specified parameter.
} {
  set level [template::adp_level]
  upvar #$level request:$name param

  if { [info exists param(multiple)] } {

    # multiple values expected

    set value [template::element::get_values request $name]

  } else {
    set value [template::element::get_value request $name]
  }

  return $value
}

ad_proc -public template::request::error { args } {
    Manually report request error(s) by setting error messages and then
    calling is_valid to handle display.  Useful for conditions not tied
    to a single query parameter.  The arguments to the procedure may be
    any number of name-message combinations.

    @param name A unique identifier for the error condition, which may
                be used for layout purposes.
    @param msg  The message text associated with the condition.
} {
  set level [template::adp_level]
  upvar #$level request:error requesterror
  foreach { name msg } $args {
    set requesterror($name) $msg
  }

  is_valid
}

ad_proc -public template::request::is_valid { { url "" } } {
    Checks for any param errors.  If errors are found, sets the display
    template to the specified URL (a system-wide request error page by
    default).

    @param url The URL of the template to use to display error messages.
    	     The special value "self" may be used to indicate that the template
    	     for the requested page itself will handle reporting error
               conditions.

    @return 1 if no error conditions exist, 0 otherwise.
} {
    set level [template::adp_level]
    upvar #$level request:error requesterror

    if { [info exists requesterror] } {

	# set requesterror as a data source
	uplevel #$level "upvar 0 request:error requesterror"

	if { $url ne "self" } {

	    if {$url eq {}} { 
		set file_stub [template::resource_path -type messages -style request-error]
	    } else {
		set file_stub [ns_url2file $url]
	    }
	    template::set_file $file_stub
	}

	return 0

    } else {

	return 1
    }
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
