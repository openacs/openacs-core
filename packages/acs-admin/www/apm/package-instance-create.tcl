ad_page_contract {
    Create (unmounted) package instance. 
    @author Gustaf Neumann
    @creation-date 8 Sept 2014
    @cvs-id $Id$
} {
    {package_key:notnull}
    {return_url /acs/admin/apm}
}
apm_package_instance_new -package_key $package_key
ad_returnredirect $return_url
