
<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages (package_key, message_key, locale, message, upgrade_status, creation_user) 
      values (:package_key, :message_key, :locale, :message, :message_upgrade_status, :creation_user) 
    </querytext>
  </fullquery>

 <fullquery name="lang::message::register.lang_message_update">
     <querytext>
       update lang_messages
       set    message = :message,
              upgrade_status = :message_upgrade_status
       where  locale = :locale
       and    message_key = :message_key
       and    package_key = :package_key
     </querytext>
 </fullquery>

  <fullquery name="lang::message::update_description.update_description">
    <querytext>
      update lang_message_keys
      set    description = :description
      where  message_key = :message_key
      and    package_key = :package_key
    </querytext>
  </fullquery>

</queryset>
