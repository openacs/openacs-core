ad_page_contract {
    Will redirect you to aolserver.com if documentation can be found
    @cvs-id $Id$
} {
    tcl_proc
} -properties {
    title:onevalue
    context:onevalue
    tcl_proc:onevalue
}

# old aolserver documentation
#set tcl_api_host  "http://www.aolserver.com/"
#set tcl_api_index "docs/devel/tcl/api/"

# wiki on panpotic
#set tcl_api_host  "http://panoptic.com/"
#set tcl_api_index "wiki/aolserver/Tcl_API"
#set tcl_api_root ${tcl_api_host}${tcl_api_index}
#set tcl_api_index_page [util_memoize [list ns_httpget $tcl_api_root]]

# naviserver at sourceforge
set tcl_api_host  "http://naviserver.sourceforge.net/"
set tcl_api_index "n/naviserver/files/"
set tcl_api_root ${tcl_api_host}${tcl_api_index}
set tcl_api_html_index $tcl_api_root/commandlist.html
set tcl_api_index_result [util_memoize [list util::http::get -url $tcl_api_html_index]]
set tcl_api_index_page [dict get $tcl_api_index_result page]

set tcl_proc [lindex $tcl_proc 0]

for { set i [expr { [string length $tcl_proc] - 1 }] } { $i >= 0 } { incr i -1 } {
    set search_for [string range $tcl_proc 0 $i]
    if { [regexp "<a href= *\['\"\](\[^>\"'\]+)\[\"'\]\[^>\]*>$search_for</a>" $tcl_api_index_page match relative_url] } {
        if {[string match "/*" $relative_url]} {
          set url ${tcl_api_host}$relative_url
        } else {
          set url ${tcl_api_root}$relative_url
        }
        ad_returnredirect -allow_complete_url $url
        ad_script_abort
    } 
}

set title "AOLserver Tcl API Search for: \"$tcl_proc\""
set context [list "TCL API Search: $tcl_proc"]
