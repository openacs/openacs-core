ad_page_contract {
    Change member state
} {
    {rel_id:multiple ""}
    {member_state:notnull}
}

ad_require_permission $rel_id "admin"

membership_rel::change_state \
    -rel_id $rel_id \
    -state $member_state

ad_returnredirect [export_vars -base . { member_state }]
ad_script_abort
