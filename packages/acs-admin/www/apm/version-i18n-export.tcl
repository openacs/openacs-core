ad_page_contract {
    Export messages from the database to xml catalog files.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:integer
    {return_url {[export_vars -base "version-i18n-index" { version_id }]}}
}

set package_key [apm_package_key_from_version_id $version_id]

set page_title "$package_key Messagess Exported"
set context [list $page_title]

set catalog_dir [lang::catalog::package_catalog_dir $package_key]

lang::catalog::export_package_to_files [apm_package_key_from_version_id $version_id]
