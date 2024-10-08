ad_page_contract {
    @author Bryan Quinn (bquinn@arsdigita.com)
    @author Michael Bryzek (mbryzek@arsdigita.com)

    @creation-date August 15, 2000
    @cvs-id $Id$
} {
} -properties {
    context:onevalue
    acs_admin_url:onevalue
    instance_name:onevalue
    acs_automated_testing_url:onevalue
    acs_lang_admin_url:onevalue
}

set title "[_ acs-subsite.Administration]: [ad_conn instance_name]"
#set context [_ acs-subsite.Administration]
#set context [list [list "." "[_ acs-subsite.Administration]"] "Admin"]

set acs_admin_url [apm_package_url_from_key "acs-admin"]
set acs_admin_node_info [site_node::get -url $acs_admin_url]
set acs_admin_name [dict get $acs_admin_node_info instance_name]
set sw_admin_p [permission::permission_p \
                    -party_id [ad_conn user_id] \
                    -object_id [dict get $acs_admin_node_info object_id] \
                    -privilege admin]

#
# Get the main site location, which is the configured location.
# When SuppressHttpPort is set, get it without the port.
#
# Caveat: when running inside a container, the configured locations
# are not useful for return URLs, since the IP addresses and ports are
# typically mapped. For the time being, use the configured_location
# just when host-node-mapping is performed.
#
if {[db_string have_hostname_map {select count(*) from host_node_map}]} {
    #
    # Construct URL based on configured location.
    #
    set suppress_port [parameter::get -parameter SuppressHttpPort \
                           -package_id [apm_package_id_from_key acs-tcl] \
                           -default 0]
    set main_site_location [util::configured_location -suppress_port=$suppress_port]
    set full_acs_admin_url $main_site_location$acs_admin_url
} else {
    #
    # Stick with location-relative URL
    #
    set full_acs_admin_url $acs_admin_url
}

set convert_subsite_p [expr { [llength [apm::get_package_descendent_options [ad_conn package_key]]] > 0 }]

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
