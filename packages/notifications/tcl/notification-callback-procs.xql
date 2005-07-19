<?xml version="1.0"?>

<queryset>

    <fullquery name="callback::MergeShowUserInfo::impl::notifications.user_notification">
        <querytext>	
          select notification_id, notif_subject
          from notifications
          where notif_user  = :user_id
        </querytext>
    </fullquery>	

    <fullquery name="callback::MergePackageUser::impl::notifications.upd_notifications">
        <querytext>	
          update notifications
	  set notif_user  = :to_user_id
   	  where notif_user = :from_user_id
        </querytext>
    </fullquery>	

    <fullquery name="callback::MergePackageUser::impl::notifications.upd_map">
        <querytext>	
          update notification_user_map
	  set user_id  = :to_user_id
	  where user_id = :from_user_id
        </querytext>
    </fullquery>	

</queryset>
