# Wizard tool for the ArsDigita Templating System

# Copyright (C) 1999-2000 ArsDigita Corporation
# Authors: Karl Goldstein    (karlg@arsdigita.com)
# heavily modified by Jun Yamog on June 2003

# wizard-procs.tcl,v 1.1.2.1 2001/01/04 20:14:57 brech Exp

# This is free software distributed under the terms of the GNU Public
# License.  Full text of the license is available from the GNU Project:
# http://www.fsf.org/copyleft/gpl.html

namespace eval template {}
namespace eval template::wizard {}

ad_proc -public template::wizard { command args } {
    alias proc to call the real template::wizard::proc

    @see template::wizard::add
    @see template::wizard::create
    @see template::wizard::current_step
    @see template::wizard::exists
    @see template::wizard::forward

    @see template::wizard::get_action_url
    @see template::wizard::get_current_name
    @see template::wizard::get_current_step
    @see template::wizard::get_forward_url
    @see template::wizard::get_param
    @see template::wizard::get_reference
    @see template::wizard::get_visited_step
    @see template::wizard::get_wizards
    @see template::wizard::get_wizards_levels

    @see template::wizard::load_last_visited_step
    @see template::wizard::save_last_visited_step

    @see template::wizard::set_finish_url
    @see template::wizard::set_param
    @see template::wizard::set_visited_step

    @see template::wizard::submit
} {
    eval wizard::$command $args
}

# create a wizard from a set of steps

ad_proc -public template::wizard::create { args } { 
    <pre>example:
    template::wizard create -action "wizard" -name my_wizard -params {
	my_param1 my_param2
    } -steps {
	1 -label "Step 1" -url "step1"
	2 -label "Step 2" -url "step2"	
	3 -label "Step 3" -url "step3"
    }
    </pre>
    <ul>
    <li>action - the url where the wizard will always submit, normally its the
    same as your current wizard file.  Has no effect for subwizards.</li>
    <li>name - use to distinguish between the different wizards, since you can
    have 1 or more subwizard. name must be no spaces, alpanumeric similar
    to normal tcl variable naming convention</li>
    <li>params - are used to keep values that you would like to pass on to 
    the other steps</li>
    <li>steps - are use to define what includes to use for each step of the
    wizard</li>
    </ul>
    </li>

    @see template::wizard
} {

    set level [template::adp_level]

    variable parse_level
    set parse_level $level

    # keep wizard properties and a list of the steps
    upvar #$level wizard:steps steps wizard:properties opts 
    upvar #$level wizard:rowcount rowcount
    upvar #$level wizard:columns columns
    upvar #$level wizard:name wizard_name
    upvar #$level wizard:wizards wizards

    template::util::get_opts $args

    set steps [list]
    set rowcount 0
    if { [info exists opts(name)] } {
	set wizard_name $opts(name)
    } else {
	set wizard_name "wizard${level}"
    }
    set wizards [get_wizards]

    set columns [list label rownum id link url]

    # lets add the visited step param
    lappend opts(params) wizard_visitedstep${wizard_name}

    # add steps specified at the time the wizard is created
    if { [info exists opts(steps)] } {

	# strip carriage returns
	regsub -all {\r} $opts(steps) {} step_data

	foreach step [split $step_data "\n"] {

	    set step [string trim $step]
	    if {$step eq {}} { continue }

	    eval add $step
	}
    }
}

ad_proc -public template::wizard::get_param { name } {
    <p>Get a wizard's param value</p>
    <p>
    "template::wizard get_param" has the advantage over ad_page_contract of getting the
    param value during the response time.  What does this mean?  It will properly
    get the current value of the param which was set by "template::wizard set_param",
    while ad_page_contract will not pick that up since it will get what is the request
    http var value.  This is because "template::wizard get_param" gets the value
    from the tcl var while ad_page_contract gets the value from the http var.
    So while processing in tcl that value may change.
    </p>

    @see template::wizard
} {

    set level [template::adp_level]

    upvar #$level wizard:params params

    if { [info exists params($name)] } {
        set value $params($name)
    } else {
        set value [ns_queryget $name]
    }
    return $value

}


ad_proc -public template::wizard::set_param { name value } { 
    <p>Set a wizard's param for passthrough</p>

    <p>Normally you place this in the steps of the wizard where the 
    form has been processed.  A param
    is normally used when you want to reuse a value across the steps.</p>

    <p>Note: if you are to use "template::wizard set_param" on a wizard file ex. 
    (wizard.tcl).  Make sure to do it before "template::wizard get_current_step".
    So when "template::wizard get_current_step" redirects it will properly set
    the correct values of the param to the new value.</p>

    @see template::wizard
} {

    set level [template::adp_level]

    upvar #$level wizard:params params
    set params($name) $value

}


ad_proc -public template::wizard::set_finish_url { finish_url } { 
    <p>if the finish url is set, when a the finish button is pressed
    it will redirect to this url</p>

    @see template::wizard
} {
    get_reference
    set wizard_finish_url $finish_url

}


ad_proc -private template::wizard::add { step_id args } {
    Append a step to a wizard

    @see template::wizard
} {
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


ad_proc -public template::wizard::get_current_step {
    -start
} {
    <p>Set the step to display for this particular request This is
    determined by the wizard_step parameter.  If not set, the first step
    is used.</p>

    <p>Make sure that you call any "template::wizard set_param" if needed before 
    calling get_current_step.  get_current_step will redirect to the wizard -action
    properly setting all -params value and its other needed http state vars</p>

    <p>The wizard will rewrite the url always.  Only self submitting forms
    are preserved.  Once the form is finished processing the wizard will take
    over and rewrite the url.</p>

    @param start Optionally specify 
    
    @see template::wizard
} {
    get_reference

    upvar #$level wizard:current_id current_id
    set current_id [ns_queryget wizard_step${wizard_name} {}]
    if { $current_id eq "" } {
        if { [info exists start] } {
            set current_id $start
        } else {
            set current_id [lindex $steps 0]
        }
    }

    upvar #$level wizard:visited_step visited_step
    set visited_step [get_visited_step]

    # if there is no step state, we are likely in the first step.
    # lets redirect with the proper state vars
    if {[ns_queryget wizard_step${wizard_name}] eq ""} {
	template::forward [get_forward_url $current_id]
    }

    # get a reference to the step
    upvar #$level wizard:$current_id step 

    upvar #$level wizard:current_url current_url

    # lets see if this step exists, if not we are finished with wizard and pass the steps
    if {[info exists step(url)]} {
	set current_url $step(url)
    } else {
	# if we have set_finish_url then we redirect to that url when we are finished
	# otherwise increment the parent wizard step
	if {[info exists wizard_finish_url]} {
	    template::forward $wizard_finish_url
	} else {

	    # lets set the current wizard name to the parent wizard
	    set parent_wizard [lindex $wizards 0]
	    set wizard_name $parent_wizard

	    # lets now increment step of the parent wizard
	    set parent_step [expr {[ns_queryget wizard_step${parent_wizard}] + 1}]
	    template::forward [get_forward_url $parent_step]
	}
	
    }

    # check for a "back" submission and forward immediately if so
    # also check if we are backing up the current wizard or another wizard
    
    if { [ns_queryexists wizard_submit_back] && $wizard_name eq [ns_queryget wizard_name]} {

	set last_index [expr {[lsearch -exact $steps $current_id] - 1}]
	set last_id [lindex $steps $last_index]

        # LARS: I removed this, because it causes forms to not save their changes when you hit the back button
        # If you construct your form, so it calls 'wizard forward' in the -after_submit block, things will 
        # work the way you expect them to
	#template::forward [get_forward_url $last_id]
    }
}

ad_proc -private template::wizard::current_step {} {
    convinience method to get the step for the http params or from the
    wizard step definition

    @see template::wizard
} {

    get_reference

    return [ns_queryget wizard_step${wizard_name} [lindex $steps 0]]
}


ad_proc -public template::wizard::get_visited_step {} {
    get the last visited step

    @see template::wizard
} {

    get_reference

    # lets create the visited steps for the current
    # lets see if the current step is greater what we have visited
    # otherwise we keep the current value
    set last_visitedstep [get_param wizard_visitedstep${wizard_name}]
    set current_step [current_step]
    if { ($last_visitedstep < $current_step) || $last_visitedstep eq "" } {
        return $current_step
    } else {
        return $last_visitedstep
    }

}

ad_proc -public template::wizard::set_visited_step {step_id} { 
    set the last visited step

    @see template::wizard
} {
    
    get_reference
    set_param wizard_visitedstep${wizard_name} $step_id
}


ad_proc -public template::wizard::get_current_name {} {
    get the current wizard name

    @see template::wizard
} {

    get_reference

    return $wizard_name
}


ad_proc -private template::wizard::get_wizards_levels {} {
    internal helper proc to get the different levels of wizards
    from current to parent

    @see template::wizard
} {
    variable parse_level
    set level [expr {$parse_level - 1}]

    set levels {}
    for {set i $level} {$i > 1} {set i [expr {$i - 1}]} {
        upvar #$i wizard:name parent_wizard
        if {[info exists parent_wizard]} {
            lappend levels $i
        } else {
            break
        }
    }

    return $levels

}


ad_proc -private template::wizard::get_wizards {} {
    we will get all the wizards that we have passed through

    @see template::wizard
} {

    set wizards {}
    set levels [get_wizards_levels]

    foreach i $levels {
        upvar #$i wizard:name parent_wizard
        if {[info exists parent_wizard]} {
            lappend wizards $parent_wizard
        }
    }

    return $wizards
}


ad_proc -public template::wizard::submit { form_id args } {
    <p>Add the appropriate buttons to the submit wizard
    Also create a list of all the buttons
    The optional -buttons parameter is a list of name-value pairs,
    in form {name label} {name label...}
    The valid button names are back, next, repeat, finish</p>

    <p>Also writes the params to the form as hidden elements to keep the
    state of the wizard.</p>

    <p>The following values are acceptable for the buttons: back, next and finish.
    Back buttons are not rendered if the step is the first step, like wise next
    buttons are not displayed if its the last step.  Finish can appear on any step
    and will finish the current wizard even if not all steps are done.</p>

    @see template::wizard
} {

    variable default_button_labels

    get_reference
    upvar 2 wizard_submit_buttons buttons
    set buttons [list]

    set param_level [template::adp_level]
    upvar #$param_level wizard:params params

    template::util::get_opts $args
    
    # Handle the -buttons parameter
    if { ![info exists opts(buttons)] } {
	# jkyamog - is this really correct?  when no buttons is present we put all of the buttons?
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
    
    # Add a hidden element for the current wizard name
    template::element create $form_id wizard_name -widget hidden -value $wizard_name -datatype keyword

    set current_id [current_step]

    # Add a hidden element with the current ID
    template::element create $form_id wizard_step${wizard_name} -widget hidden -value $current_id -datatype keyword


    set step_index [expr {[lsearch -exact $steps $current_id] + 1}]

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
    set levels [get_wizards_levels]
    lappend levels $level

    foreach onelevel $levels {
	upvar #$onelevel wizard:properties properties
	foreach param $properties(params) {
	    if { ![template::element::exists $form_id $param] } {
		if { [info exists params($param)] } {
		    template::element create $form_id $param -widget hidden -datatype text -optional -param -value $params($param)
		} else {
		    template::element create $form_id $param -widget hidden -datatype text -optional -param
		}
	    }
	}

    }

    # Create hidden variables for the other wizard steps and visited steps
    foreach one_wizard $wizards {
	if { ![template::element::exists $form_id wizard_step${one_wizard}] } {
	    template::element create $form_id wizard_step${one_wizard} -widget hidden \
		-datatype keyword -value [ns_queryget wizard_step${one_wizard}]
	}
	if { ![template::element::exists $form_id wizard_visitedstep${one_wizard}] } {
	    template::element create $form_id wizard_visitedstep${one_wizard} -widget hidden \
		-datatype keyword -value [ns_queryget wizard_visitedstep${one_wizard}]
	}
    }

}


ad_proc -private template::wizard::get_reference {} {
    Get a reference to the wizard steps (internal helper)

    @see template::wizard
} {
    
    uplevel {

	variable parse_level
	set level $parse_level

	upvar #$level wizard:steps steps wizard:properties properties wizard:name wizard_name wizard:wizards wizards wizard:finish_url wizard_finish_url
	if { ! [info exists steps] } {
	    error "Wizard does not exist"
	}
    }
}


ad_proc -public template::wizard::exists {} {
    @return 1 if a wizard is currently defined

    @see template::wizard
} {
    variable parse_level 

    if { ![info exists parse_level] } {
	return 0
    }

    upvar #$parse_level wizard:steps steps 

    return [info exists steps]
}


ad_proc -public template::wizard::forward { } {
    call when a step has been validated and completed.
    checks which submit button was pressed and proceeds accordingly.

    @see template::wizard
} {
    set cache_p "f"
    set persistent_p "f"
    set excluded_vars ""

    get_reference

    upvar #$level wizard:current_id current_id
    set current_index [expr {[lsearch -exact $steps $current_id] + 1}]

    if { [ns_queryexists wizard_submit_next] } {

	# figure out the next step and go there

	set next_id [lindex $steps $current_index]
	template::forward [get_forward_url $next_id] $cache_p $persistent_p $excluded_vars

    } elseif { [ns_queryexists wizard_submit_back] } {

	set last_id [lindex $steps [expr {$current_index - 2}]]
	template::forward [get_forward_url $last_id] $cache_p $persistent_p $excluded_vars

    } elseif { [ns_queryexists wizard_submit_repeat] } {
	
	template::forward "[get_forward_url $current_id]&wizard_submit_repeat=t" $cache_p $persistent_p $excluded_vars

    } elseif { [ns_queryexists wizard_submit_finish] } {

	#    template::forward $properties(action)
	# NOTE : we are changing the behaviour of wizard, when its finish it will not reset and go back
	# to step 1, it will blindly go forward and we will catch this on get_current_step
	set next_id [expr {$current_index + 1}]
	template::forward [get_forward_url $next_id] $cache_p $persistent_p $excluded_vars
    }
}

ad_proc -public template::wizard::get_forward_url { step_id } {
    Build the redirect URL for the next step

    @see template::wizard
} {

    variable parse_level
    get_reference

    set level [template::adp_level]

    upvar #$level wizard:params params

    set url [ns_conn url]?wizard_step${wizard_name}=$step_id&wizard_name=$wizard_name
  
    # create the wizards and keep track of their steps too
    foreach one_wizard $wizards {
        append url "&wizard_step${one_wizard}=[ns_queryget wizard_step${one_wizard}]"
        append url "&wizard_visitedstep${one_wizard}=[ns_queryget wizard_visitedstep${one_wizard}]"
    }

    set multiple_listed [list]

    # check for passthrough parameters

    if { [info exists properties(params)] } {
	foreach param $properties(params) {
	    upvar #$level $param value
	    set flags [split [lindex [split $param ":"] 1] ","]
	    if { [lsearch -exact [split [lindex [split $param ":"] 1] ","] "array"] != -1 || [array exists value] } {
		# Array
		foreach {index array_value} [array get value] {
		    if { [info exists array_value] && $array_value ne "" } {
			append url "&$param.$index=[ns_urlencode $array_value]"
		    } else {
			append url "&$param.$index="
		    }
		}
	    } else {
		# Normal Variable
		if { [lsearch -exact [split [lindex [split $param ":"] 1] ","] "multiple"] != -1 } {
		    # Multiple
		    set param [lindex [split $param ":"] 0]
		    if { [lsearch -exact $multiple_listed $param] == -1 } {
			foreach check_param $properties(params) {
			    if { [string equal [lindex [split $check_param ":"] 0] $param] } {
				set value_list [ns_querygetall $param]
				for { set i 0 } { $i < [llength $value_list] } { incr i } {
				    append url "&$param=[ns_urlencode [lindex $value_list $i]]"
				}
			    }
			}
			lappend multiple_listed $param
		    }
		} else {
		    # Normal Var
		    if { [info exists params($param)] } {
			append url "&$param=[ns_urlencode $params($param)]"
		    } else {
			append url "&$param=[ns_urlencode [ns_queryget $param]]"
		    }
		}
	    }
	}
    }

    return $url
}

ad_proc -public template::wizard::get_action_url {} {
    Retreive the URL to the action

    @see template::wizard
} {

get_reference

return $properties(action)
}


ad_proc -public template::wizard::load_last_visited_step {
    -key:required
} {
    loads the last visited step from the db

    @creation-date june 2003
    @author Jun Yamog

    @param key unique identifier for a particular wizard normally the main object_id the wizard
    is manipulating

    use this step before get_current_step

    @see template::wizard
} {

    get_reference
    
    # check the old visited step on the the state manager
    set visited_step [ad_get_client_property -default "" $key ${wizard_name}visited]
    if {$visited_step ne "" } {
        template::wizard::set_visited_step $visited_step
    }

}


ad_proc -public template::wizard::save_last_visited_step {
    -key:required
} {
    saves the last visisted step to the db

    @creation-date june 2003
    @author Jun Yamog

    @param key unique identifier for a particular wizard normally the main object_id the wizard
    is manipulating

    use this step after get_current_step

    @see template::wizard
} {

    get_reference

    # save the state of the visited step for this wizard
    if { $key ne "" } {
        ad_set_client_property $key ${wizard_name}visited [template::wizard::get_visited_step]
    }

}

