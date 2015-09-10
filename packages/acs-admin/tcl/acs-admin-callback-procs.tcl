# packages/acs-admin/tcl/acs-admin-callback-procs.tcl

ad_library {
    
    Callback procs for acs-admin
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2007-06-15
    @arch-tag: 4267c818-0019-4222-8a50-64edbe7563d1
}

namespace eval acs_admin {}

ad_proc -public -callback acs_admin::member_state_change {
    -user_id
    -member_state
} {
    Callback which is executed after a successful change of member state. Allows other software to do additional tasks
    upon the user.
    
    @param user_id User ID of the user upon whom the state change was done
    @param member_state New state of the user
} -


# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
