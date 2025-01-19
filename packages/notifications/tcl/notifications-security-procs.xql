<?xml version="1.0"?>

<queryset>

    <fullquery name="notification::security::can_notify_user.user_approved_p">
        <querytext>
    select case when member_state = 'approved' then 1 else 0 end as send_p 
      from cc_users 
     where user_id = :user_id
        </querytext>
    </fullquery>

</queryset>
    