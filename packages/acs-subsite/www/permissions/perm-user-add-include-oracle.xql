<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="users_who_dont_have_any_permissions">      
      <querytext>

    select u.user_id,
           person.name(u.user_id) as name,
           u.email
    from   cc_users u
    where  u.user_id not in (select grantee_id from acs_permissions_all where object_id = :object_id)
    order  by name


      </querytext>
</fullquery>


</queryset>
