ad_library {
    Definition of dimensional selection bar widget and helper functions.

    @cvs-id $Id$
}

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
    Generate an option bar from an option_list, which has the structure:
    <pre>
    {
        {variable "Title" defaultvalue
            {
                {value "Label" {key sql-clause}}
                ...
            }
        }
        ...
    }
    </pre>

    Here is an example of the option_list:
    <pre>
    set dimensional_list {
        {visited "Last Visit" 1w {
            {never "Never" {where "last_visit is null"}}
            {1m "Last Month" {where "last_visit + 30 > sysdate"}}
            {1w "Last Week" {where "last_visit + 7 > sysdate"}}
            {1d "Today" {where "last_visit > trunc(sysdate)"}}
        }}
        ..(more of the same)..
    }
    </pre>

    @param style name of the adp file (without extension)
    @param option_list the structure with the option data provided
    @param url url target for select (if blank we set it to ad_conn url).
    @param options_set if not provided defaults to [ns_getform], for hilite of selected options.
    @param optionstype only url is used now, was thinking about extending
           so we get radio buttons and a form since with a slow select updating one
           thing at a time would be stupid.
    @return HTML rendering
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
                       -default "dimensional"]
    }

    #
    # Get the path. template::include needs a relative path.
    #
    set adp_stub [template::resource_path -type dimensionals -style $style -relative]

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

ad_proc ad_dimensional_sql {
    option_list
    {what "where"}
    {joiner "and"}
    {options_set ""}
} {

    Given what clause we are asking for and the joiner this returns
    the sql fragment

    @param option_list the structure with the option data provided
    @param what look for such keys in the option_list
    @param joiner join string for combining multiple clases
    @param options_set ns_set for reading variables
    @return SQL clause

    @see ad_dimensional
} {
    set out {}

    if {$option_list eq ""} {
        return
    }

    if {$options_set eq ""} {
        set options_set [ns_getform]
    }

    foreach option $option_list {
        # find out what the current option value is.
        # check if a default is set otherwise the first value is used
        set option_key [lindex $option 0]
        set option_val {}
        # get the option from the form
        if { $options_set ne ""} {
            set option_val [ns_set get $options_set $option_key]
        }
        #otherwise get from default
        if { $option_val eq "" } {
            set option_val [lindex $option 2]
        }

        foreach option_value [lindex $option 3] {
            set thisoption [lindex $option_value 0]
            if {$option_val eq $thisoption } {
                set code [lindex $option_value 2]
                if {$code ne ""} {
                    if {[lindex $code 0] eq $what } {
                        append out " $joiner [uplevel [list subst [lindex $code 1]]]"
                    }
                }
            }
        }
    }

    return $out
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:

