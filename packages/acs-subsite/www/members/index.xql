<?xml version="1.0"?>

<queryset>

<fullquery name="members_pagination">
      <querytext>
      
    select r.rel_id, 
           u.first_names || ' ' || u.last_name as name
    from   acs_rels r,
           membership_rels mr,
           cc_users u
    where  r.object_id_one = :group_id
    and    mr.rel_id = r.rel_id
    and    u.user_id = r.object_id_two
    [template::list::filter_where_clauses -and -name "members"]
    [template::list::orderby_clause -orderby -name "members"]
	
      </querytext>
</fullquery>


<fullquery name="members_select">      
      <querytext>

    select r.rel_id, 
           u.user_id,
           u.first_names || ' ' || u.last_name as name,
           u.email,
           r.rel_type,
           rt.role_two as rel_role,
           role.pretty_name as rel_role_pretty,
           mr.member_state
    from   acs_rels r,
           membership_rels mr,
           cc_users u,
           acs_rel_types rt,
           acs_rel_roles role
    where  r.object_id_one = :group_id
    and    mr.rel_id = r.rel_id
    and    u.user_id = r.object_id_two
    and    rt.rel_type = r.rel_type
    and    role.role = rt.role_two
    [template::list::filter_where_clauses -and -name "members"]
    [template::list::page_where_clause -and -name "members" -key "r.rel_id"]
    [template::list::orderby_clause -orderby -name "members"]


      </querytext>
</fullquery>

 
</queryset>
