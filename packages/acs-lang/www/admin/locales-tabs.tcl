#
# Tabs for workflow-page
#
# Input:
#   tab
#   locales
#   show_locales_p
#
# Data sources:
#   tabs:multirow name url
#
# Author: Lars Pind (lars@pinds.com)
# Author: Bruno Mattarollo (bruno.mattarollo@ams.greenpeace.org)
# Creation-date: Feb 26, 2001
# Cvs-id: $Id$
#

multirow create tabs name key url 

if { $show_locales_p == "t" } {

    set list_tabs [list { Locales locales } { Messages localized-messages } ]

} else {

    set list_tabs [list { Messages localized-messages } ]

}

foreach loop_tab $list_tabs {
    multirow append tabs [lindex $loop_tab 0] [lindex $loop_tab 1] ".?[export_vars -url {locales {tab {[lindex $loop_tab 1]}}}]"
}

#   { Timing timing } 
#   { Actions actions } 

