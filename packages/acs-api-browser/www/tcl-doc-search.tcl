ad_page_contract {
    Will redirect you to dev.scriptics.com if documentation can be found
    @cvs-id $Id$
} {
    tcl_proc:token,notnull
} -properties {
    title:onevalue
    context:onevalue
    tcl_proc:onevalue
} -validate {
    csrf { csrf::validate }
}


#
# Try Tcl command documentation
#

regexp {^(.*)/[^/]+} $::apidoc::tcl_api_html_index _ root
append root /

set url [apidoc::get_doc_url \
             -cmd $tcl_proc \
             -index $::apidoc::tcl_api_html_index \
             -root $root \
             -host $root]

if {$url ne ""} {
    ns_log notice "api-doc/www/proc-view got URL <$url>"
    ad_returnredirect -allow_complete_url $url
    ad_script_abort
}

set tcl_docs_url $::apidoc::tcl_api_html_index
set title "Tcl API Procedure Search for: \"$tcl_proc\""
set context [list "Tcl API Search: $tcl_proc"]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
