<?xml version="1.0"?>
<queryset>

  <fullquery name="lang::message::register.message_key_exists_p">
    <querytext>
       select count(*) 
       from lang_message_keys
       where package_key = :package_key
         and message_key = :message_key  
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.message_exists_p">
    <querytext>
       select count(*) 
       from lang_messages
       where package_key = :package_key
         and message_key = :message_key  
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.insert_message_key">
    <querytext> 
        insert into lang_message_keys
            (message_key, package_key, upgrade_status)
          values
            (:message_key, :package_key, :key_upgrade_status)
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_null_update">
    <querytext>
      update lang_messages 
      set    message = null,
             upgrade_status = :message_upgrade_status
      where  locale = :locale 
      and    package_key = :package_key
      and    message_key = :message_key
    </querytext>
  </fullquery>

  <fullquery name="lang::message::cache.select_locale_keys">
    <querytext>
      select locale, package_key, message_key, message 
      from   lang_messages
      $package_where_clause
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert_null_msg">
    <querytext>
      insert into lang_messages (package_key, message_key, locale, message, upgrade_status) 
      values (:package_key, :message_key, :locale, null, :message_upgrade_status) 
    </querytext>
  </fullquery>

  <fullquery name="lang::message::update_description.update_description_insert_null">
    <querytext>
      update lang_message_keys
      set    description = null
      where  message_key = :message_key
      and    package_key = :package_key
    </querytext>
  </fullquery>

</queryset>
