ad_page_contract {

    @author Peter Marklund
    @creation-date 28 January 2003
    @cvs-id $Id$  
} {
    version_id:integer,notnull    
    type:notnull
}

set package_key [apm_package_key_from_version_id $version_id]
apm_remove_callback_proc -type $type -package_key $package_key

ad_returnredirect "version-callbacks?version_id=$version_id"