ad_page_contract {
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 2003-10-28
    @cvs-id $Id$
} {
    enabled_p
    {return_url "."}
}

ds_require_permission [ad_conn package_id] "admin"

ds_set_database_enabled $enabled_p

ad_returnredirect $return_url
