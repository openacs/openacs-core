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

   <fullquery name="acs_mail_lite::log_mail_sending.record_mail_sent">
     <querytext>

       update acs_mail_lite_mail_log
       set last_mail_date = sysdate
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::log_mail_sending.insert_log_entry">
     <querytext>

       insert into acs_mail_lite_mail_log (party_id, last_mail_date)
       values (:user_id, sysdate)

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::load_mail_dir.record_bounce">
     <querytext>

       update acs_mail_lite_bounce
       set bounce_count = bounce_count + 1
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="acs_mail_lite::load_mail_dir.insert_bounce">
     <querytext>

       insert into acs_mail_lite_bounce (party_id, bounce_count)
       values (:user_id, 1)

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

   <fullquery name="acs_mail_lite::get_address_array.get_user_name_and_id">
     <querytext>

       select person_id as user_id, first_names || ' ' || last_name as user_name
       from parties, persons
       where email = :email
         and party_id = person_id
	order by party_id desc
	limit 1

     </querytext>
   </fullquery>


    <fullquery name="acs_mail_lite::sweeper.delete_queue_entry">
        <querytext>
            delete
            from acs_mail_lite_queue
            where message_id = :message_id
        </querytext>
    </fullquery>

    <fullquery name="acs_mail_lite::load_mails.select_impl">
        <querytext>
	        select * from acs_mail_lite_reply_prefixes where prefix = :package_prefix
        </querytext>
    </fullquery>

<fullquery name="acs_mail_lite::party_name.get_org_name">
    <querytext>
	select
		name
	from 
		organizations
	where
		organization_id = :party_id
    </querytext>
</fullquery>

<fullquery name="acs_mail_lite::party_name.get_group_name">
    <querytext>
	select
		group_name
	from 
		groups
	where
		group_id = :party_id
    </querytext>
</fullquery>

<fullquery name="acs_mail_lite::party_name.get_party_name">
    <querytext>
	select
		party_name
	from 
		party_names
	where
		party_id = :party_id
    </querytext>
</fullquery>

</queryset>
