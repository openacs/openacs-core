set pretty_name [_ acs-subsite.subsite]
set pretty_plural [_ acs-subsite.subsites]

set admin_p [permission::permission_p -object_id [ad_conn package_id] -privilege admin -party_id [ad_conn untrusted_user_id]]

set actions [list]
if { $admin_p } {
    lappend actions [_ acs-subsite.Create_new_subsite] "[subsite::get_element -element url]admin/subsite-add" {}
}


list::create \
    -name subsites \
    -multirow subsites \
    -actions $actions \
    -no_data "[_ acs-subsite.No_pretty_plural [list pretty_plural $pretty_plural]]" \
    -elements {
        instance_name {
            label "[_ acs-subsite.Name]"
            link_url_eval "$name/"
        }
        num_members {
            label "\# [_ acs-subsite.Members]"
            html { align right }
        }
    }


set subsite_node_id [subsite::get_element -element node_id]

set user_id [ad_conn user_id]

db_multirow subsites select_subsites {
    select p.package_id,
           p.instance_name,
           n.node_id, 
           n.name,
           (select count(*)
            from   application_groups ag,
                   group_approved_member_map m
            where  ag.package_id = p.package_id
            and    m.rel_type = 'membership_rel'
            and    m.group_id = ag.group_id) as num_members
    from   site_nodes n,
           apm_packages p
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    p.package_key = 'acs-subsite'
    and    exists (select 1 
                   from   all_object_party_privilege_map perm 
                   where  perm.object_id = p.package_id
                   and    perm.privilege = 'read'
                   and    perm.party_id = :user_id)
    order  by upper(instance_name)
}



