ad_library {
    APM callback procedures for acs-templating.
    
    @creation-date 2003-09-22
    @author Lars Pind (lars@collaboraid.biz)
    @cvs-id $Id$
}

namespace eval template {}
namespace eval template::apm {}

ad_proc -private template::apm::before_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    before upgrade apm callback for acs-templating.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            4.6.4 5.0d1 {
                db_transaction {

                    # Change 'standard-lars' to 'standard'

                    set package_id [apm_package_id_from_key "acs-templating"]
                    set DefaultFormStyle [parameter::get \
                                              -package_id $package_id \
                                              -parameter DefaultFormStyle]

                    if {$DefaultFormStyle eq "standard-lars"} {
                        parameter::set_value \
                            -package_id $package_id \
                            -parameter DefaultFormStyle \
                            -value "standard"
                    }

                    db_foreach subsite {
                        select package_id
                        from   apm_packages
                        where  package_key = 'acs-subsite'
                    } {
                        set DefaultFormStyle [parameter::get \
                                                  -package_id $package_id \
                                                  -parameter DefaultFormStyle]

                        if {$DefaultFormStyle eq "standard-lars"} {
                            parameter::set_value \
                                -package_id $package_id \
                                -parameter DefaultFormStyle \
                                -value "standard"
                        }
                    }
                }
            }
            5.5.1d1 5.5.1d2 {
                # Removing invalid plugins for the new version of Xinha
                set package_id_templating [apm_package_id_from_key "acs-templating"]
                set plugins [parameter::get \
                                 -package_id $package_id_templating \
                                 -parameter "XinhaDefaultPlugins" \
                                 -default ""]
                if { $plugins ne "" } {
		    set del_pos [lsearch $plugins FullScreen]
		    set plugins [lreplace $plugins $del_pos $del_pos]
		    parameter::set_value \
			-package_id $package_id_templating \
			-parameter "XinhaDefaultPlugins" \
			-value $plugins 
                }
            }
        }
}

ad_proc -private template::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    after upgrade apm callback for acs-templating.
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
            5.3.0d1 5.3.0d2 {
                db_transaction {
                    # mount acs-templating so we can address
                    # executable Tcl scripts under www with a url
                    set package_id [apm_package_id_from_key acs-templating]
                    array set main_subsite \
                        [site_node::get_from_url \
                             -url "/" \
                             -exact]
                    
                    set node_id [site_node::new \
                                     -parent_id $main_subsite(node_id) \
                                     -name acs-templating]
                    site_node::mount -node_id $node_id -object_id $package_id
                    # acs-templating needs to inherit permissions from
                    # the main subsite so users can actually read the
                    # files under it
#                    acs_object::set_context_id \
                        -object_id $package_id \
                       -context_id $main_subsite(object_id)
                }
            }
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
