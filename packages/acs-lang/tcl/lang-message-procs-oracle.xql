<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::message::register.lang_message_update">
    <querytext>
      update lang_messages
      set    message = empty_clob(),
             upgrade_status = :message_upgrade_status
      where  locale = :locale 
      and    message_key = :message_key
      and    package_key = :package_key
      returning message into :1
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages (package_key, message_key, locale, message, upgrade_status, creation_user) 
      values (:package_key, :message_key, :locale, empty_clob(), :message_upgrade_status, :creation_user) 
      returning message into :1
    </querytext>
  </fullquery>

  <fullquery name="lang::message::update_description.update_description">
    <querytext>
      update lang_message_keys
      set    description = empty_clob()
      where  message_key = :message_key
      and    package_key = :package_key
      returning description into :1
    </querytext>
  </fullquery>

</queryset>
