<?xml version="1.0"?>
<queryset>

<fullquery name="users_n_users">      
      <querytext>
          select count(user_id) as n_users, 
                 max(creation_date) as last_registration
          from   users u,
                 acs_objects o
          where  o.object_id = u.user_id
            and  user_id <> 0
      </querytext>
</fullquery>

<fullquery name="users_deleted_users">
      <querytext>

      select count(user_id) as n_deleted_users
      from   users u,
             group_member_map m,
             membership_rels mr,
             acs_magic_objects amo
      where  u.user_id = m.member_id
      and    amo.name = 'registered_users'
      and    m.group_id = amo.object_id
      and    m.container_id = m.group_id
      and    mr.rel_id = m.rel_id
      and    mr.member_state = 'deleted'

      </querytext>
</fullquery>


 
</queryset>
