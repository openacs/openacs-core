<?xml version="1.0"?>
<queryset>

   <fullquery name="lang::user::locale.get_user_locale">      
      <querytext>
        select locale 
        from   ad_locale_user_prefs 
        where  user_id = :user_id
      </querytext>
   </fullquery>


   <fullquery name="lang::user::set_locale.user_locale_exists_p">
      <querytext>
        select count(*) 
        from   ad_locale_user_prefs 
        where  user_id = :user_id
      </querytext>
   </fullquery>


   <fullquery name="lang::user::set_locale.update_user_locale">
      <querytext>
        update ad_locale_user_prefs set locale = :locale where user_id = :user_id
      </querytext>
   </fullquery>


   <fullquery name="lang::user::set_locale.insert_user_locale">
      <querytext>
         insert into ad_locale_user_prefs (user_id, locale) values (:user_id, :locale)
      </querytext>
   </fullquery>


   <fullquery name="lang::user::set_locale.delete_user_locale">
      <querytext>
        delete from ad_locale_user_prefs where user_id = :user_id
      </querytext>
   </fullquery>

</queryset>
