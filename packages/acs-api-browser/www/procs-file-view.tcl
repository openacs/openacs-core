ad_page_contract {
    Displays procs in a Tcl library file.

    @cvs-id $Id$
} {
    version_id:naturalnum,optional,notnull
    { public_p:boolean "" }
    path:path,trim
    source_p:boolean,optional,trim,notnull
} -properties {
    title:onevalue
    context:onevalue
    dimensional_slider:onevalue
    library_documentation:onevalue
    proc_list:multirow
    proc_doc_list:multirow
}

set url_vars [export_vars {path version_id}]
set return_url [ns_urlencode [ad_conn url]?][ns_urlencode $url_vars]

set default_source_p [ad_get_client_property -default 0 acs-api-browser api_doc_source_p]
if { ![info exists source_p] } {
    set source_p $default_source_p
    if {$source_p eq ""} {set source_p 0}
}
if { ![info exists version_id]
     && [regexp {^packages/([^ /]+)/} $path "" package_key] } {
    db_0or1row version_id_from_package_key {
        select version_id 
	from apm_enabled_package_versions 
	where package_key = :package_key
    }
}

set path [apidoc::sanitize_path $path]
if {![file readable ${::acs::rootdir}$path] || [file isdirectory ${::acs::rootdir}$path]} {
    if {[info exists version_id]} {
	set kind procs
	set href [export_vars -base [ad_conn package_url]/package-view {version_id {kind procs}}]
	set link [subst {<p>Go back to <a href="[ns_quotehtml $href]">Package Documentation</a>.}]
    } else {
	set link [subst {<p>Go back to <a href="[ns_quotehtml [ad_conn package_url]]">API Browser</a>.}]
    }
    ad_return_warning "No such library file" [subst {
	The file '$path' was not found. Maybe the url contains a typo.
	$link
    }]
    return
}


if {[info exists version_id]} {
    set public_p [::apidoc::set_public $version_id $public_p]
} else {
    set public_p [::apidoc::set_public "" $public_p]
}

set dimensional_list {
    {
        public_p "Publicity:" 1 {
            { 1 "Public Only" }
            { 0 "All" }
        }
    }
}

set context [list]
if { [info exists version_id] } {
    db_0or1row package_info_from_package_id {
        select pretty_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    if {[info exists pretty_name]} {
	lappend context [list [export_vars -base package-view {version_id}] "$pretty_name $version_name"]
    }

}

set path [string trimleft $path /]
lappend context [file tail $path]

set title [file tail $path]

set dimensional_slider [ad_dimensional $dimensional_list]
set library_documentation [api_library_documentation $path]

multirow create proc_list proc
multirow create proc_doc_list doc

if { [nsv_exists api_proc_doc_scripts $path] } {
    foreach proc [lsort [nsv_get api_proc_doc_scripts $path]] {
        if { $public_p } {
            array set doc_elements [nsv_get api_proc_doc $proc]
            if { $doc_elements(protection) ne "public"} {
                continue
            }
        }
        multirow append proc_list [api_proc_pretty_name -link $proc]
    }   
    foreach proc [lsort [nsv_get api_proc_doc_scripts $path]] {
        if { $public_p } {
            array set doc_elements [nsv_get api_proc_doc $proc]
            if { $doc_elements(protection) ne "public"} {
                continue
            }
        }
        multirow append proc_doc_list [api_proc_documentation $proc]
    }
}

if { $source_p } {
   set file_contents [template::util::read_file $::acs::rootdir/$path]
   set file_contents [apidoc::tclcode_to_html $file_contents]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
