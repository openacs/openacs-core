ad_page_contract {
    Displays information about a content page.
    
    @param version_id the id of the package version the file belongs to
    @param path the path and filename of the page to document, relative to $::acs::rootdir
    
    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @creation-date 1 July 2000
    
    @cvs-id $Id$
} {
    version_id:integer,optional
    source_p:integer,optional,trim
    path
} -properties {
    title:onevalue
    context:onevalue
    script_documentation:onevalue
}

set context [list]
set url_vars [export_vars -url {path version_id}]
set return_url [ns_urlencode [ad_conn url]?][ns_urlencode $url_vars]
set default_source_p [ad_get_client_property -default 0 acs-api-browser api_doc_source_p]

if { ![info exists source_p] } {
    set source_p $default_source_p
}

if { ![info exists version_id] && \
        [regexp {^packages/([^ /]+)/} $path "" package_key] } {
    db_0or1row version_id_from_package_key {
        select version_id 
          from apm_enabled_package_versions 
         where package_key = :package_key
    }
}

if { [info exists version_id] } {
    db_0or1row package_info_from_version_id {
        select pretty_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    if {[info exists pretty_name]} {
        lappend context [list "package-view?version_id=$version_id&kind=content" "$pretty_name $version_name"]
    }
}



lappend context [file tail $path]

set filename "$::acs::rootdir/$path"

if {[regsub -all {[.][.]/} $filename "" shortened_filename]} {
    ns_log notice "INTRUDER ALERT:\n\nsomesone tried to snarf '$filename'!\n  file exists: [file exists $filename]\n  user_id: [ad_conn user_id]\n  peer: [ad_conn peeraddr]\n"
    set filename shortened_filename
}

if {![file exists $filename] || [file isdirectory $filename]} {
    set file_contents "file '$filename' not found"
    multirow create xql_links link
} else {
    if { $source_p } {
        if {[catch {
        
            set fd [open $filename r]
            set file_contents [read $fd]
            close $fd
        
        } err ]} {
            set file_contents "error opening '$filename'\n$err"
        } else {
            set file_contents [ad_quotehtml $file_contents]
        }
    }

    template::util::list_to_multirow xql_links [api_xql_links_list $path]
}


set title [file tail $path]
set script_documentation [api_script_documentation $path]

