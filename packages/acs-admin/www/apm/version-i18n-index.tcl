ad_page_contract {
    Manage Internationalization for a certain package version.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
} -properties {
    page_title
    context_bar
    num_cat_files
}

db_1row package_version_info { 
    select package_key, pretty_name, version_name 
    from   apm_package_version_info 
    where  version_id = :version_id 
}

set page_title "Manage Internationalization of $pretty_name $version_name"
set context_bar [ad_context_bar $page_title]

set num_cat_files [llength [glob -nocomplain "[acs_package_root_dir $package_key]/catalog/*.cat"]]

ad_return_template
