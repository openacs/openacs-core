ad_page_contract {
    Import messages from catalog files to the database.  Will overwrite texts in the database.

    @author Peter Marklund (peter@collaboraid.biz)
    @creation-date 23 October 2002
    @cvs-id $Id$  
} {
    version_id:naturalnum,notnull    
    {return_url:localurl {[export_vars -base "version-i18n-index" { version_id }]}}
}

db_1row package_version_info { 
    select package_key, pretty_name, version_name 
    from   apm_package_version_info 
    where  version_id = :version_id 
}

set page_title "Import Messages"
set context [list \
                 [list "/acs-admin/apm/" "Package Manager"] \
                 [list [export_vars -base version-view { version_id }] "$pretty_name $version_name"] \
                 [list [export_vars -base "version-i18n-index" { version_id }] "Internationalization"] $page_title]

set catalog_dir [lang::catalog::package_catalog_dir $package_key]

lang::catalog::import -package_key $package_key

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
