ad_page_contract {

    Stores the system/publisher names and some email addresses,
    provided by the user on the <code>site-info</code> form, in the
    server configuration.

    @author Jon Salz (jsalz@arsdigita.com)
    @author Bryan Quinn (bquinn@arsdigita.com)
    @cvs-id $Id$
} {
    system_name:notnull
    publisher_name:notnull
    system_owner:notnull
    admin_owner:notnull
    host_administrator:notnull
}

set kernel_id [db_string acs_kernel_id_get {
    select package_id from apm_packages
    where package_key = 'acs-kernel'
}]

foreach { var param } {
    system_name SystemName
    publisher_name PublisherName
    system_owner SystemOwner
    admin_owner AdminOwner
    host_administrator HostAdministrator
} {
    ad_parameter -set [set $var] -package_id $kernel_id $param
}

# set the Main Site RestrictToSSL parameter

set main_site_id [db_string main_site_id_select { 
    select package_id from apm_packages
    where instance_name = 'Main Site' 
}]

ad_parameter -set "acs-admin/*" -package_id $main_site_id RestrictToSSL

ad_returnredirect "/?done_p=1"
