<?xml version="1.0"?>
<queryset>
  <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

  <fullquery name="lang::message::register.lang_message_update">
    <querytext>
      update lang_messages
      set    message = empty_clob()
      where  locale = :locale 
      and    message_key = :message_key
      and    package_key = :package_key
      returning message into :1
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages (package_key, message_key, locale, message) 
      values (:package_key, :message_key, :locale, empty_clob()) 
      returning message into :1
    </querytext>
  </fullquery>

  <fullquery name="lang::message::register.select_an_existing_message">
    <querytext>
        select message
          from lang_messages
         where message_key = :message_key
           and package_key = :package_key
           and rownum = 1
    </querytext>
  </fullquery>

</queryset>



