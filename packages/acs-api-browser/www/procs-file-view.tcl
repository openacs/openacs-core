ad_page_contract {
    Displays procs in a Tcl library file.

    @cvs-id $Id$
} {
    version_id:optional
    { public_p "" }
    path
} -properties {
    title:onevalue
    context:onevalue
    dimensional_slider:onevalue
    library_documentation:onevalue
    proc_list:multirow
    proc_doc_list:multirow
}

if { ![info exists version_id] && \
        [regexp {^packages/([^ /]+)/} $path "" package_key] } {
    db_0or1row version_id_from_package_key {
        select version_id 
          from apm_enabled_package_versions 
         where package_key = :package_key
    }
}

if {[info exists version_id]} {
    set public_p [api_set_public $version_id $public_p]
} else {
    set public_p [api_set_public "" $public_p]
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
    db_1row package_info_from_package_id {
        select pretty_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    lappend context [list "package-view?version_id=$version_id" "$pretty_name $version_name"]
}

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
            if { !$doc_elements(public_p) } {
                continue
            }
        }
        multirow append proc_list [api_proc_pretty_name -link $proc]
    }   
    foreach proc [lsort [nsv_get api_proc_doc_scripts $path]] {
        if { $public_p } {
            array set doc_elements [nsv_get api_proc_doc $proc]
            if { !$doc_elements(public_p) } {
                continue
            }
        }
        multirow append proc_doc_list [api_proc_documentation $proc]
    }
}
