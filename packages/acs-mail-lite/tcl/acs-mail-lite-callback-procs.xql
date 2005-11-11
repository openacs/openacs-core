<?xml version="1.0"?>
<queryset>
   <fullquery name="callback::acs_mail_lite::incoming_email::impl::acs-mail-lite.record_bounce">
     <querytext>

       update acs_mail_lite_bounce
       set bounce_count = bounce_count + 1
       where user_id = :user_id

     </querytext>
   </fullquery>

   <fullquery name="callback::acs_mail_lite::incoming_email::impl::acs-mail-lite.insert_bounce">
     <querytext>

       insert into acs_mail_lite_bounce (user_id, bounce_count)
       values (:user_id, 1)

     </querytext>
   </fullquery>

    <fullquery name="callback::subsite::parameter_changed::impl::acs-mail-lite.update_entry">
        <querytext>
        update acs_mail_lite_reply_prefixes set prefix = :value where
        package_id = :package_id and impl_name = :package_key
        </querytext>
    </fullquery>

    <fullquery name="callback::subsite::parameter_changed::impl::acs-mail-lite.insert_entry">
        <querytext>
        insert into acs_mail_lite_reply_prefixes (package_id,impl_name,prefix)
        values (:package_id,:package_key,:value)
        </querytext>
    </fullquery>

    <fullquery name="callback::subsite::parameter_changed::impl::acs-mail-lite.remove_entry">
        <querytext>
	delete from acs_mail_lite_reply_prefixes where package_id = :package_id
        </querytext>
    </fullquery>

    <fullquery name="callback::subsite::parameter_changed::impl::acs-mail-lite.entry_exists">
        <querytext>
	select * from acs_mail_lite_reply_prefixes where package_id = :package_id
        </querytext>
    </fullquery>

</queryset>