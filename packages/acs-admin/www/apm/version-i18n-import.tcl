ad_page_contract {
    Import messages from catalog files to the database.
    Will overwrite texts in the database.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
    {format "xml"}
}

set package_key [apm_package_key_from_version_id $version_id]
if { [string equal $format "xml"] } {
    lang::catalog::import_from_files $package_key
} else {
    lang::catalog::import_from_tcl_files $package_key
}

ad_returnredirect "version-i18n-index?version_id=$version_id"
