<?xml version="1.0"?>

<queryset>

    <fullquery name="auth::local::authentication::MergeUser.getrelid">
      <querytext>
	select rel_id from cc_users where user_id = :from_user_id      
      </querytext>
    </fullquery>

<fullquery name="auth::local::search::Search.user_search">      
      <querytext>
            select distinct user_id, username, email
            from   cc_users u
            where  upper(coalesce(u.first_names || ' ', '')  ||
                   coalesce(u.last_name || ' ', '') ||
                   u.email || ' ' ||
                   u.username || ' ' ||
                   coalesce(u.screen_name, '')) like upper('%'||:search_text||'%')
            order  by username, email

      </querytext>
</fullquery>

<fullquery name="auth::local::user_info::GetUserInfo.get_user_info">      
      <querytext>
            select user_id, first_names, last_name, username, email
              from cc_users 
             where user_id = :user_id
      </querytext>
</fullquery>

</queryset>


