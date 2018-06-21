<?xml version="1.0"?>
<queryset>

    <fullquery name="acs_mail_lite::check_bounces.get_recent_bouncing_users">
      <querytext>

       select u.user_id, u.email, u.first_names || ' ' || u.last_name as name
       from cc_users u, acs_mail_lite_bounce_notif n
       where u.user_id = n.party_id
       and u.email_bouncing_p = 't'
       and n.notification_time < current_timestamp - interval :notification_interval day
       and n.notification_count < :max_notification_count

      </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::check_bounces.send_notification_to_bouncing_email">
      <querytext>

       insert into acs_mail_lite_bounce_notif (party_id, notification_count, notification_time)
       select party_id, 0 as notification_count,
              current_date - (1 + cast(:notification_interval as integer)) as notification_time
        from acs_mail_lite_bounce
        where bounce_count >= :max_bounce_count

      </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::check_bounces.log_notification_sending">
      <querytext>

       update acs_mail_lite_bounce_notif
       set notification_time = current_date,
           notification_count = notification_count + 1
       where party_id = :user_id

      </querytext>
    </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.delete_log_if_no_recent_bounce">
     <querytext>

       delete from acs_mail_lite_bounce
       where party_id in (select party_id
                         from acs_mail_lite_mail_log
                         where last_mail_date < current_timestamp - interval :max_days_to_bounce day)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.disable_bouncing_email">
     <querytext>

       update users
       set email_bouncing_p = 't'
       where user_id in (select party_id
                         from acs_mail_lite_bounce
                         where bounce_count >= :max_bounce_count)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.delete_bouncing_users_from_log">
     <querytext>

       delete from acs_mail_lite_bounce
       where bounce_count >= :max_bounce_count

     </querytext>
   </fullquery>

</queryset>
