ad_page_contract {
    
    @author Lars Pind (lars@pinds.com)
    @creation-date 31 August 2000
    @cvs-id $Id$
} {
    enabled_p
    {return_url "."}
}

ds_require_permission [ad_conn package_id] "admin"

ds_set_user_switching_enabled $enabled_p

ad_returnredirect $return_url
