ad_library {
    Definition of dimensional selection bar widget

    @cvs-id $Id$
}

# TODOS:
# May be deprecate the following functions of table-display-procs.
#
#   ad_dimensional_sql
#   ad_dimensional_set_variables
#   ad_order_by_from_sort_spec
#   ad_same_page_link
#   ad_reverse
#   ad_custom_load
#   ad_custom_list
#   ad_custom_page_defaults
#   ad_custom_form
#   ad_dimensional_settings
#
# Add Package Parameter DefaultDimensionalStyle to acs-subsite
# Check style-switcher callback in theme package
#
# Dimensional selection bars.
#

ad_proc ad_dimensional {
    {-style ""}
    option_list
    {url {}}
    {options_set ""}
    {optionstype url}
} {
    Generate an option bar:

    @param style name of the adp file (without extension)
    @param option_list the structure with the option data provided 
    @param url url target for select (if blank we set it to ad_conn url).
    @param options_set if not provided defaults to [ns_getform], for hilite of selected options.
    @param optionstype only url is used now, was thinking about extending 
            so we get radio buttons and a form since with a slow select updating one 
            thing at a time would be stupid.
    @return HTML rendering
    
    <p>
    option_list structure is 
    <pre>
    { 
        {variable "Title" defaultvalue
            {
                {value "Label"}
                ...
            }
        }
        ...
    }

    an example:

    set dimensional_list {
        {visited "Last Visit" 1w {
            {never "Never"}
            {1m "Last Month"}
            {1w "Last Week"}
            {1d "Today"}
        }}
        ..(more of the same)..
    }
    </pre>
} {
    if {$option_list eq ""} {
        return
    }

    if {$options_set eq ""} {
        set options_set [ns_getform]
    }
    
    if {$url eq ""} {
        set url [ad_conn url]
    }

    if {$style eq ""} {
	set style [parameter::get \
		       -package_id [ad_conn subsite_id] \
		       -parameter DefaultDimensionalStyle \
		       -default "dimensional-table"]
    }

    if {[regexp {^/(.*)} $style path]} {
        set adp_stub $path
    } else {
        set adp_stub /packages/acs-templating/resources/dimensional/$style
    }

    #
    # Create nested adp-arrays. Since the templating system does not
    # support this (we need an oo-templating) this is emulated here
    # via multiple multirows, where the names of the inner multirows
    # are dynamically generated.
    #
    template::multirow create dimensional key label
    set arrays {}

    foreach option $option_list {
	lassign $option option_key option_label option_default option_values

	template::multirow append dimensional $option_key $option_label
	#
	# Find out what the current option value is.
	# check if a default is set otherwise the first value is used
	#
	set option_val {}
	if { $options_set ne ""} {
	    set option_val [ns_set get $options_set $option_key]
	}
	if { $option_val eq "" } {
	    set option_val $option_default
	}
	#
	# Manage the names of the innner multirows, and pass all inner
	# multirows to the outer template such it becomes visible in
	# the inner template.
	#
	set array opt_$option_key
	lappend arrays &$array $array

	template::multirow create $array key label current count href
	set count 0
	
	foreach option_value $option_values {
	    lassign $option_value key label clause

	    template::multirow append $array \
		$key $label [expr {$option_val eq $key}] [incr count] \
		$url?[export_ns_set_vars url $option_key $options_set]&[ns_urlencode $option_key]=[ns_urlencode $key]
	}
	
    }
    
    #
    # Finally, pass everything to the templating engine. The outer
    # template contains an "<include...>" for the inner template.
    #
    return [template::adp_include -uplevel 2 -- $adp_stub [list &dimensional dimensional {*}$arrays]]
}

