<?xml version="1.0"?>
<queryset>

    <fullquery name="acs_mail_lite::bouncing_email_p.bouncing_p">
      <querytext>

    	select case when email_bouncing_p = 't' then 1 else 0 end 
	as send_p 
      	from users, parties 
     	where lower(email) = lower(:email)
          and party_id = user_id

      </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::bouncing_user_p.bouncing_p">
      <querytext>

    	select case when email_bouncing_p = 't' then 1 else 0 end 
	as send_p 
      	from users 
     	where user_id = :user_id

      </querytext>
    </fullquery>


   <fullquery name="acs_mail_lite::check_bounces.delete_log_if_no_recent_bounce">
     <querytext>

       delete from acs_mail_lite_bounce
       where party_id in (select party_id
                         from acs_mail_lite_mail_log
                         where last_mail_date < sysdate - :max_days_to_bounce)

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

   <fullquery name="acs_mail_lite::record_bounce.record_bounce">
     <querytext>

       update acs_mail_lite_bounce
       set bounce_count = bounce_count + 1
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::record_bounce.insert_bounce">
     <querytext>

       insert into acs_mail_lite_bounce (party_id, bounce_count)
       values (:user_id, 1)

     </querytext>
   </fullquery>

</queryset>
