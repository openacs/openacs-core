<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="subsite::sweep_expired_approvals.select_expired_user_ids">      
      <querytext>
      
        select u.user_id 
        from   cc_users u, 
               acs_objects relo
        where  relo.object_id = u.rel_id
        and    age(u.last_visit) > interval '$days days'
        and    age(relo.last_modified) > interval '$days days'
        and    u.member_state = 'approved'
        
      </querytext>
</fullquery>
 

 
</queryset>
