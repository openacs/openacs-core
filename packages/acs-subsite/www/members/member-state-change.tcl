ad_page_contract {
    Change member state
} {
    {rel_id:naturalnum,multiple ""}
    {member_state:notnull}
}

permission::require_permission -object_id $rel_id -privilege "admin"

membership_rel::change_state \
    -rel_id $rel_id \
    -state $member_state

ad_returnredirect [export_vars -base . { member_state }]
ad_script_abort

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
