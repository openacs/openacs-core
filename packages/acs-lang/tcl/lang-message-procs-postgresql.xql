<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::message::register.lang_message_update">
    <querytext>
      update lang_messages
      set    registered_p = 't',
             message = :message
      where  locale = :locale 
      and    key = :key
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages (key, locale, message, registered_p) 
      values (:key, :locale, :message, 't') 
    </querytext>
  </fullquery>

</queryset>
