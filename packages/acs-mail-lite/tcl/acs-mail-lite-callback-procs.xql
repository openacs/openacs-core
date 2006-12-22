<?xml version="1.0"?>
<queryset>
   <fullquery name="callback::acs_mail_lite::incoming_email::impl::acs-mail-lite.record_bounce">
     <querytext>

       update acs_mail_lite_bounce
       set bounce_count = bounce_count + 1
       where party_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="callback::acs_mail_lite::incoming_email::impl::acs-mail-lite.insert_bounce">
     <querytext>

       insert into acs_mail_lite_bounce (party_id, bounce_count)
       values (:user_id, 1)

     </querytext>
   </fullquery>

</queryset>
