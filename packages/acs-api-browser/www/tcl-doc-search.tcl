ad_page_contract {
    Will redirect you to dev.scriptics.com if documentation can be found
    @cvs-id $Id$
} {
    tcl_proc
} -properties {
    title:onevalue
    context_bar:onevalue
    tcl_proc:onevalue
}

set tcl_docs_root "http://dev.scriptics.com/man/tcl[info tclversion]/TclCmd/"

set tcl_docs_url "${tcl_docs_root}contents.htm"

set tcl_docs_index_page [util_memoize "ns_httpget $tcl_docs_url"]

set tcl_proc [lindex $tcl_proc 0] 

set len [string length $tcl_proc]

for { set i [expr { $len-1 }] } { $i >= 0 } { incr i -1 } {
    set search_for [string range $tcl_proc 0 $i]
    if { [regexp "<a href=\"(\[^>\]+)\">$search_for</a>" $tcl_docs_index_page match relative_url] } {
        ad_returnredirect "$tcl_docs_root$relative_url"
        return
    } 
}

set title "Tcl API Procedure Search for: \"$tcl_proc\""
set context_bar [ad_context_bar "TCL API Search: $tcl_proc"]

ad_return_template
