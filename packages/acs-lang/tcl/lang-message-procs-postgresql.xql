<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::message::register.lang_message_insert">      
    <querytext>
      insert into lang_messages (package_key, message_key, locale, message) 
      values (:package_key, :message_key, :locale, :message) 
    </querytext>
  </fullquery>

 <fullquery name="lang::message::register.lang_message_update">
     <querytext>
       update lang_messages
       set    message = :message
       where  locale = :locale
       and    message_key = :message_key
       and    package_key = :package_key
     </querytext>
 </fullquery>

</queryset>
