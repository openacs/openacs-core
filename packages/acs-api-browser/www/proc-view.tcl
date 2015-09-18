ad_page_contract {
    Display information about one procedure.
    
    @cvs-id $Id$
} {
    proc:token,trim
    source_p:boolean,optional,trim
    {version_id:naturalnum,optional ""}
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
if { $version_id ne "" } {
    db_0or1row package_info_from_package_id {
        select pretty_name, package_key, version_name
        from apm_package_version_info
        where version_id = :version_id
    }
    if {[info exists package_id]} {
        lappend context [list [export_vars -base package-view {version_id {kind procs}}] \
                             "$pretty_name $version_name"]
    }
}
lappend context [list $proc]

set default_source_p [ad_get_client_property -default 0 acs-api-browser api_doc_source_p]
set return_url [export_vars -base [ad_conn url] {proc version_id}]
set error_msg ""

if { ![info exists source_p] } {
    set source_p $default_source_p
}

if {[string match ::* $proc]} {
    set absolute_proc $proc
    set relative_proc [string range $proc 2 end]
} else {
    set absolute_proc ::$proc
    set relative_proc $proc
}

set documented_call [nsv_exists api_proc_doc $relative_proc]
if {$documented_call} {
    set proc_index $relative_proc
} else {
    set documented_call [nsv_exists api_proc_doc $absolute_proc]
    set proc_index $absolute_proc
}

if { !$documented_call } {
    if {[info procs $absolute_proc] eq $absolute_proc} { 

        template::head::add_style -style {pre.code {
            background: #fefefa; 
            border-color: #aaaaaa; 
            border-style: solid;
            border-width: 1px; 
        }}
        set error_msg [subst {
            <p>This procedure is defined in the server but not
            documented via ad_proc or proc_doc and may be intended as
            a private interface.</p><p>The procedure is defined as:
<pre class='code'>
proc $proc {[info args $proc]} {
    [ns_quotehtml [info body $proc]]
}
</pre></p>
        }]
    } elseif {[info commands $absolute_proc] eq $absolute_proc} { 

        set result [util_memoize [list ::util::http::get -url $::apidoc::ns_api_html_index]]
        set page [dict get $result page]

        set url [apidoc::search_on_webindex \
                     -page $page \
                     -root $::apidoc::ns_api_root \
                     -host $::apidoc::ns_api_host \
                     -proc $relative_proc]
        
        if {$url ne ""} {
            ns_log notice "api-doc/www/proc-view got URL <$url>"
            ad_returnredirect -allow_complete_url $url
            ad_script_abort
        }

        set result [util_memoize [list ::util::http::get -url $::apidoc::tcl_api_html_index]]
        set page [dict get $result page]

        # Strip the end of the Tcl-URL to obtain the root
        regexp {^(.*)/[^/]+} $::apidoc::tcl_api_html_index _ root
        append root /

        set url [apidoc::search_on_webindex -page $page -root $root -host $root -proc $proc]
        
        if {$url ne ""} {
            ad_returnredirect -allow_complete_url $url
            ad_script_abort
        }

        set error_msg [subst {

            <p>The command <b>$proc</b> is an available command on
            the server and might be found in the <a
            href="$::apidoc::tcl_api_html_index">Tcl</a>
            or <a href="$::apidoc::ns_api_html_index">[ns_info name]</a>
            documentation or in documentation for a loadable module.
            </p>
        }]

    } else { 
        set error_msg "<p>The procedure <b>$proc</b> is not defined in the server.</p>"
    }
} else {

    if { $source_p } {
        set documentation [api_proc_documentation -script -xql -source $proc_index]
    } else {
        set documentation [api_proc_documentation -script $proc_index]
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
