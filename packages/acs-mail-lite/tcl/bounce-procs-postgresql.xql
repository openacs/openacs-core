<?xml version="1.0"?>

<queryset>
    <rdbms><type>postgresql</type><version>7.1</version></rdbms>

   <fullquery name="acs_mail_lite::check_bounces.send_notification_to_bouncing_email">
     <querytext>

       insert into acs_mail_lite_bounce_notif (party_id, notification_count, notification_time)
       select party_id, 0 as notification_count,
           date_trunc('day', current_timestamp - to_interval(1 + :notification_interval, 'days'))
           as notification_time
        from acs_mail_lite_bounce
        where bounce_count >= :max_bounce_count

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.get_recent_bouncing_users">
     <querytext>

       select u.user_id, u.email, u.first_names || ' ' || u.last_name as name
       from cc_users u, acs_mail_lite_bounce_notif n
       where u.user_id = n.party_id
       and u.email_bouncing_p = 't'
       and n.notification_time < current_timestamp - to_interval(:notification_interval, 'days')
       and n.notification_count < :max_notification_count

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.log_notication_sending">
     <querytext>

       update acs_mail_lite_bounce_notif
       set notification_time = date_trunc('day',current_timestamp),
           notification_count = notification_count + 1
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::check_bounces.delete_log_if_no_recent_bounce">
     <querytext>

       delete from acs_mail_lite_bounce
       where party_id in (select party_id
                         from acs_mail_lite_mail_log
                         where last_mail_date < current_timestamp - to_interval(:max_days_to_bounce, 'days'))

     </querytext>
   </fullquery>



</queryset>
