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

set page_title "Internationalization"
set context [list [list "/acs-admin/apm/" "Package Manager"] [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] $page_title]

set num_cat_files [llength [glob -nocomplain "[acs_package_root_dir $package_key]/catalog/*.cat"]]


set localize_url [export_vars -base "[apm_package_url_from_key "acs-lang"]admin/message-list" { package_key {locale {[ad_conn locale]}}}]

set import_url [export_vars -base "/acs-lang/admin/import-messages" { package_key {return_url {[ad_return_url]}} }]
set export_url [export_vars -base "/acs-lang/admin/export-messages" { package_key {return_url {[ad_return_url]}} }]
