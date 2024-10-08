
ad_library {
    Tcl procs for managing privacy

    @author ben@openforce.net
    @creation-date 2000-12-02
    @cvs-id $Id$
}

namespace eval acs_privacy {

    ad_proc -deprecated privacy_control_enabled_p {} {
        Returns whether privacy control is turned on or not.
        This is provided in order to have complete backwards
        compatibility with past behaviors, where private information
        was in no way regulated.

        DEPRECATED: this privacy feature was only used in the context
        of dotlrn, which also has an own set of apis for a similar
        purpose.

        @see dotlrn
    } {
        # If no parameter set, then we assume privacy control is DISABLED
        return [parameter::get -package_id [ad_acs_kernel_id] -parameter PrivacyControlEnabledP -default 0]
    }

    ad_proc -deprecated privacy_control_set {val} {
        set the privacy control

        DEPRECATED: this privacy feature was only used in the context
        of dotlrn, which also has an own set of apis for a similar
        purpose.

        @see dotlrn
    } {
        return [parameter::set_value -value $val -package_id [ad_acs_kernel_id] -parameter PrivacyControlEnabledP]
    }

    ad_proc -deprecated user_can_read_private_data_p {
        {-user_id ""}
        {-object_id:required}
    } {
        check if a user can access an object's private data

        DEPRECATED: this privacy feature was only used in the context
        of dotlrn, which also has an own set of apis for a similar
        purpose.

        @see dotlrn
    } {
        if {[privacy_control_enabled_p]} {
            return [permission::permission_p -party_id $user_id -object_id $object_id -privilege read_private_data]
        } else {
            # backwards compatibility
            return 1
        }
    }

    ad_proc -deprecated set_user_read_private_data {
        {-user_id:required}
        {-object_id:required}
        {-value:required}
    } {
        grant permission to access private data

        DEPRECATED: this privacy feature was only used in the context
        of dotlrn, which also has an own set of apis for a similar
        purpose.

        @see dotlrn
    } {
        if { [string is true -strict $value] } {
            permission::grant -party_id $user_id -object_id $object_id -privilege read_private_data
        } else {
            permission::revoke -party_id $user_id -object_id $object_id -privilege read_private_data
        }
    }
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
