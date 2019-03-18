ad_include_contract {
    UI includelet to show and create subsites.
} {
}

set pretty_name [_ acs-subsite.subsite]
set pretty_plural [_ acs-subsite.subsites]

set untrusted_user_id [ad_conn untrusted_user_id]
set subsite_id [ad_conn subsite_id]

# generate admin action links?
set admin_p [permission::permission_p \
                 -object_id $subsite_id \
                 -privilege admin \
                 -party_id $untrusted_user_id]

set subsite [site_node::get_from_object_id -object_id $subsite_id]
set subsite_node_id [dict get $subsite node_id]
set subsite_url     [dict get $subsite url]

set actions [list]
if { $admin_p } {
    lappend actions [_ acs-subsite.Create_new_subsite] "${subsite_url}admin/subsite-add" {}
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

set return_url [ad_return_url]
db_multirow -extend { url join_url request_url } subsites select_subsites [subst {
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
      and    p.package_key  in ('[join [subsite::package_keys] {','}]')
      and    ag.package_id = p.package_id
      and    g.group_id = ag.group_id
      and    (acs_permission.permission_p(p.package_id, :untrusted_user_id, 'read')
              or g.join_policy != 'closed')
    order  by lower(instance_name)
}] {
    set join_url [export_vars -base "${subsite_url}register/user-join" {group_id return_url}]
    set url $subsite_url$name
}

# Local variables:
#    mode: tcl
#    tcl-indent-level: 4
#    indent-tabs-mode: nil
# End:
