<?xml version="1.0"?>
<queryset>

  <fullquery name="get_users">      
    <querytext>
      select user_id, first_name, last_name 
      from ad_template_sample_users 
      where lower(first_name) like '%' || :user_search || '%' 
         or lower(last_name) like '%' || :user_search || '%'
    </querytext>
  </fullquery>

  <fullquery name="get_info">      
    <querytext>
      select user_id, first_name, last_name, address1, address2, city, state
      from ad_template_sample_users
      where user_id = :user_id
    </querytext>
  </fullquery>

</queryset>