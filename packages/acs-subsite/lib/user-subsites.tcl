db_multirow -extend {url admin_p} groups groups {
  select distinct ap.package_id, groups.group_id, lower(groups.group_name), groups.group_name
     from groups, group_member_map gm, application_groups ap
     where groups.group_id = gm.group_id and gm.member_id=:user_id
       and ap.group_id = groups.group_id
  order by lower(groups.group_name)
} {
    set admin_p [permission::permission_p -party_id $user_id -object_id $group_id -privilege "admin"]
    set url [apm_package_url_from_id $package_id]
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
