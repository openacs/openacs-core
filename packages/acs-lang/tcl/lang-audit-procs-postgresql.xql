<?xml version="1.0"?>
<queryset>
  <rdbms><type>postgresql</type><version>7.2</version></rdbms>

  <fullquery name="lang::audit::changed_message.lang_message_audit">
    <querytext>
          insert into lang_messages_audit (package_key, message_key, locale, message, overwrite_user) 
            values (:package_key, :message_key, :locale, :old_message, :overwrite_user) 
    </querytext>
  </fullquery>

</queryset>
