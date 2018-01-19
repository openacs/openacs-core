ad_page_contract {
    Script that deletes an authority.

    @author Peter Marklund
    @creation-date 2003-09-08
} {
    authority_id:naturalnum,notnull
}

# Cannot delete local authority
if {$authority_id eq [auth::authority::local]} {
    ad_return_error "Cannot delete local authority" "The system requires the local authority to operate."
}

if { [auth::can_admin_system_without_authority_p -authority_id $authority_id] } { 

    auth::authority::delete -authority_id $authority_id

    ad_returnredirect "."
    ad_script_abort
} else {
    ad_return_error "Cannot delete authority" "Deleting this authority would mean that all site-wide administrator users are shut out from the system, meaning the system could no longer be administered."    
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
