<?xml version="1.0"?>
<queryset>

<fullquery name="users_n_users">      
      <querytext>
      select 
    count(*) as n_users, 
    sum(case when member_state = 'deleted' then 1 else 0 end) as n_deleted_users, 
    max(creation_date) as last_registration
    from cc_users
    where email not in ('anonymous', 'system')
      </querytext>
</fullquery>

 
<fullquery name="groups_select">      
      <querytext>
      
select groups.group_id, 
       groups.group_name, 
       m.num as n_members, 
       c.num as n_components 
from groups, 
     (select group_id, count(*) as num 
      from group_member_map group by group_id) m, 
     (select group_id, count(*) as num 
      from group_component_map group by group_id) c 
where groups.group_id=m.group_id 
  and groups.group_id = c.group_id
order by group_name

      </querytext>
</fullquery>

 
</queryset>
