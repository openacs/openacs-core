<?xml version="1.0"?>

<queryset>

  <fullquery name="user_to_info">
    <querytext>
	select first_names, last_name 
	from cc_users
	where user_id = :sendto
    </querytext>
  </fullquery>
</queryset>
