<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="user_search">      
      <querytext>
            select distinct u.first_names || ' ' || u.last_name || ' (' || u.email || ')' as name, u.user_id
            from   cc_users u
            where  upper(coalesce(u.first_names || ' ', '')  ||
                   coalesce(u.last_name || ' ', '') ||
                   u.email || ' ' ||
                   coalesce(u.screen_name, '')) like upper('%'||:value||'%')
            and    not exists (select 1 from acs_rels where object_id_one = $group_id and object_id_two = u.user_id and rel_type = 'membership_rel')
            order  by name

      </querytext>
</fullquery>

 
 
</queryset>


