ad_page_contract {
    Displays information about a content page.
    
    @param version_id the id of the package version the file belongs to
    @param path the path and filename of the page to document, relative to [acs_root_dir]
    
    @author Jon Salz (jsalz@mit.edu)
    @author Lars Pind (lars@pinds.com)
    @creation-date 1 July 2000
    
    @cvs-id $Id$
} {
    version_id:integer,optional
    path
} -properties {
    title:onevalue
    context:onevalue
    script_documentation:onevalue
}

set context [list]
if { ![info exists version_id] && \
        [regexp {^packages/([^ /]+)/} $path "" package_key] } {
    db_0or1row version_id_from_package_key {
        select version_id 
          from apm_enabled_package_versions 
         where package_key = :package_key
    }
}

if { [info exists version_id] } {
    db_1row package_info_from_version_id {
        select pretty_name, package_key, version_name
          from apm_package_version_info
         where version_id = :version_id
    }
    lappend context [list "package-view?version_id=$version_id&kind=content" "$pretty_name $version_name"]
}

lappend context [file tail $path]

set title [file tail $path]
set script_documentation [api_script_documentation $path]

