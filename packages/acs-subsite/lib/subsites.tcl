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
            link_url_col url
        }
        num_members {
            label "\# [_ acs-subsite.Members]"
            html { align right }
        }
        member_state {
            label "Member state"
            display_template {
                <switch @subsites.member_state@>
                  <case value="approved">Approved</case>
                  <case value="needs approval">Awaiting approval</case>
                  <case value="rejected">Rejected</case>
                  <default>
                    @subsites.member_state@
                    <if @subsites.join_policy@ eq "open"><a href="@subsites.join_url@" class="button">Join</a></if>
                    <else><a href="@subsites.join_url@" class="button">Request membership</a></else>
                  </default>
                </switch>
            }
        }
    }


set subsite_node_id [subsite::get_element -element node_id]
set subsite_url [subsite::get_element -element url]

set untrusted_user_id [ad_conn untrusted_user_id]

db_multirow -extend { url join_url request_url } subsites select_subsites {
    select p.package_id,
           p.instance_name,
           n.node_id, 
           n.name,
           (select count(*)
            from   group_approved_member_map m
            where  m.rel_type = 'membership_rel'
            and    m.group_id = ag.group_id) as num_members,
           (select min(r2.member_state)
            from   group_member_map m2,
                   membership_rels r2
            where  m2.group_id = ag.group_id
            and    m2.member_id = :untrusted_user_id
            and    r2.rel_id = m2.rel_id) as member_state,
           g.group_id,
           g.join_policy
    from   site_nodes n,
           apm_packages p,
           application_groups ag,
           groups g
    where  n.parent_id = :subsite_node_id
    and    p.package_id = n.object_id
    and    p.package_key = 'acs-subsite'
    and    ag.package_id = p.package_id
    and    g.group_id = ag.group_id
    and    (exists (select 1 
                   from   all_object_party_privilege_map perm 
                   where  perm.object_id = p.package_id
                   and    perm.privilege = 'read'
                   and    perm.party_id = :untrusted_user_id) or g.join_policy != 'closed')
    order  by upper(instance_name)
} {
    set join_url [export_vars -base "${subsite_url}register/user-join" { group_id { return_url [ad_return_url] } }]
    set url $subsite_url$name
}
