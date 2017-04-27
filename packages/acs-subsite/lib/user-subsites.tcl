db_multirow -extend {url admin_p admin_url member_state_pretty} groups groups {
    select ap.package_id, r.object_id_one as group_id, g.group_name, mr.member_state
    from   acs_rels r,
           membership_rels mr,
           groups g,
           application_groups ap
    where  r.rel_type      = 'membership_rel'
    and    r.object_id_two = :user_id
    and    mr.rel_id   = r.rel_id
    and    g.group_id  = r.object_id_one
    and    ap.group_id = g.group_id
    order by lower(g.group_name)
} {
    set admin_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "admin"]
    set member_state_pretty [group::get_member_state_pretty -member_state $member_state]
    if {$package_id ne "" && $group_id != [acs_magic_object registered_users]} {
        set url [apm_package_url_from_id $package_id]
    } else {
        set url ""
    }
    set admin_url [export_vars -base /members/ {{group_id $group_id}}]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
