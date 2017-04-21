ad_page_contract {

    Toggles enabled_p of authority

    @author Simon Carstensen (simon@collaboraid.biz)

    @creation-date 2003-09-09
} {
    authority_id:naturalnum,notnull
    enabled_p:boolean
}

# Make sure we are not shutting out all site-wide-admins from the system
set allowed_p 1
if { $enabled_p == "f" && ![auth::can_admin_system_without_authority_p -authority_id $authority_id]} {
    set allowed_p 0
}

if { $allowed_p } { 
    db_dml set_enabled_p { update auth_authorities set enabled_p = :enabled_p where authority_id = :authority_id }
    
    ad_returnredirect . 
    ad_script_abort
} else {
    ad_return_error "Cannot disable authority" "Disabling this authority would mean that all site-wide administrator users are shut out from the system, meaning the system could no longer be administered."
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
