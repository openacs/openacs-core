ad_page_contract {
    Display information about one procedure.
    
    @cvs-id $Id$
} {
    proc
    source_p:optional,integer,trim
} -properties {
    title:onevalue
    context:onevalue
    source_p:onevalue
    default_source_p:onevalue
    return_url:onevalue
    documentation:onevalue
    error_msg:onevalue
}

set title $proc
set context [list $proc]

set default_source_p [ad_get_client_property -default 0 acs-api-browser api_doc_source_p]
set return_url [ns_urlencode [ad_conn url]?[export_url_vars proc]]
set error_msg ""

if { ![info exists source_p] } {
    set source_p $default_source_p
}

if { ![nsv_exists api_proc_doc $proc] } {
    set error_msg "This proc is not defined with ad_proc or proc_doc"
} else {

    if { $source_p } {
	set documentation [api_proc_documentation -script -source $proc]
    } else {
	set documentation [api_proc_documentation -script $proc]
    }
}
