ad_page_contract {
    Will redirect you to the server containing the documentation if it can be found
    @cvs-id $Id$
} {
    tcl_proc
} -properties {
    title:onevalue
    context:onevalue
    tcl_proc:onevalue
}

set ns_api_index_result [util_memoize [list ::util::http::get -url $::apidoc::ns_api_html_index]]
set ns_api_index_page [dict get $ns_api_index_result page]

set url [apidoc::search_on_webindex \
	     -page $ns_api_index_page \
	     -root $::apidoc::ns_api_root \
	     -host $::apidoc::ns_api_host \
	     -proc $tcl_proc]

if {$url ne ""} {
    ad_returnredirect -allow_complete_url $url
    ad_script_abort
} 

set title "[ns_info name] Tcl API Search for: \"$tcl_proc\""
set context [list "Tcl API Search: $tcl_proc"]
