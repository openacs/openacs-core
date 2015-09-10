ad_page_contract {
    Select a certain authority to be used to register
    users.

    @author Peter Marklund
} {
    authority_id:naturalnum,notnull
}

# Check that the authority has a register implementation
auth::authority::get -authority_id $authority_id -array authority
if { $authority(register_impl_id) eq "" } {
    ad_return_error "No register driver" "The authority $authority(pretty_name) does not have a register driver and cannot register users"
}

parameter::set_value -package_id [apm_package_id_from_key acs-authentication] -parameter RegisterAuthority -value $authority(short_name)

ad_returnredirect [export_vars -base "." { authority_id }]
# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
