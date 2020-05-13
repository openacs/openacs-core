ad_library {

    Handling of site_wide packages, mostly for testing and
    administration of the full site.

    @author Gustaf Neumann
    @creation-date 13 Feb 2020
}

namespace eval ::acs_admin {

    ad_proc require_site_wide_subsite {} {

        Require the site_wide subsite for administration and testing purposes.
        If the subsite does not exist, create it.

        @return package_id of the site_wide subsite
    } {
        set key ::acs_admin::site_wide_subsite
        if {![info exists $key]} {
            set subsite_name site-wide
            set subsite_parent /acs-admin
            set subsite_path $subsite_parent/$subsite_name

            if {[site_node::exists_p -url $subsite_path]} {
                set node_info [site_node::get -url $subsite_path]
                set subsite_id [dict get $node_info object_id]
            } else {
                set node_info [site_node::get -url $subsite_parent]
                set subsite_id [site_node::instantiate_and_mount \
                                    -parent_node_id [dict get $node_info node_id] \
                                    -node_name $subsite_name \
                                    -package_name $subsite_name \
                                    -package_key acs-subsite]
            }
            set $key $subsite_id
        }
        return [set $key]
    }

    ad_proc require_site_wide_package {
        -package_key:required
        -node_name
        -package_name
        {-parameters {}}
        {-configuration_command {}}
    } {

        Require a package under the site-wide subsite. If such a
        package does not exist, it is created with the provided
        parameters. When a configuration command is passed-in
        it will be called with "-package_id $package_id" of the
        new instance appended.

        @param package_key of the required package
        @param node_name name of the mount point (defaults to the package_key)
        @param package_name name of the package_instance (defaults to the package_key)
        @param parameter package parameter for initialization of the package
        @param configuration_command when a configuratio

        @return package_id of the required package
    } {
        if {![info exists node_name]} {
            set node_name $package_key
        }
        if {![info exists package_name]} {
            set package_name $package_key
        }
        set site_wide_subsite [::acs_admin::require_site_wide_subsite]
        set node_info [site_node::get_from_object_id -object_id $site_wide_subsite]

        set path [dict get $node_info url]$node_name
        #
        # Flush site node cache to avoid potential bootstrap
        # problems.
        #
        if {[info commands ::xo::site_node] ne ""} {
            xo::site_node flush_pattern id-$path*
        }

        if {[site_node::exists_p -url $path]} {
            #
            # During bootstrap, the package_id might be empty, because
            # the after_initiate callback might call the
            # site-wide-init, which in turn might initiate another
            # instance. Therefore, we might be called between site-node
            # creation and mounting .. which will result in an empty
            # package_id.
            #
            set node_info [site_node::get -url $path]
            set package_id [dict get $node_info object_id]
        } else {
            set package_id [site_node::instantiate_and_mount \
                                -parent_node_id [dict get $node_info node_id] \
                                -node_name $node_name \
                                -package_name $package_name \
                                -package_key $package_key]
            foreach {parameter value} $parameters {
                parameter::set_value -package_id $package_id -parameter $parameter -value $value
            }
            if {[llength $configuration_command] > 0} {
                {*}$configuration_command -package_id $package_id
            }
        }
        return $package_id
    }
}

#
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
