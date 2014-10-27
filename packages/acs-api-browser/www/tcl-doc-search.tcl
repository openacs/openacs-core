ad_page_contract {
    Will redirect you to dev.scriptics.com if documentation can be found
    @cvs-id $Id$
} {
    tcl_proc
} -properties {
    title:onevalue
    context:onevalue
    tcl_proc:onevalue
}

set tcl_docs_root "http://tcl.tk/man/tcl[info tclversion]/TclCmd/"
set tcl_docs_url "${tcl_docs_root}contents.htm"

with_catch errmsg {
    set tcl_docs_index_result [util_memoize [list util::http::get -url $tcl_docs_url]]
    set tcl_docs_index_page [dict get $tcl_docs_index_result page]
} {
    ad_return_error "Cannot Connect" "We're sorry, but we're having problems connecting to the server containing the Tcl documentation: $tcl_docs_url"
    ad_script_abort
}

set tcl_proc [lindex $tcl_proc 0] 
set len [string length $tcl_proc]

for { set i [expr { $len-1 }] } { $i >= 0 } { incr i -1 } {
    set search_for [string range $tcl_proc 0 $i]
    if { [regexp "<a href=\"(\[^>\]+)\">$search_for</a>" $tcl_docs_index_page match relative_url] } {
        ad_returnredirect -allow_complete_url "$tcl_docs_root$relative_url"
        ad_script_abort
    } 
}

set title "Tcl API Procedure Search for: \"$tcl_proc\""
set context [list "Tcl API Search: $tcl_proc"]
