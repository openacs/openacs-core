# Wizard tool for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)

# $Id$

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

ad_proc -public template::wizard { command args } {

  eval wizard::$command $args
}

# create a wizard from a set of steps

ad_proc -public template::wizard::create { args } {

  set level [template::adp_level]

  variable parse_level
  set parse_level $level

  # keep wizard properties and a list of the steps
  upvar #$level wizard:steps steps wizard:properties opts 
  upvar #$level wizard:rowcount rowcount

  template::util::get_opts $args

  set steps [list]
  set rowcount 0

  # add steps specified at the time the wizard is created
  if { [info exists opts(steps)] } {

    # strip carriage returns
    regsub -all {\r} $opts(steps) {} step_data

    foreach step [split $step_data "\n"] {

      set step [string trim $step]
      if { [string equal $step {}] } { continue }

      eval add $step
    }
  }
}

# Set a wizard's param for passthrough
ad_proc -public template::wizard::set_param { name value } {

  set level [template::adp_level]

  upvar #$level wizard:params params

  set params($name) $value
}

# Append a step to a wizard

ad_proc -public template::wizard::add { step_id args } {

  get_reference

  lappend steps $step_id

  # add the reference to the steps lookup array for the wizard
  upvar #$level wizard:$step_id opts wizard:rowcount rowcount
  incr rowcount
  set opts(id) $step_id
  set opts(rownum) $rowcount
  set opts(link) [get_forward_url $opts(id)]

  # copy the reference for access as a multirow data source as well
  upvar #$level wizard:$rowcount props

  template::util::get_opts $args

  array set props [array get opts]
}

# Set the step to display for this particular request This is
# determined by the wizard_step parameter.  If not set, the first step
# is used.

ad_proc -public template::wizard::get_current_step {} {

  get_reference

  upvar #$level wizard:current_id current_id
  set current_id [ns_queryget wizard_step [lindex $steps 0]]

  # get a reference to the step
  upvar #$level wizard:$current_id step 

  upvar #$level wizard:current_url current_url

  set current_url $step(url)

  # check for a "back" submission and forward immediately if so
  
  if { [ns_queryexists wizard_submit_back] } {

    set last_index [expr [lsearch -exact $steps $current_id] - 1]
    set last_id [lindex $steps $last_index]
    template::forward [get_forward_url $last_id]
  }
}

ad_proc -public template::wizard::current_step {} {

  get_reference

  return [ns_queryget wizard_step [lindex $steps 0]]
}

# Add the appropriate buttons to the submit wizard
# Also create a list of all the buttons
# The optional -buttons parameter is a list of name-value pairs,
# in form {name label} {name label...}
# The valid button names are back, next, repeat, finish
ad_proc -public template::wizard::submit { form_id args } {

  variable default_button_labels

  get_reference
  upvar 2 wizard_submit_buttons buttons
  set buttons [list]

  template::util::get_opts $args
 
  # Handle the -buttons parameter
  if { ![info exists opts(buttons)] } {
    upvar 0 default_button_labels button_labels 
  } else {
    foreach pair $opts(buttons) { 
      # If provided with just a name, use default label
      if { [llength $pair] == 1 } {
        set button_labels($pair) $default_button_labels($pair)
      } else {
        set button_labels([lindex $pair 0]) [lindex $pair 1]
      }
    }
  }
    
  set current_id [ns_queryget wizard_step [lindex $steps 0]]

  # Add a hidden element with the current ID
  template::element create $form_id wizard_step -widget hidden -value $current_id -datatype keyword

  set step_index [expr [lsearch -exact $steps $current_id] + 1]

  # If not the first one and it is allowed than add a "Back" button
  if { $step_index > 1 && [info exists button_labels(back)] } {
    template::element create $form_id wizard_submit_back -widget submit \
       -label $button_labels(back) -optional -datatype text

    lappend buttons wizard_submit_back
  }

  # If iteration is allowed than add a "Repeat" button
  upvar #$level wizard:$current_id step
  if { [info exists step(repeat)] && [info exists button_labels(repeat)]} {
    template::element create $form_id wizard_submit_repeat -widget submit \
      -label $button_labels(repeat) -optional -datatype text
    lappend buttons wizard_submit_repeat
  } 

  # If not the last one than add a "Next" button
  if { $step_index < [llength $steps] && [info exists button_labels(next)] } {
    template::element create $form_id wizard_submit_next -widget submit \
      -label $button_labels(next) -optional -datatype text
    lappend buttons wizard_submit_next
  } 

  # Always finish
  if { [info exists button_labels(finish) ] } {
    template::element create $form_id wizard_submit_finish -widget submit \
      -label $button_labels(finish) -optional -datatype text
    lappend buttons wizard_submit_finish
  }

  # Create hidden variables for wizard parameters
  foreach param $properties(params) {
    if { ![template::element::exists $form_id $param] } {
      template::element create $form_id $param -widget hidden -datatype text -optional -param
    }
  }
}

# Get a reference to the wizard steps (internal helper)

ad_proc -public template::wizard::get_reference {} {
  
  uplevel {

    variable parse_level
    set level $parse_level

    upvar #$level wizard:steps steps wizard:properties properties
    if { ! [info exists steps] } {
      error "Wizard does not exist"
    }
  }
}

# Return 1 if a wizard is currently defined

ad_proc -public template::wizard::exists {} {

  variable parse_level 

  if { ![info exists parse_level] } {
    return 0
  }

  upvar #$parse_level wizard:steps steps 

  return [info exists steps]
}

# call when a step has been validated and completed.
# checks which submit button was pressed and proceeds accordingly.

ad_proc -public template::wizard::forward {} {

  get_reference

  upvar #$level wizard:current_id current_id
  set current_index [expr [lsearch -exact $steps $current_id] + 1]

  if { [ns_queryexists wizard_submit_next] } {

    # figure out the next step and go there

    set next_id [lindex $steps $current_index]
    template::forward [get_forward_url $next_id]

  } elseif { [ns_queryexists wizard_submit_back] } {

    set last_id [lindex $steps [expr $current_index - 2]]
    template::forward [get_forward_url $last_id]

  } elseif { [ns_queryexists wizard_submit_repeat] } {
   
    template::forward "[get_forward_url $current_id]&wizard_submit_repeat=t"

  } elseif { [ns_queryexists wizard_submit_finish] } {

    template::forward $properties(action)
  }
}

# Build the redirect URL for the next step

ad_proc -public template::wizard::get_forward_url { step_id } {

  variable parse_level
  get_reference

  set level [template::adp_level]

  upvar #$level wizard:params params

  set url [ns_conn url]?wizard_step=$step_id

  # check for passthrough parameters

  if { [info exists properties(params)] } {
    foreach param $properties(params) {

      if { [info exists params($param)] } {
        set value $params($param)
      } else {
        set value [ns_queryget $param]
      }
      append url "&$param=[ns_urlencode $value]"
    }
  }

  return $url
}

# Retreive the URL to the action
ad_proc -public template::wizard::get_action_url {} {
  
  get_reference

  return $properties(action)
}
