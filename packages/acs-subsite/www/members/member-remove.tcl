ad_page_contract {
    Remove member(s).
    
    @author Lars Pind (lars@collaboraid.biz)
    @creation-date 2003-06-02
    @cvs-id $Id$
} {
    user_id:naturalnum,multiple
}

set group_id [application_group::group_id_from_package_id]

permission::require_permission -object_id $group_id -privilege "admin"

foreach id $user_id {
    group::remove_member \
        -group_id $group_id \
        -user_id $user_id
}

ad_returnredirect .

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
