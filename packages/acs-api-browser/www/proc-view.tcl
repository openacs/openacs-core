ad_page_contract {
    Display information about one procedure.
    
    @cvs-id $Id$
} {
    proc
    source_p:optional,integer,trim
    {version_id ""}
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

set context [list]
if { [exists_and_not_null version_id] } {
    db_1row package_info_from_package_id {
        select pretty_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    lappend context [list "package-view?version_id=$version_id&kind=procs" "$pretty_name $version_name"]
}
lappend context [list $proc]

set default_source_p [ad_get_client_property -default 0 acs-api-browser api_doc_source_p]
set return_url [ns_urlencode [ad_conn url]?[export_url_vars proc version_id]]
set error_msg ""

if { ![info exists source_p] } {
    set source_p $default_source_p
}

# Try and be helpful about the procedure.
if { ![nsv_exists api_proc_doc $proc] } {
    if {![empty_string_p [namespace eval :: [list info procs $proc]]]} { 
        set error_msg "<p>This procedure is defined in the server but not documented via ad_proc or proc_doc and may be intended as a private interface.</p><p>The procedure is defined as: <pre>
proc $proc {[info args $proc]} {
[ad_quotehtml [info body $proc]]
}</pre></p>"
    } elseif {![empty_string_p [namespace eval :: [list info commands $proc]]]} { 
        set error_msg "<p>The procedure <b>$proc</b> is an available command on the server and might be found in the <a href=\"http://dev.scriptics.com/man/tcl8.3/TclCmd/contents.htm\">TCL</a> or <a href=\"http://www.aolserver.com/docs/devel/tcl/api/\">AOLServer</a> documentation or in documentation for a loadable module (like ns_cache for example).</p>"
    } else { 
        set error_msg "<p>The procedure <b>$proc</b> is not defined in the server.</p>"
    }
} else {

    if { $source_p } {
	set documentation [api_proc_documentation -script -xql -source $proc]
    } else {
	set documentation [api_proc_documentation -script $proc]
    }
}
