ad_page_contract {
    Export messages from the database to xml catalog files.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:integer
    {return_url ""}
}

set page_title "Message Export Results"

# Default return_url
if { [empty_string_p $return_url] } {
    set return_url "version-i18n-index?[export_vars { version_id }]"
}

set catalog_dir [lang::catalog::package_catalog_dir [apm_package_key_from_version_id $version_id]]

lang::catalog::export_package_to_files [apm_package_key_from_version_id $version_id]
