ad_library {
    Procs related to automated testing coverage

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-29
    @cvs-id $Id$
}

namespace eval ::aa::coverage {}

ad_proc -public aa::coverage::proc_covered_p {
    proc_name
} {
    Checks if the proc 'proc_name' is covered by any automated test.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-29

    @param proc_name The name of the proc to check.

    @return 'true' if the proc is covered, 'false' otherwise.
} {
    if {[dict exists [nsv_get api_proc_doc $proc_name] testcase]} {
        return true
    } else {
        return false
    }
}


ad_proc -public aa::coverage::proc_list {
    {-package_key ""}
} {
    Creates a list of the procs belonging to a particular package, with its
    current automated testing covered status, excluding deprecated, callback
    contracts and not public procs.

    If no 'package_key' is passed, or the value of the provided
    package_key is an empty string, then the system wide test proc
    coverage is returned.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-29

    @param package_key  The 'package_key' of the package to check.

    @return List of dicts, each one with the following values:
            - package_key: the package key of the package, if the 'package_key'
              parameter is empty.
            - proc_name: the proc name.
            - covered_p: boolean, 'true' if the proc is covered by any automated
              test, false otherwise.
} {
    set procs [list]
    foreach path [nsv_array names api_proc_doc_scripts] {
        if { [regexp "^packages/" $path] } {
            set package_name [lindex [split $path "/"] 1]
            if { $package_key eq "" || $package_key eq $package_name } {
                foreach proc_name [nsv_get api_proc_doc_scripts $path] {
                    unset -nocomplain proc_doc
                    array set proc_doc [nsv_get api_proc_doc $proc_name]
                    if { [info exists proc_doc(protection)]
                         && "public" in $proc_doc(protection)
                         && !($proc_doc(deprecated_p) || $proc_doc(warn_p))
                         && ![regexp {^callback::.*::contract$} $proc_name]
                         && ![string match xo::db::sql::* $proc_name]
                         && ![string match acs::db::nsdb* $proc_name]
                         && ![string match " Class *" $proc_name]
                         && ![string match " Object *" $proc_name]
                     } {
                        #ns_log notice "proc-doc, for <$proc_name>"
                        set proc_data [dict create]
                        if { $package_key eq "" } {
                            dict set proc_data package_key $package_name
                        }
                        dict set proc_data proc_name $proc_name
                        dict set proc_data covered_p [info exists proc_doc(testcase)]
                        lappend procs "$proc_data"
                    }
                }
            }
        }
    }
    return $procs
}

ad_proc -public aa::coverage::proc_coverage {
    {-package_key ""}
} {
    Calculates the test proc coverage of a particular package.

    If no 'package_key' is passed, then the system wide test proc coverage is
    returned.

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-28

    @param package_key  The 'package_key' of the package to check.

    @return Dict with the number of procs (procs), covered procs (covered) and
            the coverage percentage (coverage).

} {
    set procs 0
    set procs_covered 0
    #
    # Get proc list to check
    #
    if { $package_key ne "" } {
        set proc_list [aa::coverage::proc_list -package_key $package_key]
    } else {
        set proc_list [aa::coverage::proc_list]
    }
    #
    # Count the covered procs
    #
    foreach proc_data $proc_list {
        incr procs
        if { [dict get $proc_data covered_p] } {
            incr procs_covered
        }
    }
    #
    # Return the coverage percentage
    #
    if { $procs eq 0 } {
        set coverage 100.0
    } else {
        set coverage [expr {($procs_covered / ($procs + 0.0)) * 100}]
    }
    return "procs $procs covered $procs_covered coverage [format {%0.2f} $coverage]"
}

ad_proc -private aa::percentage_to_color {
    percentage
} {
    Calculates background and foreground color from a percentage. 0
    gives red, 100 gives green.

    @author Gustaf neumann

    @param percentage A value between 0 and 100.0
    @return color code in hex (three double-digit figures)
} {
    set red 255
    set green 255
    if {$percentage >= 0 && $percentage <= 50} {
        set green [expr {int(510 * $percentage/100.0)}]
    } elseif {$percentage > 50.0 && $percentage <= 100.0} {
        set red [expr {int(-510 * $percentage/100.0 + 510)}]
    }
    # Luminance as defined by HDTV
    #set luminance [expr {0.2126*$red + 0.7152*$green + 0.0722*0}]
    # luminance as defined by UHDTV, HDR
    set luminance [expr {0.2627*$red + 0.6780*$green + 0.0593*0}]    
    return [list \
                background #[format %.2x $red][format %.2x $green]00 \
                foreground [expr {$luminance < 120 ? "#ffffff": "#000000"}] \
               ]
}

ad_proc -public aa::coverage::proc_coverage_level {
    coverage
} {
    Calculates the level (high, medium, low...) of proc coverage from a
    particular value.

    This proc centralizes the levels for the different values, in order to keep
    consistency.

    Current values are:
        <25:  very_low
        <50:  low
        <75:  medium
        <100: high
        100:  full

    @author Héctor Romojaro <hector.romojaro@gmail.com>
    @creation-date 2019-08-28

    @param coverage The percentage of the procs covered by automated tests.

    @return A string (e.g: 'high')
} {
    if { $coverage < 25 } {
        return very_low
    } elseif { $coverage < 50 } {
        return low
    } elseif { $coverage < 75 } {
        return medium
    } elseif { $coverage < 100 } {
        return high
    } elseif { $coverage == 100 } {
        return full
    } else {
        return -code error "Error: Invalid coverage percentage"
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
