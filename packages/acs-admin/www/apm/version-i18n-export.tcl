ad_page_contract {
    Export messages from the database to xml catalog files.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
}

lang::catalog::export_package_to_files [apm_package_key_from_version_id $version_id]

ad_returnredirect "version-i18n-index?version_id=$version_id"
