ad_page_contract {
    Export messages from the database to xml catalog files.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:integer
    {return_url "version-i18n-index?version_id=$version_id"}
}

set page_title "Message Export Results"

set catalog_dir [lang::catalog::package_catalog_dir [apm_package_key_from_version_id $version_id]]

lang::catalog::export_package_to_files [apm_package_key_from_version_id $version_id]
