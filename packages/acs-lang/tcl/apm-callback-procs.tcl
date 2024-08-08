# /packages/acs-lang/tcl/apm-callback-procs.tcl

ad_library {

    APM callbacks library

    @creation-date August 2009
    @author  Emmanuelle Raffenne (eraffenne@gmail.com)
    @cvs-id $Id$

}

namespace eval lang {}
namespace eval lang::apm {}

ad_proc -private lang::apm::after_install {
} {
    After install callback
} {

}

ad_proc -private lang::apm::after_mount {
    -package_id:required
    -node_id:required
} {
    
    Modify default permissions after mount to restrict read access to
    the package from public read to read access for registered users.
    
} {
    #ns_log notice "-- After mount callback package_id $package_id node_id $node_id"
    
    #
    # Turn off inheritance from public site
    #
    permission::set_not_inherit -object_id $package_id
    #
    # Allow registered users to read
    #
    permission::grant -party_id [acs_magic_object registered_users] \
        -object_id $package_id \
        -privilege read
}

ad_proc -private lang::apm::after_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    After upgrade callback for acs-lang
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
        }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
