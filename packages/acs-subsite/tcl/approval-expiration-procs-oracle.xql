<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="subsite::sweep_expired_approvals.select_expired_user_ids">      
      <querytext>
      
        select u.user_id 
        from   cc_users u, 
               acs_objects relo
        where  relo.object_id = u.rel_id
        and    last_visit < sysdate - :days
        and    relo.last_modified < sysdate - :days
        and    u.member_state = 'approved'
        
      </querytext>
</fullquery>
 
</queryset>
