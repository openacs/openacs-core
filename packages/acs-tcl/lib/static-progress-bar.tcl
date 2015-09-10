# packages/acs-tcl/lib/static-progress-bar.tcl
#
# The OTHER progress-bar.adp is animated.
# include this to show a progress bar for an assessment (or other multi-page
# flow)
#
# @author Deds Castillo (deds@i-manila.com.ph)
# @creation-date 2004-11-08
#
# params: total (int) - number of pages in entire assessment
#         current (int) - current page being shown
#         finish (optional,boolean) - if supplied, then this is the final page
#         bgcolor background color
#         fontcolor color of text
#         bgimage URL of background image
#

# NOTE: shows progress in terms of pages, NOT questions

foreach required_param {total current} {
    if {![info exists $required_param]} {
        return -code error "$required_param is a required parameter."
    }
}

if {![info exists finish]} {
    set finish 0
}

if {![info exists bgcolor]} {
    set bgcolor "\#aaaaaa"
}

if {![info exists fontcolor]} {
    set fontcolor "white"
}

if {![info exists bgimage]} {
    set bgimage "/resources/acs-subsite/pb-bg.gif"
}

if {![info exists header_color]} {
    set header_color "black"
}

if { ($total == 0) || [string is true $finish] } {
    set percentage_done 100
} elseif {[info exists finished_page] && $finished_page == $current} {
    # subtract 1 from current, since we haven't completed this page yet
    set percentage_done [expr {round($current * 100.0 / $total)}]    
} else {
    # subtract 1 from current, since we haven't completed this page yet
    set percentage_done [expr {round(($current - 1) * 100.0 / $total)}]
}


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
