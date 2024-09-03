<?xml version="1.0"?>

<queryset>

    <fullquery name="callback::merge::MergeShowUserInfo::impl::notifications.user_notification">
        <querytext>	
          select notification_id, notif_subject
          from notifications
          where notif_user  = :user_id
        </querytext>
    </fullquery>	

    <fullquery name="callback::merge::MergePackageUser::impl::notifications.upd_notifications">
        <querytext>	
          update notifications
	  set notif_user  = :to_user_id
   	  where notif_user = :from_user_id
        </querytext>
    </fullquery>	

    <fullquery name="callback::merge::MergePackageUser::impl::notifications.upd_map">
        <querytext>	
          update notification_user_map
	  set user_id  = :to_user_id
	  where user_id = :from_user_id
        </querytext>
    </fullquery>	

    <fullquery
      name="callback::acs_mail_lite::incoming_email::impl::notifications.holdinsert">
      <querytext>
        insert into notification_email_hold
        (reply_id,to_addr,headers,body)
        values
        (:reply_id,:to_addr,:headers,:bodies)
      </querytext>
    </fullquery>

</queryset>
