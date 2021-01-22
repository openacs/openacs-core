<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>9.0</version></rdbms>

<fullquery name="users_who_dont_have_any_permissions_paginator">
  <querytext>

    select u.user_id,
           u.first_names || ' ' || u.last_name
    from   cc_users u
    where  u.user_id not in (
       select grantee_id from acs_permission.permissions_all(:object_id)
    )
    order  by upper(first_names), upper(last_name)

  </querytext>
</fullquery>

</queryset>
