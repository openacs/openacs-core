<?xml version="1.0"?>
<queryset>

  <fullquery name="subsite::sweep_expired_approvals.select_expired_user_ids">
    <querytext>
        select u.user_id
        from   cc_users u,
               acs_objects relo
        where  relo.object_id = u.rel_id
        and    u.last_visit < current_timestamp - interval :days day
        and    relo.last_modified < current_timestamp - interval :days day
        and    u.member_state = 'approved'
    </querytext>
  </fullquery>

</queryset>
