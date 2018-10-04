ad_library {
    Server startup initialization code for the "acs_testing" authority.

    @author Gustaf Neumann
    @creation-date 2018-10-04
}

#
# Make sure, the needed service contracts are defined:
#
acs::test::auth::install

#
# Refresh the alias wrappers, in case acs-service-contract-init.tcl
# was run before us.
#
acs_sc_update_alias_wrappers

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
