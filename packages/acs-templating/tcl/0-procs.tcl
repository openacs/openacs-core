# Initialize namespaces, global macros and filters for ArsDigita Templating
# System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Author: Karl Goldstein (karlg@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Initialize namespaces used by template procs

namespace eval template {

  namespace export query request form element

  # namespaces for cached datasource and template procedures

  namespace eval code {
    namespace eval tcl {}
    namespace eval adp {}
  }

  # namespaces for mtime checking procedures on datasource and
  # template files
  namespace eval mtimes {
    namespace eval tcl {}
    namespace eval adp {}
  }

  namespace eval query {}
  namespace eval util {
    namespace eval date {}
    namespace eval currency {}
    namespace eval file {}
  }

  namespace eval element {

    # default settings 
    variable defaults
    set defaults [list widget text datatype integer values {} help_text {} before_html {} after_html {}]
  }

  namespace eval request {}

  namespace eval widget {
    namespace eval table {}
  }

  namespace eval form {
    
    # default settings
    variable defaults
    set defaults [list method post section {} mode edit edit_buttons { { "OK" ok } } display_buttons { { "Edit" edit } } show_required_p t]
  }

  namespace eval wizard {
    
    # stack level at which wizard is created
    variable parse_level
    # An array of default buttons and their names
    variable default_button_labels
    array set default_button_labels \
      [list back "<< Previous" repeat "Repeat" next "Next >>" finish "Finish"]
  }

  namespace eval paginator {
    
    # stack level at which paginator is created
    variable parse_level

    # Default values for paginator properties
    variable defaults
    set defaults [list pagesize 20 timeout 600 groupsize 10]
  }

  namespace eval data {
    namespace eval validate {}
    namespace eval transform {}
  }

  # keep track of the stack frame in which a template is rendered at run-time
  variable parse_level

  # used for compiling Tcl code from ADP template
  variable parse_list

  # used to keep track of nested tags
  variable tag_stack

  # used to keep a list of filter procedures to execute
  variable filter_list
  set filter_list [list]

  # filters may set or modify the URL to replace ns_conn url
  variable url

  # specify what procs can be accessed directly
  namespace export form element request
}

ad_proc -public template_tag { name arglist body } {
    Generic wrapper for registered tag handlers.
} {

  # LARS:
  # We only ns_register_adptag the tag if it hasn't already been registered
  # (if the proc doesn't exist).
  # This makes debugging templating tags so much easier, because you don't have
  # to restart the server each time.
  set exists_p [llength [info procs template_tag_$name]]

  switch [llength $arglist] {

    1 { 

      # empty tag
      eval "proc template_tag_$name { params } {
	
	template::adp_tag_init $name
	
	$body

        return \"\"
      }"

      if { !$exists_p } {
        ns_register_adptag $name template_tag_$name 
      }
    }

    2 { 

      # balanced tag so push on/pop off tag name and parameters on a stack
      eval "proc template_tag_$name { chunk params } {
	
	template::adp_tag_init $name

	variable template::tag_stack
	lappend tag_stack \[list $name \$params\]
	
	$body

	template::util::lpop tag_stack

        return \"\"
      }"

      if { !$exists_p } {
        ns_register_adptag $name /$name template_tag_$name 
      }
    }

    default { error "Invalid number of arguments to tag handler." }
  }
}
