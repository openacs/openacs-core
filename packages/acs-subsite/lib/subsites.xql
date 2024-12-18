<?xml version="1.0"?>
<queryset>

  <fullquery name="select_subsites">
    <querytext>

    select p.package_id,
           p.instance_name,
           n.node_id, 
           n.name,
           :subsite_url || n.name as url,
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
      and    (g.join_policy != 'closed' or
              acs_permission.permission_p(p.package_id, :untrusted_user_id, 'read') = 't')
    order  by lower(instance_name)

      </querytext>
  </fullquery>
</queryset>

