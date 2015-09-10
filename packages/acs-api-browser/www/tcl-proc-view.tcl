ad_page_contract {
    Will redirect you to the server containing the documentation if it can be found
    @cvs-id $Id$
} {
    tcl_proc:token,notnull
} -properties {
    title:onevalue
    context:onevalue
    tcl_proc:onevalue
}

set ns_api_index_result [util_memoize [list ::util::http::get -url $::apidoc::ns_api_html_index]]
set ns_api_index_page [dict get $ns_api_index_result page]

#
# Since man pages contain often a summary of multiple commands, try
# abbreviation in case the full name is not found (e.g. man page "nsv"
# contains "nsv_array", "nsv_set" etc.)
#
for {set i [string length $tcl_proc]} {$i > 1} {incr i -1} {
    set proc [string range $tcl_proc 0 $i]
    set url [apidoc::search_on_webindex \
		 -page $ns_api_index_page \
		 -root $::apidoc::ns_api_root \
		 -host $::apidoc::ns_api_host \
		 -proc $proc]
    if {$url ne ""} break
}

if {$url ne ""} {
    ad_returnredirect -allow_complete_url $url
    ad_script_abort
} 

set title "[ns_info name] Tcl API Search for: \"$tcl_proc\""
set context [list "Tcl API Search: $tcl_proc"]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
