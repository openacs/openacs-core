<?xml version="1.0"?>

<queryset>

<fullquery name="users_who_dont_have_any_permissions">
      <querytext>

    select u.user_id,
           u.first_names || ' ' || u.last_name as name,
           u.email
    from   cc_users u
    where  [template::list::page_where_clause -name users]
    order  by upper(first_names), upper(last_name)

      </querytext>
</fullquery>

</queryset>
