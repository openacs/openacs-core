ad_page_contract {
    Create (unmounted) package instance. 
    @author Gustaf Neumann
    @creation-date 8 Sept 2014
    @cvs-id $Id$
} {
    {package_key:token,notnull}
    {return_url:localurl /acs/admin/apm}
}

apm_package_instance_new -package_key $package_key
ad_returnredirect $return_url
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
