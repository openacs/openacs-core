<?xml version="1.0"?>
<queryset>

  <fullquery name="lang::message::register.lang_message_null_update">
    <querytext>
      update lang_messages 
      set    registered_p = 't',
             message = null
      where  locale = :locale 
      and    key = :key
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages (key, locale, message, registered_p)
      values (:key, :locale, null, 't')
    </querytext>
  </fullquery>

  <fullquery name="lang::message::cache.select_locale_keys">
    <querytext>
      select locale, key, message 
      from   lang_messages
      where  registered_p = 't'
    </querytext>
  </fullquery>

</queryset>
