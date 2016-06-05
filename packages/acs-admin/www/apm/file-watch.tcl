ad_page_contract {
    Watches a number of files for reload. Note that the
    paths given to this page should be relative to package root,
    not server root.

    @author Peter Marklund
    @creation-date 17 April 2000
    @cvs-id $Id$
} {
    version_id:naturalnum,notnull
    paths:multiple
    {return_url:localurl ""}
} 

set package_key [apm_package_key_from_version_id $version_id]

foreach path $paths {
    apm_file_watch "packages/$package_key/$path"
}

ad_returnredirect $return_url

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
