<?xml version="1.0"?>

<queryset>

<fullquery name="members_pagination">
      <querytext>
      
    select r.rel_id, 
           p.first_names || ' ' || p.last_name as name
    from   acs_rels r,
           membership_rels mr,
           persons p,
           parties pa
    where  r.object_id_one = :group_id
    and    r.rel_type = 'membership_rel'
    and    mr.rel_id = r.rel_id
    and    p.person_id = r.object_id_two
    and    p.person_id = pa.party_id
    [template::list::filter_where_clauses -and -name "members"]
    [template::list::orderby_clause -orderby -name "members"]
	
      </querytext>
</fullquery>

<fullquery name="pretty_roles">
      <querytext>

        select admin_role.pretty_name as admin_role_pretty,
          member_role.pretty_name as member_role_pretty
        from acs_rel_roles admin_role, acs_rel_roles member_role
        where admin_role.role = 'admin'
          and member_role.role = 'member'

      </querytext>
</fullquery>

<fullquery name="members_select">      
      <querytext>

    select r.rel_id, 
           p.person_id as user_id,
           p.first_names || ' ' || p.last_name as name,
           pa.email,
           mr.member_state,
           (select count(*)
            from rel_segment_party_map
            where rel_type = 'admin_rel'
              and group_id = :group_id
              and party_id = pa.party_id) as member_admin_p,
           (select distinct r.pretty_name 
            from acs_rel_roles r, rel_segment_party_map m, acs_rel_types t
            where m.group_id = :group_id
            and t.rel_type = m.rel_type
            and m.rel_type <> 'admin_rel'
            and m.rel_type <> 'membership_rel'
            and r.role = t.role_two
            and m.party_id = pa.party_id) as other_role_pretty
    from   acs_rels r,
           membership_rels mr,
           persons p,
           parties pa
    where  r.object_id_one = :group_id
    and    mr.rel_id = r.rel_id
    and    r.rel_id = mr.rel_id
    and    p.person_id = r.object_id_two
    and    p.person_id = pa.party_id
    [template::list::filter_where_clauses -and -name "members"]
    [template::list::page_where_clause -and -name "members" -key "r.rel_id"]
    [template::list::orderby_clause -orderby -name "members"]

      </querytext>
</fullquery>

<fullquery name="select_member_states">
      <querytext>

        select mr.member_state as state, 
               count(mr.rel_id) as num_members
        from   membership_rels mr, acs_rels r
        where  r.rel_id = mr.rel_id
          and  r.object_id_one = :group_id
          and  r.rel_type = 'membership_rel'
        group  by mr.member_state

      </querytext>
</fullquery>
 
</queryset>
