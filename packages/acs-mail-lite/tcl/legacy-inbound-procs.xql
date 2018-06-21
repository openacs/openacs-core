<?xml version="1.0"?>
<queryset>

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
