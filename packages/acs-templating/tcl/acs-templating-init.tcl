# Initialize namespaces, global macros and filters for ArsDigita Templating
# System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Author: Karl Goldstein (karlg@arsdigita.com)
# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

# Initialize namespaces used by template procs

namespace eval template {}
namespace eval template::form {}

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
    set defaults \
        [list \
             method post \
             section {} \
             mode edit \
             edit_buttons [list [list [_ acs-kernel.common_OK] ok ]] \
             display_buttons [list [list [_ acs-kernel.common_Edit] edit]] \
             show_required_p t]
  }

  namespace eval wizard {
    
    # stack level at which wizard is created
    variable parse_level
    # An array of default buttons and their names
    variable default_button_labels
    array set default_button_labels \
	[list back [_ acs-templating.Previous_with_arrow] \
             repeat [_ acs-kernel.common_Repeat] \
             next [_ acs-templating.Next_with_arrow] \
             finish [_ acs-kernel.common_Finish]]
  }

  namespace eval paginator {
    
    # stack level at which paginator is created
    variable parse_level

    # Default values for paginator properties
    variable defaults
    set defaults [list pagesize 20 timeout 600 groupsize 10 page_offset 0]
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

