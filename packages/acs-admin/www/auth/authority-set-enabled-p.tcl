ad_page_contract {

    Toggles enabled_p of authority

    @author Simon Carstensen (simon@collaboraid.biz)

    @creation-date 2003-09-09
} {
    {authority_id:naturalnum,notnull}
    {enabled_p:boolean}
} -validate {
    authority_exists -requires {authority_id:naturalnum} {
        if {![db_0or1row dbqd...check_authority_id {select authority_id from auth_authorities where authority_id = :authority_id}]} {
            ad_complain "Invalid authority"
            return
        }
    }
}

# Make sure we are not shutting out all site-wide-admins from the system
if { $enabled_p == "f" && ![auth::can_admin_system_without_authority_p -authority_id $authority_id] } { 
    ad_return_error "Cannot disable authority" \
        "Disabling this authority would mean that all site-wide administrator users are shut out from the system, meaning the system could no longer be administered."
} else {
    set element_arr(enabled_p) $enabled_p
    auth::authority::edit -authority_id $authority_id -array element_arr
    ad_returnredirect .     
}

ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
